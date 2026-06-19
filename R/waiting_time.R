#' @title Compute per-destination waiting times from API responses
#'
#' @description
#' For each API response in `results_data`, extracts departure times, computes
#' the minimum positive waiting time from now, and aggregates into a
#' per-destination summary table.
#'
#' @param results_data A list of parsed API responses from [get_all_connections()].
#' @param result_routes The query table from [get_all_connections()], used to
#'   label each response with the correct city names.
#'
#' @return A list of two tibbles: `waiting_table` (one row per query) and
#'   `summary_table` (one row per destination, with median, mean and count).
#'
#' @noRd

compute_waiting_times <- function(results_data, result_routes) {

  now <- Sys.time()

  waiting_table <- purrr::map(seq_along(results_data), function(i) {

    response <- results_data[[i]]

    #EXTRACTION DEPARTUR CONNECTION
    departures <- purrr::map_chr(response$connections, ~ .x$departure)
    departure_dts <- as.POSIXct(departures, format = "%Y-%m-%d %H:%M:%S")

    # TIME DIFFERENCES
    waiting_mins <- as.numeric(difftime(departure_dts, now, units = "mins"))

    # TAKE MIN DIFFERENCE AMONG POSITIVE (>0) RESULTS
    positive <- waiting_mins[waiting_mins >= 0]
    min_wait <- if (length(positive) > 0) min(positive) else NA_real_

    tibble::tibble(
      from_city    = result_routes$from_city[i],
      to_city      = result_routes$to_city[i],
      query_time = result_routes$query_time[i],
      waiting_time = min_wait
    )
  }) |> purrr::list_rbind()

  summary_table <- waiting_table |>
    dplyr::group_by(.data$to_city) |>
    dplyr::summarise(
      median_waiting_time = stats::median(.data$waiting_time, na.rm = TRUE),
      mean_waiting_time   = mean(.data$waiting_time, na.rm = TRUE),
      n_queries           = dplyr::n()
    ) |>
    dplyr::arrange(.data$median_waiting_time)

  return(list(waiting_table, summary_table))
}

#' @title Print a formatted waiting-time summary table
#'
#' @description
#' Renders a fixed-width console table showing the waiting time for every
#' destination at each query time, plus the per-destination median.
#'
#' @param waiting_table Raw waiting-time tibble from [compute_waiting_times()].
#' @param summary_table Per-destination summary from [compute_waiting_times()].
#'
#' @return Called for its side effect (printing). Returns `NULL` invisibly.
#'
#' @importFrom rlang .data
#'
#' @noRd
print_waiting_summary <- function(waiting_table, summary_table) {

  query_times <- sort(unique(waiting_table$query_time))

  cat(paste0(strrep("\u2550", 55), "\n"))
  cat("  WAITING TIME SUMMARY \u2014 Z\u00fcrich HB\n")
  cat(paste0(strrep("\u2550", 55), "\n"))
  cat(paste0("  Destination         ", paste(sprintf("%6s", query_times), collapse = "  "), "  MEDIAN\n"))
  cat(paste0(strrep("\u2500", 55), "\n"))

  for (city in summary_table$to_city) {
    times <- purrr::map_chr(query_times, function(qt) {
      val <- waiting_table |>
        dplyr::filter(.data$to_city == city, .data$query_time == qt) |>
        dplyr::pull(.data$waiting_time)
      if (length(val) == 0 || is.na(val)) "  NA " else sprintf("%4.0fm", val)
    })
    median_val <- summary_table |> dplyr::filter(.data$to_city == city) |> dplyr::pull(.data$median_waiting_time)
    cat(paste0(sprintf("  %-20s", city), paste(times, collapse = "  "), sprintf("  %4.0fm\n", median_val)))
  }

  cat(paste0(strrep("\u2550", 55), "\n"))
}



#' @title Run the full waiting-time pipeline
#'
#' @description
#' Calls [get_all_connections()], passes the results to
#' [compute_waiting_times()], prints the summary with
#' [print_waiting_summary()], and returns both tables.
#'
#' @return A list of two tibbles: `waiting_table` and `summary_table`
#'   (see [compute_waiting_times()]).
#'
#' @noRd
get_waiting_time <- function(){
  results_all  <- get_all_connections()
  results_data <- results_all[[1]]
  result_routes <- results_all[[2]]

  output <- compute_waiting_times(results_data, result_routes)
  waiting_table <- output[[1]]
  summary_table <- output[[2]]

  print_waiting_summary(waiting_table, summary_table)
  return(list(waiting_table, summary_table))
}

# Call get_waiting_time() explicitly when needed (e.g. from the pipeline's
# fetch_waiting_times() adapter). Do NOT auto-run on source(), otherwise simply
# loading this file would fire API calls.
