#' The standard cross-validator (CV)
#'
#' This object runs a decoding analysis where a classifier is repeatedly trained
#' and tested using cross-validation.
#'
#' @details A cross-validator object takes a datasource (DS), a classifier (CL),
#'   feature preprocessors (FP) and result metric (RM) objects, and runs
#'   multiple cross-validation cycles where:
#'
#'   1. A datasource (DS) generates training and test data splits of the data
#'   2. Feature preprocessors (FPs) do preprocessing of the data
#'   3. A classifier (CL) is trained and predictions are generated on a test set
#'   4. Result metrics (RMs) assess the accuracy of the predictions and compile
#'   the results.
#'
#' @param ndr_container The purpose of this argument is to make the
#'   constructor of the cv_standard cross-validator work with the magrittr
#'   pipe (%>%) operator. This argument would almost always be set at the
#'   end of a sequence of piping operators that include a datasource and a 
#'   classifier. Alternatively, one can keep this set to NULL and directly use
#'   the datasource and classifier arguments (one would almost never use
#'   both types of arguments). See the examples. 
#'
#' @param datasource A datasource (DS) object that will generate the training
#'   and test data. 
#'
#' @param classifier A classifier (CS) object that will learn parameters based
#'   on the training data and will generate predictions based on the test data.
#'
#' @param feature_preprocessors A list of feature preprocessor (FP) objects that
#'   learn preprocessing parameters from the training data and apply
#'   preprocessing of both the training and test data based on these parameters.
#'
#' @param result_metrics A list of result metric (RM) objects that are used to
#'   evaluate the classification performance. If this is set to NULL then the
#'   rm_main_results(), rm_confusion_matrix() results metrics will be used.
#'
#' @param num_resample_runs The number of times the cross-validation should be
#'   run (i.e., "resample runs"), where on each run, new training and test sets
#'   are generated. If pseudo-populations are used (e.g., with the ds_basic),
#'   then new pseudo-populations will be generated on each resample run as well.
#'
#' @param test_only_at_training_time A boolean indicated whether the classifier
#'   should only be trained and tested at the same time point (i.e., if TRUE a
#'   temporal cross-decoding analysis will NOT be run). Setting this to true can
#'   potentially speed up the analysis and save memory at the cost of not
#'   calculated the temporal cross decoding results.
#'
#' @param num_parallel_cores An integers specifying the number of parallel cores
#'   to use when executing the resample runs in the analysis. The default (NULL)
#'   value is to use half of the cores detected on the system. If this value is
#'   set to a value of less than 1, then the code will be run serially and
#'   messages will be printed showing how long each CV split took to run which
#'   is useful for debugging.
#'
#' @examples
#' data_file <- system.file("extdata/ZD_150bins_50sampled.Rda",
#'   package = "NeuroDecodeR")
#'
#' ds <- ds_basic(data_file, "stimulus_ID", 18)
#' fps <- list(fp_zscore())
#' cl <- cl_max_correlation()
#'
#' cv <- cv_standard(datasource = ds, 
#'                  classifier = cl, 
#'                  feature_preprocessors = fps)
#' 
#' 
#' # alternatively, one can also use the magrittr pipe (%>%) to do an analysis
#' library(magrittr)
#' data_file2 <- system.file("extdata/ZD_500bins_500sampled.Rda",
#'   package = "NeuroDecodeR")
#'   
#' DECODING_RESULTS <- data_file2 %>%
#'     ds_basic('stimulus_ID', 6, num_label_repeats_per_cv_split = 3) %>%
#'     cl_max_correlation() %>%
#'     fp_zscore() %>%
#'     rm_main_results() %>%
#'     rm_confusion_matrix() %>%
#'     cv_standard(num_resample_runs = 3) %>%
#'     run_decoding()
#' 
#' 
#' @family cross-validator
#'
#'
#'
# the constructor
#' @export
#' 
cv_standard <- function(ndr_container = NULL,
                        datasource = NULL,
                        classifier = NULL,
                        feature_preprocessors = NULL,
                        result_metrics = NULL,
                        num_resample_runs = 50,
                        test_only_at_training_time = FALSE,
                        num_parallel_cores = NULL) {

  
  # Going to add any of the datasource, classifier, feature_preprocessor, and
  # result_metric objects that were passed as arguments to this constructor to
  # either an existing (if the ndr_container argument is not null) or new ndr
  # container. Then will pull these objects out of the ndr container and create
  # a new cv_standard object based on them. This will allow objects to be
  # defined either by previously setting them in an ndr container or by setting
  # them directly through cv_standard arguments.
  
  
  if (is.null(ndr_container)) {
    ndr_container <- ndr_container()
  }
  
  if (class(ndr_container) != "ndr_container") {
    stop("The argument ndr_container must be set to an ndr_container object.")
  }
  
  
  add_cv_objects_to_container <- function(ndr_container, cv_object, class_type) {
    
    if (!is.null(cv_object)) {
      
      # if a list of objects was passed (e.g., a list of FPs)
      if (class(cv_object) == "list") {
        
        for (curr_obj in cv_object) {
          
          # check to make sure arguments of the write type were passed to the constructor
          if (get_ndr_object_type(curr_obj) != class_type) {
            stop(paste0("Some of the arguments that were passed as type ", toupper(class_type), 
                        "are instead of type ", toupper(get_ndr_object_type(cv_object))))
          }
            
          ndr_container <-  add_ndr_object(ndr_container, curr_obj)
        }
        
        
      } else {
        
        # if a single object was passed (e.g., a DS)
        
        if (get_ndr_object_type(cv_object) != class_type) {
          stop(paste0("Some of the arguments that were passed as type ", toupper(class_type), 
                      "are instead of type ", toupper(get_ndr_object_type(cv_object))))
        }
        ndr_container <- add_ndr_object(ndr_container, cv_object)
      }
    
      
    }
    
    ndr_container
    
  } 

  
  
  ndr_container <- add_cv_objects_to_container(ndr_container, datasource, "ds")
  ndr_container <- add_cv_objects_to_container(ndr_container, classifier, "cl")
  ndr_container <- add_cv_objects_to_container(ndr_container, feature_preprocessors, "fp")
  ndr_container <- add_cv_objects_to_container(ndr_container, result_metrics, "rm")
  
 
  the_cv <- new_cv_standard(ndr_container$ds,
                            ndr_container$cl,
                            ndr_container$fp,
                            ndr_container$rm,
                            num_resample_runs,
                            test_only_at_training_time,
                            num_parallel_cores)
  
  the_cv
  
}






new_cv_standard <- function(datasource,
                        classifier,
                        feature_preprocessors,
                        result_metrics,
                        num_resample_runs,
                        test_only_at_training_time,
                        num_parallel_cores) {

  if (is.null(datasource)) {
    stop('A datasource must be set in the cv_standard constructor.')
  }
  
  if (is.null(classifier)) {
    stop('A classifier must be set in the cv_standard constructor.')
  }
  
  
  if (is.null(result_metrics)) {
    result_metrics <- list(
      rm_main_results(),
      rm_confusion_matrix())
  }

  
  # if the num_parallel_cores is not set, use half the available cores
  if (is.null(num_parallel_cores)) {
    num_parallel_cores <- parallel::detectCores()/2
  }
  
  
  analysis_ID <- generate_analysis_ID()

  the_cv <- list(
    analysis_ID = analysis_ID,
    datasource = datasource,
    classifier = classifier,
    feature_preprocessors = feature_preprocessors,
    num_resample_runs = num_resample_runs,
    result_metrics = result_metrics,
    test_only_at_training_time = test_only_at_training_time,
    num_parallel_cores = num_parallel_cores)

  attr(the_cv, "class") <- "cv_standard"
  the_cv

}




#' @export
run_decoding.cv_standard <- function(cv_obj) {
  
  analysis_start_time <- Sys.time()

  # copy over the main objects
  datasource <- cv_obj$datasource
  classifier <- cv_obj$classifier
  feature_preprocessors <- cv_obj$feature_preprocessors
  num_resample_runs <- cv_obj$num_resample_runs
  result_metrics <- cv_obj$result_metrics
  test_only_at_training_time <- cv_obj$test_only_at_training_time
  

  if (cv_obj$num_parallel_cores > 0) {

    # register parallel resources
    the_cluster <- parallel::makeCluster(cv_obj$num_parallel_cores, type = "SOCK")
    doSNOW::registerDoSNOW(the_cluster)

    "%do_type%" <- get("%dopar%")

  } else {

    "%do_type%" <- get("%do%")

  }


  # Do a parallel loop over resample runs
  all_resample_run_decoding_results <- foreach(iResample = 1:num_resample_runs) %do_type% { 

    
    # get the data from the current cross-validation run
    cv_data <- get_data(datasource)

    unique_times <- unique(cv_data$time_bin)
    num_time_bins <- length(unique_times)
    all_cv_train_test_inds <- select(cv_data, starts_with("CV"))
    num_cv <- ncol(all_cv_train_test_inds)


    # resample_run_decoding_results is the name of the decoding results inside
    # the dopar loop outside the loop, when all the results have really been
    # combined into a list, this is called all_resample_run_decoding_results
    resample_run_decoding_results <- NULL

    all_cv_results <- NULL

    for (iCV in 1:num_cv) {

      all_time_results <- NULL

      # when the code is not run in parallel, the CV number will be printed
      tictoc::tic()
      message(paste0("CV: ", iCV))


      for (iTrain in 1:num_time_bins) {

        training_set <- dplyr::filter(
          cv_data, .data$time_bin == unique_times[iTrain],
          all_cv_train_test_inds[iCV] == "train") %>%
          dplyr::select(starts_with("site"), .data$train_labels)

        test_set <- dplyr::filter(cv_data, all_cv_train_test_inds[iCV] == "test") %>%
          dplyr::select(starts_with("site"), .data$test_labels, .data$time_bin)

        if (test_only_at_training_time) {
          test_set <- dplyr::filter(test_set, .data$time_bin == unique_times[iTrain])
        }


        # if feature-processors have been specified, do feature processing...
        if (length(feature_preprocessors) >= 1) {
          for (iFP in seq_along(feature_preprocessors)) {
            processed_data <- preprocess_data(feature_preprocessors[[iFP]], training_set, test_set)
            training_set <- processed_data$training_set
            test_set <- processed_data$test_set
          }
        }


        # get predictions from the classifier (along with the correct labels)
        curr_cv_prediction_results <- get_predictions(classifier, training_set, test_set)

        # add the current CV run number, train time to the results data frame
        curr_cv_prediction_results <- curr_cv_prediction_results %>%
          dplyr::mutate(CV = iCV, train_time = unique_times[iTrain]) %>%
          select(.data$CV, .data$train_time, everything())

        # all_cv_results <- rbind(all_cv_results, curr_cv_prediction_results)
        all_time_results[[iTrain]] <- curr_cv_prediction_results # should be faster b/c don't need to reallocate memory

      } # end the for loop over time bins


      tictoc::toc()


      # Aggregate results over all CV split runs
      all_cv_results[[iCV]] <- dplyr::bind_rows(all_time_results)
      
    } # end the for loop over CV splits



    # convert the results from each CV split from a list into a data frame
    all_cv_results <- dplyr::bind_rows(all_cv_results)


    # go through each Result Metric and aggregate the results from all CV splits using each metric
    for (iMetric in seq_along(result_metrics)) {
      curr_metric_results <- aggregate_CV_split_results(result_metrics[[iMetric]], all_cv_results)
      resample_run_decoding_results[[iMetric]] <- curr_metric_results ###  DECODING_RESULTS
    }


    return(resample_run_decoding_results)

  } # end loop over resample runs




  # aggregate results over all resample runs  ---------------------------------


  # close parallel resources
  if (cv_obj$num_parallel_cores > 0) {
    parallel::stopCluster(the_cluster)
  }


  # go through each Result Metric and aggregate the final results from all resample runs using each metric
  DECODING_RESULTS <- NULL
  result_metric_names <- NULL
  grouped_results <- purrr::transpose(all_resample_run_decoding_results)

  for (iMetric in seq_along(result_metrics)) {

    # bind the list of all the resample result RM objects together and preserve the RM's options attribute
    curr_options <- attributes(grouped_results[[iMetric]][[1]])$options
    curr_resample_run_results <- dplyr::bind_rows(grouped_results[[iMetric]], .id = "resample_run")
    attr(curr_resample_run_results, "options") <- curr_options

    DECODING_RESULTS[[iMetric]] <- aggregate_resample_run_results(curr_resample_run_results)
    result_metric_names[iMetric] <- class(DECODING_RESULTS[[iMetric]])[1]

  }

  # add names to the final results list so easy to extract elements
  names(DECODING_RESULTS) <- result_metric_names



  # save the decoding parameters to make results reproducible -----------------

  # set to null to save memory, can recreate the datasource by reloading the
  #  data in the binned_file_name field
  cv_obj$datasource$binned_data <- NULL

  cv_obj$parameter_df <- get_parameters(cv_obj)

  analysis_end_time <- Sys.time()

  # could save these in the cv_obj directly rather than in the cv_obj$parameters_df
  cv_obj$parameter_df$analysis_start_time <- analysis_start_time
  cv_obj$parameter_df$analysis_end_time <- analysis_end_time

  # saves all the CV parameters (DS, CL FPs etc)
  DECODING_RESULTS$cross_validation_paramaters <- cv_obj


  return(DECODING_RESULTS)

} # end the run_decoding method





# get parameters from all objects and save the in a data frame so that
# which will be useful to tell if an analysis has already been run
get_parameters.cv_standard <- function(ndr_obj) {


  # start by getting the parameters from the datasource
  parameter_df <- get_parameters(ndr_obj$datasource)

  # add the parameters from the classifier
  parameter_df <- cbind(parameter_df, get_parameters(ndr_obj$classifier))


  # if feature-processors have been specified, add their parameters to the data frame
  if (length(ndr_obj$feature_preprocessors) >= 1) {

    for (iFP in seq_along(ndr_obj$feature_preprocessors)) {
      curr_FP_parameters <- get_parameters(ndr_obj$feature_preprocessors[[iFP]])
      parameter_df <- cbind(parameter_df, curr_FP_parameters)
    }

  }



  # go through each result metric and get their parameters
  for (iMetric in seq_along(ndr_obj$result_metrics)) {
    curr_metric_parameters <- get_parameters(ndr_obj$result_metrics[[iMetric]])
    parameter_df <- cbind(parameter_df, curr_metric_parameters)
  }

  
  # finally add the parameters from this cv_standard object as well
  cv_parameters <- data.frame(
    analysis_ID = ndr_obj$analysis_ID,
    cv_standard.num_resample_runs = ndr_obj$num_resample_runs,
    cv_standard.test_only_at_training_time = ndr_obj$test_only_at_training_time,
    cv_standard.num_parallel_cores = ndr_obj$num_parallel_cores
  )


  parameter_df <- cbind(cv_parameters, parameter_df)

  parameter_df

}
