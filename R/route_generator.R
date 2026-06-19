#' @title Generate all origin-destination route query combinations
#'
#' @description
#' Reads the city CSV, isolates the origin station and destination cities for
#' the given region, and returns a data frame with one row per
#' origin-destination / query-time combination, ready for [get_route()].
#'
#' @param path Path to `SwissCities.csv`.
#' @param group_id Group identifier string for the query batch.
#' @param region Region name matching the `region` column in the CSV.
#' @param query_date Query date in `"DD.MM.YYYY"` format.
#' @param query_time Character vector of query times in `"HH:MM"` format.
#'
#' @return A `data.frame` with columns `group_id`, `region`, `from_city`,
#'   `to_city`, `from_station_id`, `to_station_id`, `query_date`, `query_time`.
#'
#' @noRd
generate_routes <- function(path, group_id, region, query_date, query_time) {
  df <- extract_city_df(path, region)

  # separa origine e destinazioni
  origin       <- df |> dplyr::filter(.data$is_origin == TRUE)
  destinations <- df |> dplyr::filter(.data$is_origin == FALSE)

  query_table <- data.frame()

  for (j in 1:nrow(destinations)) {
    for (time in query_time) {
      row <- data.frame(
        group_id        = group_id,
        region          = region,
        from_city       = origin$city[1],
        to_city         = destinations$city[j],
        from_station_id = origin$station_id[1],
        to_station_id   = destinations$station_id[j],
        query_date      = query_date,
        query_time      = time
      )
      query_table <- rbind(query_table, row)
    }
  }

  return(query_table)
}
