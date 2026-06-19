#' @title Generate the regional waiting-time map (full pipeline)
#'
#' @description
#' End-to-end pipeline that produces the mandatory waiting-time map for one
#' region. It chains every stage together:
#' \enumerate{
#'   \item [prepare_shapefile()] - find / unzip / cache the base-map shapefile;
#'   \item [read_map_wgs84()] - read it and transform to EPSG:4326;
#'   \item [extract_city_json()] + [load_region_cities()] - get the region's
#'         cities from the CSV;
#'   \item [fetch_waiting_times()] - query the API (stub); when it returns
#'         `NULL`, fall back to the waiting times stored in `json_path`;
#'   \item [align_waiting_times()] - join cities with their waiting times;
#'   \item [plot_waiting_map()] - draw the map
#' }
#'
#' @param region Region name to map (must match `SwissCities.csv`).
#' @param csv_path Path to `SwissCities.csv`
#' @param json_path Path to the JSON holding the waiting-time `summary`
#'   (used as a fallback while the API is not implemented)
#' @param geom_dir Path to the `2026_GEOM_TK` folder (or its `.zip`)
#' @param output Optional path; if given, the map is also saved there as an image
#'
#' @return A [ggplot2][ggplot2::ggplot] object (returned invisibly when saved)
#'
#' @examples
#' \dontrun{
#' p <- generate_waiting_map("Zurich / Eastern Switzerland",
#'                           "Data/SwissCities.csv",
#'                           "Data/example_waiting_time_data_map.json",
#'                           "2026_GEOM_TK",
#'                           output = "waiting_map.png")
#' }
#'
#' @export
generate_waiting_map <- function(region,                                   # region label to filter and title the map
                                 csv_path,                                 # path to SwissCities.csv (city coords/pop)
                                 json_path,                                # path to the JSON waiting-time fallback
                                 geom_dir = "2026_GEOM_TK",                # folder/zip with the base-map shapefile
                                 output = NULL) {                          # optional image path to also save the map
 
  # Base map: locate the shapefile, then reproject it to lon/lat (Points 1 and 2)
  shp_path <- prepare_shapefile(geom_dir)                                  # find/unzip/cache and return the .shp path
  cantons  <- read_map_wgs84(shp_path)                                     # read it and transform to EPSG:4326

  # Region cities from SwissCities.csv (via city_swss_extract.R) (Point 3)
  city_json <- extract_city_json(csv_path, region)
  cities    <- load_region_cities(city_json)

  # Waiting times: try the API first, otherwise use the bundled JSON (Point 4)
  summary <- fetch_waiting_times(cities)
  if (is.null(summary)) {
    message("API not implemented yet - using waiting times from ",
            basename(json_path))
    summary <- tibble::as_tibble(jsonlite::fromJSON(json_path)$summary)
  }

  # Align cities with their waiting times (Point 5)
  aligned <- align_waiting_times(cities, summary)

  # Build the map (Point 6)
  waiting_map <- plot_waiting_map(
    title = paste0("Public transport waiting time - ", region)
  )

  if (!is.null(output)) {
    ggplot2::ggsave(output, waiting_map, width = 10, height = 8, dpi = 150)
    message("Saved waiting-time map to: ", output)
    return(invisible(waiting_map))
  }

  waiting_map                                                              # otherwise just return the plot object
}
