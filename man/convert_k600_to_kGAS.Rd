% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convert_k600_to_kGAS.R
\name{convert_k600_to_kGAS}
\alias{convert_k600_to_kGAS}
\title{Returns the gas exchange velocity for gas of interest w/ no unit conversions}
\usage{
convert_k600_to_kGAS(k600, temperature, gas = "O2")
}
\arguments{
\item{k600}{k600 as vector of numbers or single number}

\item{temperature}{Water temperature (deg C) as vector array of numbers or single number}

\item{gas}{gas for conversion, as string (e.g., 'CO2' or 'O2')}
}
\value{
Numeric value of gas exchange velocity for gas
}
\description{
Returns the gas exchange velocity for gas of interest w/ no unit conversions
}
