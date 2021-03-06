context("metab_sim")

test_that("metab_sim predictions (predict_metab, predict_DO) make sense", {

  # generate data
  dat <- data_metab('3')
  data_date <- mm_model_by_ply(mm_model_by_ply_prototype, dat, day_start=4, day_end=28)$date
  dd <- data.frame(date=data_date, DO.mod.1=7.5, GPP.daily=4, ER.daily=-c(NA,2,4), K600.daily=30, discharge.daily=42)
  sp <- specs('sim', discharge_daily=NULL, K600_daily=NULL, GPP_daily=NULL, ER_daily=NULL)

  # should be able to fit by specifying either data$DO.obs[d,1] or data_daily$DO.mod.1
  mm <- metab_sim(sp, data=select(dat, -DO.obs), data_daily=dd)
  mm2 <- metab_sim(sp, data=dat, data_daily=select(dd, -DO.mod.1))

  # get_params
  expect_equal(select(get_params(mm), -DO.mod.1), get_params(mm2))

  # predict_metab
  expect_equal(select(get_params(mm)[2:3,], GPP=GPP.daily, ER=ER.daily), select(predict_metab(mm)[2:3,], GPP, ER))
  expect_equal(select(get_params(mm2)[2:3,], GPP=GPP.daily, ER=ER.daily), select(predict_metab(mm2)[2:3,], GPP, ER))

  # should be able to omit day_tests and then get preds for all 3 days
  mm3 <- metab_sim(revise(sp, day_tests=c()), data=select(dat, -DO.obs), data_daily=dd)
  expect_equal(select(get_params(mm3), GPP=GPP.daily, ER=ER.daily), select(predict_metab(mm3), GPP, ER))

  # predict_DO - DO.mod.1 should follow specifications
  expect_equal(predict_DO(mm) %>% group_by(date) %>% summarize(first.DO.mod = DO.mod[1]) %>% .$first.DO.mod,
               dd %>% .$DO.mod.1 %>% {.*c(NA,1,1)} )
  expect_equal(predict_DO(mm2) %>% group_by(date) %>% summarize(first.DO.mod = DO.mod[1]) %>% .$first.DO.mod,
               dat %>% filter(format(solar.time, '%H:%M') == '04:00') %>% .$DO.obs %>% {.*c(NA,1,1)} )

  # predict_DO - DO.mod (no error) and DO.obs (with any error) should still be pretty close
  expect_true(rmse_DO(predict_DO(mm)) < get_specs(mm)$err_obs_sigma*1.5, "DO.mod tracks DO.obs with not too much error")
  expect_true(rmse_DO(predict_DO(mm2)) < get_specs(mm2)$err_obs_sigma*1.5, "DO.mod tracks DO.obs with not too much error")
  # plot_DO_preds(predict_DO(mm))

  # predict_DO - DO.obs & DO.mod should be different each time unless seed is set. DO.pure should always be the same
  expect_true(!isTRUE(all.equal(predict_DO(mm)$DO.obs, predict_DO(mm)$DO.obs)))
  expect_true(!isTRUE(all.equal(predict_DO(mm)$DO.mod, predict_DO(mm)$DO.mod)))
  expect_true(isTRUE(all.equal(predict_DO(mm)$DO.pure, predict_DO(mm)$DO.pure)))
  mm <- metab_sim(data=dat, data_daily=select(dd, -DO.mod.1),
                  specs=specs('s_np_oipcpi_eu_plrckm.rnorm',
                              discharge_daily=NULL, K600_daily=NULL, GPP_daily=NULL, ER_daily=NULL,
                              sim_seed=626, day_start=-1, day_end=23))
  expect_true(isTRUE(all.equal(predict_DO(mm)$DO.obs, predict_DO(mm)$DO.obs)))
  expect_true(isTRUE(all.equal(predict_DO(mm)$DO.mod, predict_DO(mm)$DO.mod)))

  # predict_DO - using default (just err_obs_sigma), should have basically no autocorrelation in errors
  mm <- metab_sim(sp, data=select(dat, -DO.obs), data_daily=dd)
  DO_preds <- predict_DO(mm, date_start="2012-09-19")
  acf_out <- acf(DO_preds$DO.mod - DO_preds$DO.obs, plot=FALSE)
  expect_lt(acf_out$acf[acf_out$lag==1], 0.1)
  # plot_DO_preds(predict_DO(mm))

  # predict_DO - autocorrelation should be bigger when there's process error
  mm <- metab_sim(data=select(dat, -DO.obs), data_daily=dd,
                  specs=specs('s_np_oipcpi_eu_plrckm.rnorm',
                              discharge_daily=NULL, K600_daily=NULL, GPP_daily=NULL, ER_daily=NULL,
                              err_obs_sigma=0, err_proc_sigma=1.5))
  DO_preds <- predict_DO(mm, date_start="2012-09-19")
  acf_out <- acf(DO_preds$DO.pure - DO_preds$DO.mod, plot=FALSE)
  expect_gt(acf_out$acf[acf_out$lag==1], 0.6)
  # plot_DO_preds(predict_DO(mm))

  # should be able to switch ODE methods in fitting
  dat <- select(data_metab('3', res='30'), -DO.obs)
  sp <- specs('sim', err_obs_sigma=0, err_proc_sigma=0.05, sim_seed=4, discharge_daily=NULL, K600_daily=NULL, GPP_daily=NULL, ER_daily=NULL)
  mmE <- metab_sim(revise(sp, model_name='s_np_oipcpi_eu_plrckm.rnorm'), data=dat, data_daily=dd)
  mmP <- metab_sim(revise(sp, model_name='s_np_oipcpi_tr_plrckm.rnorm'), data=dat, data_daily=dd)
  rmseEP <- sqrt(mean((predict_DO(mmE)$DO.obs - predict_DO(mmP)$DO.obs)^2, na.rm=TRUE))
  expect_gt(rmseEP, 0.001)
  expect_lt(rmseEP, 0.1)
  # DO_preds <- bind_rows(
  #   data.frame(predict_DO(mmE), method="euler", stringsAsFactors=FALSE),
  #   data.frame(predict_DO(mmP), method="trapezoid", stringsAsFactors=FALSE))
  # library(ggplot2)
  # ggplot(DO_preds, aes(x=solar.time, y=100*DO.mod/DO.sat, color=method)) + geom_line() + theme_bw()
  # ggplot(DO_preds, aes(x=solar.time, y=100*DO.obs/DO.sat, color=method)) + geom_line() + theme_bw()

  # should be possible to adjust DO_mod_1 until the timeseries looks pretty
  # nice. turns out to be crazy easy, requiring just one iteration for perfect
  # (?!?) matches between the last DO.mod of one day and the first DO.mod of the
  # next
  dat <- data_metab('10', res='30')
  sp <- specs(
    mm_name('sim'),
    K600_daily=function(n, K600_daily_predlog=log(16), ...) pmax(1, rnorm(n, exp(K600_daily_predlog), 2)),
    GPP_daily=function(n, ...) pmax(0, rnorm(n, 2, 1)),
    ER_daily=function(n, ...) pmin(0, rnorm(n, -4, 1)),
    err_proc_sigma=2,
    sim_seed=9185)
  msim <- metab(sp, dat)
  #plot_DO_preds(msim)
  msim@data_daily <- mm_model_by_ply(function(data_ply, ...) data.frame(DO.mod.n = tail(data_ply$DO.mod, 1)), data=predict_DO(msim), day_start=msim@specs$day_start, day_end=msim@specs$day_end) %>%
    mutate(DO.mod.1=DO.mod.n[c(n(),seq_len(n()-1))]) %>% select(date, DO.mod.1)
  #plot_DO_preds(msim)
  diffs <- mm_model_by_ply(function(data_ply, ...) data.frame(DO.mod.1 = head(data_ply$DO.mod, 1), DO.mod.n = tail(data_ply$DO.mod, 1)), data=predict_DO(msim), day_start=msim@specs$day_start, day_end=msim@specs$day_end) %>%
    mutate(DO.mod.1=DO.mod.n[c(n(),seq_len(n()-1))])
  expect_equal(diffs$DO.mod.1[c(2:nrow(diffs),1)], diffs$DO.mod.n, tol=0.000000001)
})
