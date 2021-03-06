#' Functions implemented by any \code{streamMetabolizer}-compatible metabolism
#' model.
#'
#' Metabolism models in the \code{streamMetabolizer} package all implement a
#' common set of core functions. These functions are conceptually packaged as
#' the \code{metab_model_interface} defined here.
#'
#' @section Functions in the interface:
#'
#'   \itemize{
#'
#'   \item \code{\link{show}(metab_model) \{ display(metab_model) \}}
#'
#'   \item \code{\link{get_params}(metab_model, ...) \{ return(data.frame) \}}
#'
#'   \item \code{\link{get_param_names}(metab_model, ...) \{ return(list) \}}
#'
#'   \item \code{\link{predict_metab}(metab_model, ...) \{ return(data.frame)
#'   \}}
#'
#'   \item \code{\link{predict_DO}(metab_model, ...) \{ return(data.frame) \}}
#'
#'   \item \code{\link{get_fit}(metab_model) \{ return(fitted.model) \}}
#'
#'   \item \code{\link{get_fitting_time}(metab_model) \{ return(proc_time) \}}
#'
#'   \item \code{\link{get_info}(metab_model) \{ return(info) \}}
#'
#'   \item \code{\link{get_specs}(metab_model) \{ return(specs.list) \}}
#'
#'   \item \code{\link{get_data}(metab_model) \{ return(data.frame) \}}
#'
#'   \item \code{\link{get_data_daily}(metab_model) \{ return(data.frame) \}}
#'
#'   \item \code{\link{get_version}(metab_model) \{ return(version.string) \}}
#'
#'   }
#'
#' @name metab_model_interface
#' @rdname metab_model_interface
#' @docType data
#' @format A collection of functions which any metabolism model in
#'   \code{streamMetabolizer} should implement.
#' @examples
#' methods(class="metab_model")
NULL

#### show ####
# show() is already a generic S4 function.


#### S3 generics ####

#' Extract the user-supplied metadata about a metabolism model.
#'
#' A function in the metab_model_interface. Returns any user-supplied metadata.
#'
#' @param metab_model A metabolism model, implementing the
#'   metab_model_interface, for which to return the metadata information.
#' @return The user-supplied metadata in the original format.
#' @export
#' @family metab_model_interface
get_info <- function(metab_model) {
  UseMethod("get_info")
}

#' Extract the internal model from a metabolism model.
#'
#' A function in the metab_model_interface. Returns the internal model
#' representation as fitted to the supplied data and arguments.
#'
#' @param metab_model A metabolism model, implementing the
#'   metab_model_interface, for which to return the data
#' @return An internal model representation; may have any class
#' @export
#' @family metab_model_interface
get_fit <- function(metab_model) {
  UseMethod("get_fit")
}

#' Extract the amount of time that was required to fit the metabolism model.
#'
#' A function in the metab_model_interface. Returns the time that was taken to
#' fit the model; see \code{\link{proc.time}} for details.
#'
#' @param metab_model A metabolism model, implementing the
#'   metab_model_interface, for which to return the time
#' @return An proc_time object
#' @export
#' @family metab_model_interface
get_fitting_time <- function(metab_model) {
  UseMethod("get_fitting_time")
}

#' Extract the fitting specifications from a metabolism model.
#'
#' A function in the metab_model_interface. Returns the specifications that were
#' passed in when fitting the metabolism model.
#'
#' @param metab_model A metabolism model, implementing the
#'   metab_model_interface, for which to return the specifications
#' @return The list of specifications that was passed to \code{\link{metab}()}
#' @export
#' @family metab_model_interface
get_specs <- function(metab_model) {
  UseMethod("get_specs")
}


#' Extract the fitting data from a metabolism model.
#'
#' A function in the metab_model_interface. Returns the data that were passed to
#' a metabolism model.
#'
#' @param metab_model A metabolism model, implementing the
#'   metab_model_interface, for which to return the data
#' @return A data.frame
#' @export
#' @family metab_model_interface
get_data <- function(metab_model) {
  UseMethod("get_data")
}

#' Extract the daily fitting data, if any, from a metabolism model.
#'
#' A function in the metab_model_interface. Returns the daily data that were
#' passed to a metabolism model.
#'
#' @param metab_model A metabolism model, implementing the
#'   metab_model_interface, for which to return the data_daily
#' @return A data.frame
#' @export
#' @family metab_model_interface
get_data_daily <- function(metab_model) {
  UseMethod("get_data_daily")
}

#' Extract the version of streamMetabolizer that was used to fit the model.
#'
#' A function in the metab_model_interface. Returns the version of
#' streamMetabolizer that was used to fit the model.
#'
#' @param metab_model A metabolism model, implementing the
#'   metab_model_interface, for which to return the data
#' @return character representation of the package version
#' @export
#' @family metab_model_interface
get_version <- function(metab_model) {
  UseMethod("get_version")
}

#' Extract the metabolism parameters (fitted and/or fixed) from a model.
#'
#' A function in the metab_model_interface. Returns estimates of those
#' parameters describing the rates and/or shapes of GPP, ER, or reaeration.
#'
#' @param metab_model A metabolism model, implementing the
#'   metab_model_interface, to use in predicting metabolism
#' @param date_start Date or a class convertible with as.Date. The first date
#'   (inclusive) for which to report parameters. If NA, no filtering is done.
#' @param date_end Date or a class convertible with as.Date. The last date
#'   (inclusive) for which to report parameters.. If NA, no filtering is done.
#' @param uncertainty character. Should columns for the uncertainty of parameter
#'   estimates be excluded ('none'), reported as standard deviations ('sd'), or
#'   reported as lower and upper bounds of a 95 percent confidence interval
#'   ('ci')? When available (e.g., for Bayesian models), if 'ci' then the
#'   central value will be the median (50th quantile) and the ranges will be the
#'   2.5th and 97.5th quantiles. If 'sd' then the central value will always be
#'   the mean.
#' @param messages logical. Should warning and error messages from the fitting
#'   procedure be included in the output?
#' @param fixed character. Should values pulled from data_daily (i.e., fixed
#'   rather that fitted) be treated identically ('none'), paired with a logicals
#'   column ending in '.fixed' ('columns'), converted to character and marked
#'   with a leading asterisk ('stars')?
#' @param ... Other arguments passed to class-specific implementations of
#'   \code{get_params}
#' @param attach.units (deprecated, effectively FALSE in future) logical. Should
#'   units be attached to the output?
#' @return A data.frame of the parameters needed to predict GPP, ER, D, and DO,
#'   one row per date
#' @importFrom lifecycle deprecated is_present
#' @examples
#' dat <- data_metab('3', day_start=12, day_end=36)
#' mm <- metab_night(specs(mm_name('night')), data=dat)
#' get_params(mm)
#' get_params(mm, date_start=get_fit(mm)$date[2])
#' @export
#' @family metab_model_interface
#' @seealso \code{\link{predict_metab}} for daily average rates of GPP and ER
get_params <- function(
  metab_model, date_start=NA, date_end=NA,
  uncertainty=c('sd','ci','none'), messages=TRUE, fixed=c('none','columns','stars'),
  ..., attach.units=deprecated()) {

  UseMethod("get_params")
}

#' Extract the daily parameter names from a metabolism model.
#'
#' A function in the metab_model_interface. Returns vectors of the required and
#' optional daily metabolism parameters for the model.
#'
#' @param metab_model A metabolism model object or model name for which to
#'   return the list of required and optional metabolism parameters.
#' @param ... Placeholder for future arguments
#' @return Returns a list of two vectors, the names of the required and optional
#'   daily metabolism parameters, respectively.
#' @export
#' @family metab_model_interface
get_param_names <- function(metab_model, ...) {
  UseMethod("get_param_names")
}

#' Predict metabolism from a fitted model.
#'
#' A function in the metab_model_interface. Returns predictions (estimates) of
#' GPP, ER, and K600.
#'
#' @param metab_model A metabolism model, implementing the
#'   metab_model_interface, to use in predicting metabolism
#' @param date_start Date or a class convertible with as.Date. The first date
#'   (inclusive) for which to report metabolism predictions. If NA, no filtering
#'   is done.
#' @param date_end Date or a class convertible with as.Date. The last date
#'   (inclusive) for which to report metabolism predictions. If NA, no filtering
#'   is done.
#' @param day_start start time (inclusive) of a day's data in number of hours
#'   from the midnight that begins the date. For example, day_start=-1.5
#'   indicates that data describing 2006-06-26 begin at 2006-06-25 22:30, or at
#'   the first observation time that occurs after that time if day_start doesn't
#'   fall exactly on an observation time. For daily metabolism predictions,
#'   day_end - day_start should probably equal 24 so that each day's estimate is
#'   representative of a 24-hour period.
#' @param day_end end time (exclusive) of a day's data in number of hours from
#'   the midnight that begins the date. For example, day_end=30 indicates that
#'   data describing 2006-06-26 end at the last observation time that occurs
#'   before 2006-06-27 06:00. For daily metabolism predictions, day_end -
#'   day_start should probably equal 24 so that each day's estimate is
#'   representative of a 24-hour period.
#' @param ... Other arguments passed to class-specific implementations of
#'   \code{predict_metab}
#' @param attach.units (deprecated, effectively FALSE in future) logical. Should
#'   units be attached to the output?
#' @param use_saved logical. Is it OK to use predictions that were saved with
#'   the model?
#' @return A data.frame of daily metabolism estimates. Columns include:
#'   \describe{
#'
#'   \item{GPP}{numeric estimate of Gross Primary Production, positive when
#'   realistic, \eqn{g O_2 m^{-2} d^{-1}}{g O2 / m^2 / d}}
#'
#'   \item{ER}{numeric estimate of Ecosystem Respiration, negative when
#'   realistic, \eqn{g O_2 m^{-2} d^{-1}}{g O2 / m^2 / d}}
#'
#'   \item{K600}{numeric estimate of the reaeration rate \eqn{d^{-1}}{1 / d}} }
#' @importFrom lifecycle deprecated is_present
#' @examples
#' dat <- data_metab('3', day_start=12, day_end=36)
#' mm <- metab_night(specs(mm_name('night')), data=dat)
#' predict_metab(mm)
#' predict_metab(mm, date_start=get_fit(mm)$date[2])
#' @export
#' @family metab_model_interface
predict_metab <- function(
  metab_model, date_start=NA, date_end=NA,
  day_start=get_specs(metab_model)$day_start, day_end=min(day_start+24, get_specs(metab_model)$day_end),
  ..., attach.units=deprecated(), use_saved=TRUE) {

  UseMethod("predict_metab")
}


#' Predict DO from a fitted model.
#'
#' A function in the metab_model_interface. Returns predictions of dissolved
#' oxygen.
#'
#' @param metab_model A metabolism model, implementing the
#'   metab_model_interface, to use in predicting metabolism
#' @param date_start Date or a class convertible with as.Date. The first date
#'   (inclusive) for which to report DO predictions. If NA, no filtering is
#'   done.
#' @param date_end Date or a class convertible with as.Date. The last date
#'   (inclusive) for which to report DO predictions. If NA, no filtering is
#'   done.
#' @param ... Other arguments passed to class-specific implementations of
#'   \code{predict_DO}
#' @param attach.units (deprecated, effectively FALSE in future) logical. Should
#'   units be attached to the output?
#' @param use_saved logical. Is it OK to use predictions that were saved with
#'   the model?
#' @return A data.frame of dissolved oxygen predictions at the temporal
#'   resolution of the input data
#' @importFrom lifecycle deprecated is_present
#' @examples
#' dat <- data_metab('3', day_start=12, day_end=36)
#' mm <- metab_night(specs(mm_name('night')), data=dat)
#' preds <- predict_DO(mm, date_start=get_fit(mm)$date[3])
#' head(preds)
#' @export
#' @family metab_model_interface
predict_DO <- function(metab_model, date_start=NA, date_end=NA,
                       ..., attach.units=deprecated(), use_saved=TRUE) {

  UseMethod("predict_DO")
}
