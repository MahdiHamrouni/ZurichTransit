#' @title Read the base map and transform it to WGS84 (lon/lat)
#'
#' @description
#' Read the canton boundary shapefile with [sf::read_sf()] and reproject it to
#' geographic coordinates (EPSG:4326) with [sf::st_transform()], so the polygons
#' line up with the city longitude/latitude columns used for the overlay.
#'
#' @param shp_path Path to the `.shp` file, e.g. from [prepare_shapefile()].
#'
#' @return An [sf][sf::st_sf] object in EPSG:4326.
#'
#' @examples
#' \dontrun{
#' cantons <- read_map_wgs84(prepare_shapefile("2026_GEOM_TK"))
#' }
#'
#' @export
read_map_wgs84 <- function(shp_path = prepare_shapefile()) {
  cantons <- sf::read_sf(shp_path)
  sf::st_transform(cantons, 4326)
}
