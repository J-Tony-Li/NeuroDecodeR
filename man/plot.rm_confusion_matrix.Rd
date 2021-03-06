% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rm_confusion_matrix.R
\name{plot.rm_confusion_matrix}
\alias{plot.rm_confusion_matrix}
\title{A plot function for the rm_confusion_matrix object}
\usage{
\method{plot}{rm_confusion_matrix}(
  x,
  ...,
  result_type = "zero_one_loss",
  plot_only_same_train_test_time = TRUE
)
}
\arguments{
\item{x}{A rm_confusion_matrix object that has aggregated runs from a
decoding analysis, e.g., if DECODING_RESULTS are the output from the
run_decoding(cv) then this argument should be
\code{DECODING_RESULTS$rm_confusion_matrix}.}

\item{...}{This is needed to conform to the plot generic interface.}

\item{result_type}{A string specifying the type of result to plot that can
take the following values:
\itemize{
\item "zero_one_loss": plot a regular confusion matrix.
\item "decision_vals": plot a confusion matrix with the average decision values.
\item "mutual_information": plot the mutual information calculated from the
zero-one loss confusion matrix.
}}

\item{plot_only_same_train_test_time}{A boolean indicating whether the
confusion matrices should only be plotted at the same training and test
times. If the \code{result_type == "mutual_information"} setting this to TRUE
will plot a TCD plot of the mutual information otherwise it will plot a
line plot of the mutual information for training and testing at the same
time.}
}
\description{
This function plots confusion matrices after the decoding analysis has been
run (and all results have been aggregated). This function can also plot
mutual information calculated from the confusion matrix.
}
\seealso{
Other result_metrics: 
\code{\link{plot.rm_main_results}()},
\code{\link{rm_confusion_matrix}()},
\code{\link{rm_main_results}()}
}
\concept{result_metrics}
