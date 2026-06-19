#' @title Generate the regional waiting-time map (full pipeline)
#'
#' @description
#' End-to-end pipeline that produces the regional waiting-time map from a JSON
#' file previously created by [save_region_data()]. It chains every stage:
#' \enumerate{
#'   \item [prepare_shapefile()] - find / unzip / cache the base-map shapefile;
#'   \item [read_map_wgs84()] - read it and transform to EPSG:4326;
#'   \item Load \code{cities} and \code{summary} from \code{json_path};
#'   \item [align_waiting_times()] - join cities with their waiting times;
#'   \item [plot_waiting_map()] - draw the map.
#' }
#'
#' @param region Region name used as the map title.
#' @param json_path Path to the JSON file created by [save_region_data()],
#'   containing both \code{cities} and \code{summary} sections.
#' @param geom_dir Path to the \code{2026_GEOM_TK} folder (or its \code{.zip}).
#' @param output Optional path; if given, the map is also saved there as an image.
#'
#' @return A [ggplot2][ggplot2::ggplot] object (returned invisibly when saved).
#'
#' @examples
#' \dontrun{
#' # Step 1 - collect data from API and save (run once)
#' save_region_data(
#'   csv_path    = "SwissCities.csv",
#'   group_id    = "3",
#'   region      = "Zurich / Eastern Switzerland",
#'   output_path = "Data/zurich_data.json"
#' )
#'
#' # Step 2 - generate the map from the saved JSON
#' p <- generate_waiting_map(
#'   region   = "Zurich / Eastern Switzerland",
#'   json_path = "Data/zurich_data.json",
#'   geom_dir  = "2026_GEOM_TK",
#'   output    = "waiting_map.png"
#' )
#' }
#'
#' @export
generate_waiting_map <- function(region,                           # used as the map title
                                 json_path,                        # JSON produced by save_region_data()
                                 geom_dir = "2026_GEOM_TK",        # folder/zip with the base-map shapefile
                                 output = NULL) {                  # optional image path to also save the map

  # Load cities and summary from the JSON created by save_region_data()
  if (!file.exists(json_path)) {
    stop("JSON file not found: ", json_path,
         "\nRun save_region_data() first to collect and save the data.",
         call. = FALSE)
  }
  region_data <- jsonlite::fromJSON(json_path)
  cities      <- tibble::as_tibble(region_data$cities)
  summary     <- tibble::as_tibble(region_data$summary)

  # Base map: locate the shapefile and reproject to lon/lat
  shp_path <- prepare_shapefile(geom_dir)
  cantons  <- read_map_wgs84(shp_path)

  # Align cities with their waiting times
  aligned <- align_waiting_times(cities, summary)

  # Build the map
  waiting_map <- plot_waiting_map(
    cantons, aligned,
    title = paste0("Public transport waiting time - ", region)
  )

  if (!is.null(output)) {
    ggplot2::ggsave(output, waiting_map, width = 10, height = 8, dpi = 150)
    message("Saved waiting-time map to: ", output)
    return(invisible(waiting_map))
  }

  waiting_map
}
