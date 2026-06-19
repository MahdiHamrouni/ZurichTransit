#' @title Load region cities from the city_swss_extract.R output
#'
#' @description
#' Parse the JSON produced by [extract_city_json()] (see `city_swss_extract.R`)
#' into a data frame of cities for one region. This is the city side of the
#' alignment: it supplies coordinates, population and the origin flag.
#'
#' @param city_json A JSON string as returned by [extract_city_json()], or a
#'   path to a `.json` file containing the same structure.
#'
#' @return A [tibble][tibble::tibble] of cities.
#'
#' @export
load_region_cities <- function(city_json) {                 # accept a JSON string or a path to a .json file
  tibble::as_tibble(jsonlite::fromJSON(city_json))          # parse the JSON and return it as a tibble
}


#' @title Align destination cities with their waiting times
#'
#' @description
#' Join the region's destination cities (from [extract_city_json()]) with the
#' per-destination waiting-time summary (from the API, see
#' [fetch_waiting_times()], or the bundled JSON). The origin station is excluded
#' from the destinations and returned separately so the plot can highlight it.
#'
#' @param cities A cities table from [load_region_cities()].
#' @param summary A waiting-time summary with at least `to_city`, `median_wait`
#'   and `n_queries` columns.
#'
#' @return A list with two tibbles: `origin` (single row) and `destinations`
#'   (cities joined to their waiting times).
#'
#' @export
align_waiting_times <- function(cities, summary) {
  origin <- dplyr::filter(cities, .data$is_origin)
  if (nrow(origin) == 0L) {
    stop("No origin station (is_origin = TRUE) found in cities.", call. = FALSE) 
  }

  # build the destinations table from the cities
  destinations <- cities |>
    dplyr::filter(!.data$is_origin) |>
    dplyr::inner_join(
      dplyr::select(summary, "to_city", "median_wait", "n_queries"),
      by = c("city" = "to_city")
    )

  if (nrow(destinations) == 0L) {
    stop("No destination cities matched the waiting-time summary.", call. = FALSE)
  }

  list(origin = origin, destinations = destinations)
}
