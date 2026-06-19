#' @title Extract Swiss City Data to JSON
#' @param path String path to the CSV file
#' @param region String name of the region to filter
#' @description Filters Swiss cities by a specific region and converts the selected columns into a JSON format
#' @return A JSON string containing city details
#' @export
extract_city_df <- function(path, region) {
  swiss_cities <- readr::read_csv(path)

  target_string <- region

  df_result <- swiss_cities |>
    dplyr::filter(.data$region == target_string) |>
    dplyr::select("city", "is_origin", "station_name", "station_id", "latitude", "longitude", "canton", "population")

  return(df_result)
}
