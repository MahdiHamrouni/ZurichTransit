#' @title Mandatory regional waiting-time accessibility map
#'
#' @description
#' Produce the mandatory regional waiting-time map. The map shows the Swiss
#' canton borders, highlights the cantons of the assigned region, draws every
#' destination city as a point whose **size is proportional to population** and
#' whose **colour is proportional to the median waiting time**, labels the
#' destinations, and highlights the origin station with a star.
#'
#' @param summary A destination summary as returned by
#'   [summarise_waiting_times()].
#' @param cities The region's station data (see [read_swiss_cities()]); supplies
#'   coordinates, population and the origin flag.
#' @param shp_path Path to the canton boundaries shapefile. Defaults to the
#'   bundled file (see [canton_shapefile_path()]).
#'
#' @return A [ggplot2][ggplot2::ggplot] object.
#'
#' @examples
#' \dontrun{
#' cities  <- read_swiss_cities(group_id = 3)
#' routes  <- fetch_routes(build_query_table(cities))
#' summary <- summarise_waiting_times(compute_waiting_times(routes))
#' plot_waiting_map(summary, cities)
#' }
#'
#' @export
plot_waiting_map <- function(summary, cities, shp_path = canton_shapefile_path()) {
  cantons <- sf::read_sf(shp_path)
  cantons <- sf::st_transform(cantons, 4326)

  region_cantons <- unique(cities$canton)
  cantons$in_region <- cantons$KTKZ %in% region_cantons

  origin <- dplyr::filter(cities, .data$is_origin)

  dest <- cities |>
    dplyr::filter(!.data$is_origin) |>
    dplyr::inner_join(
      dplyr::select(summary, "to_city", "median_wait", "n_queries"),
      by = c("city" = "to_city")
    )

  ggplot2::ggplot() +
    ggplot2::geom_sf(data = cantons, fill = "grey95", color = "grey70",
                     linewidth = 0.3) +
    ggplot2::geom_sf(data = dplyr::filter(cantons, .data$in_region),
                     fill = "#e8f0e8", color = "grey40", linewidth = 0.5) +
    ggplot2::geom_point(
      data = dest,
      ggplot2::aes(x = .data$longitude, y = .data$latitude,
                   size = .data$population, fill = .data$median_wait),
      shape = 21, color = "grey20", alpha = 0.9
    ) +
    ggplot2::geom_point(
      data = origin,
      ggplot2::aes(x = .data$longitude, y = .data$latitude),
      shape = 23, size = 6, fill = "gold", color = "black", stroke = 1.1
    ) +
    ggplot2::geom_text(
      data = dest,
      ggplot2::aes(x = .data$longitude, y = .data$latitude, label = .data$city),
      size = 2.8, vjust = -1.1, color = "grey10"
    ) +
    ggplot2::geom_text(
      data = origin,
      ggplot2::aes(x = .data$longitude, y = .data$latitude, label = .data$city),
      size = 3.4, fontface = "bold", vjust = -1.4, color = "black"
    ) +
    ggplot2::scale_fill_viridis_c(
      name = "Median wait (min)", option = "plasma", direction = -1
    ) +
    ggplot2::scale_size_area(
      name = "Population", max_size = 12, labels = scales::comma
    ) +
    ggplot2::coord_sf(
      xlim = grDevices::extendrange(cities$longitude, f = 0.15),
      ylim = grDevices::extendrange(cities$latitude, f = 0.15)
    ) +
    ggplot2::labs(
      title = paste0("Public transport waiting time - ", unique(origin$region)),
      subtitle = paste0("Origin ", origin$city,
                        " = gold diamond. Point colour = median wait to next departure,",
                        " size = population."),
      x = NULL, y = NULL
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      panel.grid = ggplot2::element_line(color = "grey92"),
      legend.position = "right"
    )
}
