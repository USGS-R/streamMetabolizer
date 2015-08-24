#' Remove entries in data
#' 
#' @param data data.frame of instantaneous observations, to be filtered to only
#'   those points on days that pass the specified tests in mm_is_valid_day
#' @param data_daily data.frame of daily estimates/statistics, to be filtered in
#'   accordance with the filtering of data
#' @inheritParams metab_model_prototype
#' @inheritParams mm_is_valid_day
#' @return list of data and data_daily with same structure as inputs but with 
#'   invalid days removed, plus a third data.frame of dates that were removed
#' @export
mm_filter_valid_days <- function(
  data, data_daily=NULL, # inheritParams metab_model_prototype (but actually, redefine them for specificity to this function)
  day_start=6, day_end=30, # inheritParams metab_model_prototype
  tests=c('full_day', 'even_timesteps', 'complete_data') # inheritParams mm_is_valid_day
) {
  
  #' Filter the instantaneous data using mm_is_valid_day
  #' 
  #' Record dates that are removed and the reasons for removal in a parent
  #' variable named removed
  #' 
  #' @inheritParams mm_model_by_ply_prototype
  #' @inheritParams mm_is_valid_day
  #' @return data
  #' @keywords internal
  mm_filter_valid_days_filter_fun <- function(
    data_ply, data_daily_ply, day_start, day_end, local_date, # inheritParams mm_model_by_ply_prototype
    tests # inheritParams mm_is_valid_day
  ) {
    stop_strs <- mm_is_valid_day(day=data_ply, day_start=day_start, day_end=day_end, tests=tests)
    if(isTRUE(stop_strs)) {
      data_ply
    } else {
      removed <<- c(removed, list(data.frame(local.date=local_date, errors=paste0(stop_strs, collapse="; "))))
      NULL
    }
  }

  # run the filtering function over all days, recording days that were removed
  removed <- list()
  data_filtered <- mm_model_by_ply(
    model_fun=mm_filter_valid_days_filter_fun, data=data, data_daily=data_daily, 
    day_start=day_start, day_end=day_end, 
    tests=tests)
  removed <- do.call(rbind, removed) # removed was populated by <<- calls within filter_fun
  
  # filter the daily data to match & retur
  if(!is.null(data_daily)) {
    daily_removed <- data.frame(
      local.date=as.Date(setdiff(as.character(data_daily$local.date), c(unique(format(data$local.time, "%Y-%m-%d")), as.character(removed$local.date)))), 
      errors="local.date in data_daily but not data")
    removed <- rbind(removed, daily_removed)
    removed <- removed[order(removed$local.date),]
    rownames(removed) <- NULL
    data_daily_filtered <- data_daily[data_daily$local.date %in% unique(data_filtered$local.date),]
  } else {
    data_daily_filtered <- NULL
  }
  
  # return
  list(data=data_filtered, data_daily=data_daily_filtered, removed=removed)
}