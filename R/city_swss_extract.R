#' @title Extract Swiss City Data to JSON
#' @param path String path to the CSV file
#' @param region String name of the region to filter
#' @description Filters Swiss cities by a specific region and converts the selected columns into a JSON format
#' @return A JSON string containing city details
#' @export

# Read the cities of one region from the CSV and return them as a JSON string.
extract_city_json <- function(path, region) {
  swiss_cities <- read_csv(path)

  target_string <- region

  json_data <- swiss_cities %>%
    filter(region == target_string) %>% 
    select(city, is_origin, station_name, station_id, latitude, longitude, canton, population) %>%
    toJSON(pretty = TRUE)

  return(json_data)
}
