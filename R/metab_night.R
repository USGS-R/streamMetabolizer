#' @include metab_model-class.R
NULL

#' Nighttime regression for K estimation
#' 
#' Fits a model to estimate K from nighttime input data on DO, temperature, 
#' light, etc. The default day start & end are 12 noon on the preceding to
#' present day; the algorithm then filters the data to just those time points
#' for which light is very low.
#' 
#' @author Alison Appling, Maite Arroita
#' @param data data.frame with columns having the same names, units, and format 
#'   as the default. See \code{\link{mm_data}} for a full data description.
#' @param info Any metadata you would like to package within the metabolism 
#'   model.
#' @inheritParams mm_is_valid_day
#' @return A metab_night object containing the fitted model.
#' @examples
#' \dontrun{
#'  metab_night(data=data.frame(empty="shouldbreak"))
#' }
#' @export
#' @family metab_model
metab_night <- function(
  data=mm_data(local.time, DO.obs, DO.sat, depth, temp.water, light), # args for nightreg_1ply
  info=NULL, # args for new("metab_night")
  tests=c('full_day', 'even_timesteps', 'complete_data'), day_start=-12, day_end=12 # args for mm_is_valid_day, mm_model_by_ply
) {
  
  # Check data for correct column names & units
  data <- mm_validate_data(data, "metab_night")
  
  # model the data, splitting into overlapping ~31.5-hr 'plys' for each date
  night.all <- mm_model_by_ply(
    data, nightreg_1ply, # for mm_model_by_ply
    day_start=day_start, day_end=day_end, # for mm_model_by_ply and mm_is_valid_day
    tests=tests) # for mm_is_valid_day
  
  # Package and return results
  new("metab_night", 
      info=info,
      fit=night.all,
      args=list(calc_DO_fun=NA, day_start=day_start, day_end=day_end),
      data=data,
      pkg_version=as.character(packageVersion("streamMetabolizer")))
}


#### helpers ####

#' Make daily reaeration estimates from input parameters
#' 
#' Called from metab_night().
#' 
#' @param data_ply data.frame of the form \code{mm_data(local.time, DO.obs, 
#'   DO.sat, depth, temp.water, light)} and containing data for just one 
#'   estimation-day (this may be >24 hours but only yields estimates for one 
#'   24-hour period)
#' @inheritParams runjags_bayes
#' @param ... additional args passed from mm_model_by_ply and ignored here
#' @return data.frame of estimates and \code{\link[stats]{nlm}} model 
#'   diagnostics
#' @keywords internal
#' @references Hornberger, George M., and Mahlon G. Kelly. Atmospheric
#'   Reaeration in a River Using Productivity Analysis. Journal of the 
#'   Environmental Engineering Division 101, no. 5 (October 1975): 729-39.
#'   
#'   Raymond, Peter A., Christopher J. Zappa, David Butman, Thomas L. Bott, Jody
#'   Potter, Patrick Mulholland, Andrew E. Laursen, William H. McDowell, and
#'   Denis Newbold. Scaling the gas transfer velocity and hydraulic geometry in
#'   streams and small rivers. Limnology & Oceanography: Fluids & Environments 2
#'   (2012); 41:53.
nightreg_1ply <- function(data_ply, 
                          tests=c('full_day', 'even_timesteps', 'complete_data'), day_start=-12, day_end=12, ...) {
  
  # Try to run the model. Collect warnings/errors as a list of strings and
  # proceed to the next data_ply if there are stop-worthy issues.
  stop_strs <- warn_strs <- character(0)
  night.1d <- withCallingHandlers(
    tryCatch({
      # subset to times of darkness. require that these are all consecutive -
      # it'd be meaningless to look at the diff from 1 night to the next 2 nights
      which_night <- which(v(data_ply$light) < v(u(0.1, "umol m^-2 s^-1")))
      if(length(which_night) == 0) stop("no nighttime rows in data_ply")
      if(any(diff(which_night) > 1)) 
        stop_strs <<- c(stop_strs, "need exactly one night per data_ply")
      night_dat <- data_ply[which_night,]
      # do the full_day test here, rather than in mm_is_valid_day, because
      # it's not about specific times but about whether night begins and ends
      # within the ply bounds
      if(!is.na(full_day_test <- match('full_day',tests))) {
        which_twilight <- c(head(which_night,1) - 1, tail(which_night,1) + 1)
        if(which_twilight[1] < 1)
          stop_strs <<- c(stop_strs, "data don't start before day-night transition")
        if(which_twilight[2] > nrow(data_ply))
          stop_strs <<- c(stop_strs, "data don't end after night-day transition")
        tests <- tests[-full_day_test]
      }
      
      # check for data validity here, after subsetting to the time window we
      # really care about
      timestep.days <- suppressWarnings(mean(as.numeric(diff(v(night_dat$local.time)), units="days"), na.rm=TRUE))
      stop_strs <<- c(stop_strs, mm_is_valid_day(
        night_dat, # data split by mm_model_by_ply and subsetted here
        tests=tests, day_start=day_start, day_end=day_start, # args passed from metab_night
        timestep_days=timestep.days, need_complete=c("DO.obs","DO.sat","depth","temp.water","light"))) # args supplied here
      
      # actually stop if anything has broken so far
      if(length(stop_strs) > 1) stop("invalid data ply")
      
      # smooth DO data
      night_dat$DO.obs.smooth <- u(c(stats::filter(night_dat$DO.obs, rep(1/3, 3), sides=2)), get_units(night_dat$DO.obs))
      
      # calculate dDO/dt
      dDO <- u(diff(v(night_dat$DO.obs.smooth)), get_units(night_dat$DO.obs.smooth))
      dt <- u(as.numeric(diff(v(night_dat$local.time)), units='days'), 'd')
      night_dat$dDO.dt <- (dDO / dt)[c(NA, 1:length(dDO))]
      
      # calculate saturation deficit
      night_dat$DO.sat.def <- night_dat$DO.sat - night_dat$DO.obs.smooth
      
      # fit model & extract the important stuff (see Chapra & DiToro 1991)
      lm_dDOdt <- lm(dDO.dt ~ DO.sat.def, data=v(night_dat))
      out <- list()
      out$KO2 <- u(coef(lm_dDOdt)[["DO.sat.def"]], get_units(night_dat$dDO.dt[1] / night_dat$DO.sat.def[1]))
      out$KO2.sd <- u(summary(lm_dDOdt)$coefficients[["DO.sat.def","Std. Error"]], get_units(out$KO2))
      out$ER.vol <- u(coef(lm_dDOdt)[["(Intercept)"]], get_units(night_dat$dDO.dt))
      out$ER.sd.vol <- u(summary(lm_dDOdt)$coefficients[["(Intercept)","Std. Error"]], get_units(night_dat$dDO.dt))
      out$ER <- out$ER.vol * mean(night_dat$depth)
      out$ER.sd <- out$ER.sd.vol * mean(night_dat$depth)
      out$rsq <- summary(lm_dDOdt)$r.squared
      out$p <- summary(lm_dDOdt)$coefficients[["DO.sat.def","Pr(>|t|)"]]
      
      # convert from KO2 to K600. the coefficients used here differ for 
      # Maite's code and that in LakeMetabolizer. Maite and Bob use K600 = 
      # ((600/(1800.6-(120.1*temp)+(3.7818*temp^2)-(0.047608*temp^3)))^-0.5)*KO2.
      # LakeMetabolizer & streamMetabolizer use K600 <- ((600/(1568 - 
      # 86.04*temp + 2.142*temp^2 - 0.0216*temp^3))^-0.5)*KO2. The resulting 
      # numbers are believable by either method but do differ. I'll stick with
      # LakeMetabolizer since those are the coefficients from Raymond et al. 
      # 2012, which is probably the newer source. the sd conversion works
      # because the conversion is linear in KO2.
      out$K600 <- convert_kGAS_to_k600(kGAS=out$KO2, temperature=mean(v(night_dat$temp.water)), gas="O2")
      out$K600.sd <- convert_kGAS_to_k600(kGAS=out$KO2.sd, temperature=mean(v(night_dat$temp.water)), gas="O2")
      
      # return everything. remove units since we can't fully support them
      # elsewhere yet
      lapply(out, v)
      
    }, error=function(err) {
      # on error: give up, remembering error
      stop_strs <<- c(stop_strs, err$message)
      NA
    }), warning=function(war) {
      # on warning: record the warning and run again
      warn_strs <<- c(warn_strs, war$message)
      invokeRestart("muffleWarning")
    })
  
  # stop_strs may have accumulated during nlm() call. If failed, use dummy data 
  # to fill in the model output with NAs.
  if(length(stop_strs) > 0) {
    night.1d <- setNames(as.list(rep(NA, 8)), c('KO2','KO2.sd','ER','ER.sd','rsq','p','K600','K600.sd'))
  }
  
  # Return, reporting any results, warnings, and errors
  data.frame(GPP=NA, GPP.sd=NA, 
             ER=night.1d$ER, ER.sd=night.1d$ER.sd, 
             K600=night.1d$K600, K600.sd=night.1d$K600.sd,
             r.squared=night.1d$rsq, p.value=night.1d$p,
             warnings=paste0(warn_strs, collapse="; "), 
             errors=paste0(stop_strs, collapse="; "),
             stringsAsFactors=FALSE)
}



#### metab_night class ####

#' Reaeration model fitted by nighttime regression
#' 
#' \code{metab_bayes} models use nighttime regression to fit values of K for a
#' given DO time series.
#' 
#' @exportClass metab_night
#' @family metab.model.classes
setClass(
  "metab_night", 
  contains="metab_model"
)


#' Explain why we can't make dissolved oxygen predictions from a metab_night.
#' 
#' metab_night only fits ER and K, and only for the darkness hours. While it 
#' would be possible to make predictions just for those hours, it'd be costly to
#' implement and has not-yet-obvious benefits.
#' 
#' @inheritParams predict_DO
#' @return A data.frame of predictions, as for the generic 
#'   \code{\link{predict_DO}}.
#' @export
#' @family predict_DO
predict_DO.metab_night <- function(metab_model) {
  
  # pull args from the model
  calc_DO_fun <- calc_DO_mod # this isn't used in the model fitting but makes sense for prediction
  day_start <- get_args(metab_model)$day_start
  day_end <- get_args(metab_model)$day_end
  
  # get the metabolism (GPP, ER) data and estimates
  metab_ests <- predict_metab(metab_model)
  data <- get_data(metab_model)
   
  # re-process the input data with the metabolism estimates to predict DO, using
  # our special nighttime regression prediction function
  mm_model_by_ply(
    data=data, model_fun=metab_night_predict_1ply, day_start=day_start, day_end=day_end, # for mm_model_by_ply
    calc_DO_fun=calc_DO_mod, metab_ests=metab_ests) # for mm_predict_1ply
  
}

#' Helper to predict_DO.metab_model
#' 
#' Usually assigned to model_fun within mm_model_by_ply, called from there
#' 
#' @param data_ply a data.frame of predictor data for a single ply (~day)
#' @param calc_DO_fun the function to use to build DO estimates from GPP, ER, 
#'   etc. default is calc_DO_mod, but could also be calc_DO_mod_by_diff
#' @param metab_ests a data.frame of metabolism estimates for all days, from 
#'   which this function will choose the relevant estimates
#' @param ... additional args passed from mm_model_by_ply and ignored here
#' @return a data.frame of predictions
metab_night_predict_1ply <- function(data_ply, calc_DO_fun, metab_ests, ...) {

  # subset to times of darkness, just as we did in nightreg_1ply
  which_night <- which(v(data_ply$light) < v(u(0.1, "umol m^-2 s^-1")))
  night_dat <- data_ply[which_night,]

  # for metab_night, sometimes data_plys (especially night_dat) are entirely empty. if that's today,
  # return right quick now.
  if(nrow(night_dat)==0) {
    # return a variant on night_dat with more columns and just 1 row, all NAs
    night_dat[1,'DO.mod'] <- as.numeric(NA)
    return(night_dat)
  }
  
  # determine which date these data END on, because that's the date where we're
  # storing these K+ER estimates
  date <- as.character(as.Date(data_ply$local.time[nrow(data_ply)]))
  
  # get the daily metabolism estimates, and skip today (return DO.mod=NAs) if
  # they're missing
  metab_est <- metab_ests[metab_ests$date==date,]
  if(!complete.cases(metab_est[c('K600','ER')])) {
    return(data.frame(night_dat, DO.mod=NA))
  }
  
  # if we have metab estimates, use them to predict DO
  . <- local.time <- ".dplyr.var"
  night_dat %>%
    do(with(., {
      
      # prepare auxiliary data
      n <- length(local.time)
      timestep.days <- suppressWarnings(mean(as.numeric(diff(local.time), units="days"), na.rm=TRUE))
      
      # produce DO.mod estimates for today's GPP and ER
      DO.mod <- calc_DO_fun(
        GPP.daily=0, # nighttime regression assumes GPP is 0 during the [night] times modeled
        ER.daily=metab_est$ER, 
        K600.daily=metab_est$K600, 
        DO.obs=DO.obs, DO.sat=DO.sat, depth=depth, temp.water=temp.water, 
        frac.GPP=0, frac.ER=timestep.days, frac.D=timestep.days, DO.mod.1=DO.obs[1], n=n)
      
      data.frame(., DO.mod=DO.mod)
    }))
}