#' @title Fetch waiting times from the public-transport API (To be comepleted)
#'
#' @description
#' Empty stub for the API stage of the pipeline. It will later query the public
#' transport API for connections from the origin station to each destination,
#' summarise the time until the next departure, and return a waiting-time table
#' with the same shape as the `summary` block of the bundled JSON
#' (columns: `to_city`, `median_wait`, `mean_wait`, `min_wait`, `max_wait`,
#' `n_queries`, ...).
#'
#' Until the API integration is written, this returns `NULL` and callers fall
#' back to the bundled JSON summary
#'
#' @param cities A cities table (see [load_region_cities()]) providing the
#'   origin and the destination stations to query
#' @param date,time Optional query date/time for the API requests
#' @param ... Reserved for future API parameters
#'
#' @return A waiting-time summary tibble, or `NULL` while unimplemented
#'
#' @export
fetch_waiting_times <- function(cities, date = NULL, time = NULL, ...) {  # signature kept stable for the future API
  # TODO: implement the API requests and summarise them into a waiting-time
  # table. Intentionally left empty for now
  NULL                                                                    # return NULL so callers use the JSON fallback
}
