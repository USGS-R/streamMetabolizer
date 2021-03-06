% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot_distribs.R
\name{plot_distribs}
\alias{plot_distribs}
\title{Plot the prior/posterior distributions of a parameter}
\usage{
plot_distribs(
  dist_data,
  parname = c("GPP_daily", "alpha", "Pmax", "ER_daily", "K600_daily",
    "K600_daily_meanlog", "lnK600_lnQ_intercept", "lnK600_lnQ_slope", "K600_lnQ_nodes",
    "K600_daily_sdlog", "K600_daily_sigma", "err_obs_iid_sigma", "err_proc_acor_phi",
    "err_proc_acor_sigma", "err_proc_iid_sigma", "err_mult_GPP_sdlog"),
  index = TRUE,
  style = c("dygraphs", "ggplot2")
)
}
\arguments{
\item{dist_data}{Either a specs list (for priors only) or a metab_model
object (for both priors and posteriors).}

\item{parname}{character. the name of the parameter whose distribution[s] you
wish to plot}

\item{index}{integer or logical. Applicable only if plotting posteriors, and
useful only if the parname is for a parameter having multiple (e.g., daily)
instances. In this case, the index selects the instance and corresponds to
the row number in the data.frame element of \code{get_fit(metab_model)}
that contains the parameter, e.g. \code{get_fit(metab_model)$daily} for
\code{'GPP_daily'}. The default, TRUE, selects and pools all instances of
the parameter.}

\item{style}{character indicating which graphics package to use}
}
\description{
Plot the prior and/or posterior disitrubtions as implied by the
hyperparameters in a specs list and/or the
}
\examples{
\dontrun{
# priors only
plot_distribs(specs('bayes', K600_daily_mu=30), 'K600_daily')

# posteriors, too
mm <- metab(specs(mm_name('bayes')), data=data_metab('1', res='30'))
plot_distribs(mm, 'GPP_daily', 1)

# with modifications
plot_distribs(mm, 'err_proc_iid_sigma') \%>\%
  dygraphs::dyRangeSelector(dateWindow=c(-0.1,1.3)) \%>\%
  dygraphs::dyAxis(name='y', valueRange=c(0,15))
}
}
