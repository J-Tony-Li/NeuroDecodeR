% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/log_and_save_decoding_results.R
\name{log_load_results_from_params}
\alias{log_load_results_from_params}
\title{A function that loads DECODING_RESULTS based on decoding_parameters}
\usage{
log_load_results_from_params(decoding_params, results_directory_name)
}
\arguments{
\item{decoding_params}{A data frame of decoding parameters that can
be created by calling the cross-validator's get_parameters() method.}

\item{results_directory_name}{A string containing the path to a directory
that contains all the decoding results.}
}
\description{
A function that loads DECODING_RESULTS based on decoding_parameters
}
