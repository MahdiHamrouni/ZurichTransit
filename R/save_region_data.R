#' @title Collect API data and save to JSON
#'
#' @description
#' Combines city data (from [extract_city_df()]) and waiting-time results
#' (from the search.ch API via [get_all_connections()] and
#' [compute_waiting_times()]) into a single JSON file matching the structure
#' expected by [generate_waiting_map()].
#'
#' The JSON contains two sections:
#' \itemize{
#'   \item \code{cities} — one row per city with coordinates and population;
#'   \item \code{summary} — one row per destination with aggregated waiting
#'         times (median, mean, min, max).
#' }
#'
#' @param csv_path Path to \code{SwissCities.csv}.
#' @param group_id Group identifier for the query batch (e.g. \code{"3"}).
#' @param region Region name matching the \code{region} column in the CSV.
#' @param output_path Path where the JSON file will be saved.
#'
#' @return Invisibly returns a list with \code{cities} and \code{summary}
#'   tibbles. Called primarily for its side effect of writing the JSON file.
#'
#' @export
save_region_data <- function(csv_path, group_id, region, output_path) {

  # ── Cities ────────────────────────────────────────────────────────────────
  cities_df <- extract_city_df(csv_path, region)

  cities_out <- cities_df |>
    dplyr::mutate(
      group_id = as.integer(group_id),
      region   = region
    ) |>
    dplyr::select(
      "group_id", "region", "is_origin", "city",
      "station_name", "station_id", "canton",
      "latitude", "longitude", "population"
    )

  # ── Waiting times from API ────────────────────────────────────────────────
  results_all   <- get_all_connections()
  results_data  <- results_all[[1]]
  result_routes <- results_all[[2]]

  waiting_table <- compute_waiting_times(results_data, result_routes)[[1]]

  origin_city <- cities_df$city[cities_df$is_origin][1]

  summary_out <- waiting_table |>
    dplyr::group_by(.data$to_city) |>
    dplyr::summarise(
      median_wait = stats::median(.data$waiting_time, na.rm = TRUE),
      mean_wait   = mean(.data$waiting_time,          na.rm = TRUE),
      min_wait    = min(.data$waiting_time,            na.rm = TRUE),
      max_wait    = max(.data$waiting_time,            na.rm = TRUE),
      n_queries   = dplyr::n()
    ) |>
    dplyr::left_join(
      dplyr::select(cities_df, "city", "station_id"),
      by = c("to_city" = "city")
    ) |>
    dplyr::rename(to_station_id = "station_id") |>
    dplyr::mutate(
      group_id  = as.integer(group_id),
      region    = region,
      from_city = origin_city
    ) |>
    dplyr::select(
      "group_id", "region", "from_city", "to_city", "to_station_id",
      "median_wait", "mean_wait", "min_wait", "max_wait", "n_queries"
    )

  # ── Save JSON ─────────────────────────────────────────────────────────────
  jsonlite::write_json(
    list(cities = cities_out, summary = summary_out),
    path        = output_path,
    pretty      = TRUE,
    auto_unbox  = TRUE
  )

  message("Saved region data to: ", output_path)
  invisible(list(cities = cities_out, summary = summary_out))
}
