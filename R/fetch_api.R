#' @title Fetch waiting times for the pipeline (adapter over waiting_time.R)
#'
#' @description
#' Adapter between the API logic in `waiting_time.R`/`get_routes.R` and the map
#' pipeline. It calls [get_waiting_time()], keeps only the per-destination
#' `summary_table`, and renames its columns to the names the rest of the
#' pipeline expects (`median_wait`, `mean_wait`); `to_city` and `n_queries`
#' already match.
#'
#' If the API is not available yet (e.g. [get_all_connections()] is still the
#' stub) the call errors; this is caught here and `NULL` is returned, which
#' makes [generate_waiting_map()] fall back to the bundled JSON summary.
#'
#' @param cities A cities table (see [load_region_cities()]). Currently unused
#'   because `waiting_time.R` builds its own queries; kept for a stable
#'   signature and future use.
#' @param date,time Optional query date/time for the API requests.
#' @param ... Reserved for future API parameters.
#'
#' @return A waiting-time summary tibble with columns `to_city`, `median_wait`,
#'   `mean_wait`, `n_queries`; or `NULL` when no API data is available.
#'
#' @export
fetch_waiting_times <- function(cities, date = NULL, time = NULL, ...) {  # stable signature for the pipeline
  tryCatch({                                                              # any API failure -> NULL -> JSON fallback
    res <- get_waiting_time()                                            # list(waiting_table, summary_table)
    res[[2]] |>                                                          # keep only the per-destination summary
      dplyr::rename(                                                     # match the names the pipeline expects:
        median_wait = .data$median_waiting_time,                         #   median_waiting_time -> median_wait
        mean_wait   = .data$mean_waiting_time                            #   mean_waiting_time   -> mean_wait
      )                                                                  # to_city + n_queries already match
  }, error = function(e) {                                              # if the API/stub errors...
    message("API not available (", conditionMessage(e), ")")            # ...explain why...
    NULL                                                                 # ...and let the caller use the JSON fallback
  })
}
