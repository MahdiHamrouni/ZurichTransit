#' @title Simplified route map coloured by transport mode (optional task)
#'
#' @description
#' Draw a simplified route map for one connection: each leg is drawn as a
#' straight segment between consecutive stops, coloured by transport mode and
#' labelled by line. Stops are shown as points. Coordinates come from
#' [parse_legs()]; legs without coordinates are dropped. The map does not
#' reproduce the exact physical alignment of the line.
#'
#' @param legs A legs table from [parse_legs()] (optionally filtered to a single
#'   `connection_id`).
#' @param shp_path Path to the canton boundaries shapefile (background).
#'   Defaults to the bundled file.
#'
#' @return A [ggplot2][ggplot2::ggplot] object.
#'
#' @examples
#' \dontrun{
#' resp <- get_route("8503000", "8506302", "2026-06-24", "08:00")
#' legs <- parse_legs(resp)
#' plot_route_map(dplyr::filter(legs, connection_id == 1))
#' }
#'
#' @export
plot_route_map <- function(legs, shp_path = canton_shapefile_path()) {
  legs <- dplyr::filter(
    legs,
    !is.na(.data$from_lon), !is.na(.data$from_lat),
    !is.na(.data$to_lon), !is.na(.data$to_lat)
  )
  if (nrow(legs) == 0L) {
    stop("No legs with coordinates available to map.", call. = FALSE)
  }

  cantons <- sf::st_transform(sf::read_sf(shp_path), 4326)

  stops <- dplyr::bind_rows(
    dplyr::transmute(legs, stop = .data$from_stop,
                     lon = .data$from_lon, lat = .data$from_lat),
    dplyr::transmute(legs, stop = .data$to_stop,
                     lon = .data$to_lon, lat = .data$to_lat)
  )
  stops <- dplyr::distinct(stops)

  all_lon <- c(legs$from_lon, legs$to_lon)
  all_lat <- c(legs$from_lat, legs$to_lat)

  ggplot2::ggplot() +
    ggplot2::geom_sf(data = cantons, fill = "grey95", color = "grey75",
                     linewidth = 0.3) +
    ggplot2::geom_segment(
      data = legs,
      ggplot2::aes(x = .data$from_lon, y = .data$from_lat,
                   xend = .data$to_lon, yend = .data$to_lat,
                   color = .data$mode),
      linewidth = 1.1
    ) +
    ggplot2::geom_point(
      data = stops,
      ggplot2::aes(x = .data$lon, y = .data$lat),
      size = 2, color = "grey20"
    ) +
    ggplot2::geom_text(
      data = stops,
      ggplot2::aes(x = .data$lon, y = .data$lat, label = .data$stop),
      size = 2.6, vjust = -1, color = "grey10"
    ) +
    ggplot2::scale_color_brewer(name = "Transport mode", palette = "Set1") +
    ggplot2::coord_sf(
      xlim = grDevices::extendrange(all_lon, f = 0.3),
      ylim = grDevices::extendrange(all_lat, f = 0.3)
    ) +
    ggplot2::labs(title = "Simplified route map", x = NULL, y = NULL) +
    ggplot2::theme_minimal()
}
