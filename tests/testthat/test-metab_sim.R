context("metab_sim")

vfrench <- streamMetabolizer:::load_french_creek(attach.units=FALSE)
vfrenchshort <- vfrench[vfrench$local.time >= as.POSIXct("2012-08-23 22:50:00", tz="Etc/GMT+7") & 
                          vfrench$local.time <= as.POSIXct("2012-08-25 23:50:00", tz="Etc/GMT+7"), ]

test_that("metab_sim predictions (predict_metab, predict_DO) make sense", {
  
  dd <- data.frame(local.date=unique(as.character(vfrenchshort$local.time, format="%Y-%m-%d")), 
                   DO.mod.1=7.5, GPP=4, ER=-c(NA,2,4), K600=30)
  
  # should be able to fit by specifying either data$DO.obs[d,1] or data_daily$DO.mod.1 
  mm <- metab_sim(data=vfrenchshort[-which(names(vfrenchshort)=="DO.obs")], data_daily=dd, day_start=-1, day_end=23)
  mm2 <- metab_sim(data=vfrenchshort, data_daily=dd[-which(names(dd)=="DO.mod.1")], day_start=-1, day_end=23)

  # get_fit
  expect_equal(dd, get_fit(mm))
  
  # predict_metab
  expect_equal(c(3,5), dim(predict_metab(mm)))
  
  # predict_DO - DO.mod (no error) and DO.obs (with any error) should still be pretty close
  DO_preds <- predict_DO(mm)
  expect_true(mean(abs(DO_preds$DO.obs - DO_preds$DO.mod), na.rm=TRUE) < 0.15, "DO.mod tracks DO.obs with not too much error")
  # plot_DO_preds(DO_preds)
  
  # predict_DO - DO.obs should be different each time unless seed is set. DO.mod should always be the same
  expect_true(!isTRUE(all.equal(predict_DO(mm)$DO.obs, predict_DO(mm)$DO.obs)))
  expect_true(isTRUE(all.equal(predict_DO(mm)$DO.mod, predict_DO(mm)$DO.mod)))
  mm <- metab_sim(data=vfrenchshort, data_daily=dd[-which(names(dd)=="DO.mod.1")], 
                  model_specs=specs_sim_basic(sim.seed=626), day_start=-1, day_end=23)
  expect_true(isTRUE(all.equal(predict_DO(mm)$DO.obs, predict_DO(mm)$DO.obs)))
  expect_true(isTRUE(all.equal(predict_DO(mm)$DO.mod, predict_DO(mm)$DO.mod)))
  
  # predict_DO - using default (just err.obs.sigma), should have basically no autocorrelation in errors
  mm <- metab_sim(data=vfrenchshort[-which(names(vfrenchshort)=="DO.obs")], 
                  data_daily=dd, day_start=-1, day_end=23)
  DO_preds <- predict_DO(mm)[-(1:3),]
  acf_out <- acf(DO_preds$DO.mod - DO_preds$DO.obs, plot=FALSE)
  expect_less_than(acf_out$acf[acf_out$lag==1], 0.1)
  
  # predict_DO - autocorrelation should be bigger when there's process error
  mm <- metab_sim(data=vfrenchshort[-which(names(vfrenchshort)=="DO.obs")], 
                  model_specs=specs_sim_basic(err.obs.sigma=0, err.proc.sigma=0.05), 
                  data_daily=dd, day_start=-1, day_end=23)
  DO_preds <- predict_DO(mm)[-(1:3),]
  acf_out <- acf(DO_preds$DO.mod - DO_preds$DO.obs, plot=FALSE)
  expect_more_than(acf_out$acf[acf_out$lag==1], 0.6)
  # plot_DO_preds(predict_DO(mm))
  
  # should be able to switch ODE methods in fitting
  mmE <- metab_sim(data=vfrenchshort[-which(names(vfrenchshort)=="DO.obs")], 
                  model_specs=specs_sim_basic(err.obs.sigma=0, err.proc.sigma=0.05, sim.seed=4, ODE_method="Euler"), 
                  data_daily=dd, day_start=-1, day_end=23)
  mmP <- metab_sim(data=vfrenchshort[-which(names(vfrenchshort)=="DO.obs")], 
                  model_specs=specs_sim_basic(err.obs.sigma=0, err.proc.sigma=0.05, sim.seed=4, ODE_method="pairmeans"), 
                  data_daily=dd, day_start=-1, day_end=23)
  DO_preds <- bind_rows(
    data.frame(predict_DO(mmE), method="Euler", stringsAsFactors=FALSE),
    data.frame(predict_DO(mmP), method="pairmeans", stringsAsFactors=FALSE))
  # ggplot(DO_preds, aes(x=local.time, y=100*DO.mod/DO.sat, color=method)) + geom_line() + theme_bw()
  # ggplot(DO_preds, aes(x=local.time, y=100*DO.obs/DO.sat, color=method)) + geom_line() + theme_bw()
  # ggplot(spread(select(filter(DO_preds, local.date=="2012-08-24"), local.time, method, DO.mod), method, DO.mod), aes(x=local.time, y=pairmeans, color=method)) + geom_line() + theme_bw()
  # ggplot(spread(select(filter(DO_preds, local.date=="2012-08-24"), local.time, method, DO.mod), method, DO.mod), aes(x=local.time, y=Euler-pairmeans, color=method)) + geom_line() + theme_bw()
  
  # should be able to switch ODE methods in prediction
  mm <- metab_sim(data=vfrenchshort[-which(names(vfrenchshort)=="DO.obs")], 
                  model_specs=specs_sim_basic(err.obs.sigma=0, err.proc.sigma=0.05, sim.seed=4), 
                  data_daily=dd, day_start=-1, day_end=23)
  DO_preds <- bind_rows(
    data.frame(predict_DO(mm, calc_DO_args=replace(get_args(mm)$model_specs$calc_DO_args, "ODE_method", "Euler")), method="Euler", stringsAsFactors=FALSE),
    data.frame(predict_DO(mm), method="pairmeans", stringsAsFactors=FALSE))
  # ggplot(DO_preds, aes(x=local.time, y=DO.mod, color=method)) + geom_line() + theme_bw()
  # ggplot(DO_preds, aes(x=local.time, y=100*DO.mod/DO.sat, color=method)) + geom_line() + theme_bw()
  # ggplot(DO_preds, aes(x=local.time, y=DO.obs, color=method)) + geom_line() + theme_bw()
  # ggplot(DO_preds, aes(x=local.time, y=100*DO.obs/DO.sat, color=method)) + geom_line() + theme_bw()
})