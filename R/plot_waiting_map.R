#' @title Plot the mandatory regional waiting-time map
#'
#' @description
#' Draw the regional waiting-time map required by the assignment. On top of the
#' Swiss canton borders it highlights the region's cantons, overlays every
#' destination city as a point whose **size is proportional to population** and
#' whose **colour is proportional to the median waiting time**, labels the
#' destinations, and marks the origin station with a gold star/diamond.
#'
#' All spatial inputs are expected in EPSG:4326 (see [read_map_wgs84()]).
#'
#' @param cantons An [sf][sf::st_sf] object of Swiss canton polygons in
#'   EPSG:4326 (from [read_map_wgs84()]).
#' @param aligned The result of [align_waiting_times()] (`origin` +
#'   `destinations`).
#' @param region_cantons Canton codes (column `KTKZ`) to highlight as the
#'   region. Defaults to the cantons present in the data.
#' @param title Plot title. Defaults to a generic waiting-time title.
#'
#' @return A [ggplot2][ggplot2::ggplot] object.
#'
#' @export
plot_waiting_map <- function(cantons, aligned,                          # base map + aligned origin/destinations
                             region_cantons = NULL,                     # canton codes to shade as the region
                             title = "Public transport waiting time") { # headline shown on the map
  origin <- aligned$origin                                              # single origin row (the gold diamond)
  dest   <- aligned$destinations                                        # destination cities with waiting times

  if (is.null(region_cantons)) {                                        # if the caller did not specify the region...
    region_cantons <- unique(c(origin$canton, dest$canton))             # ...derive it from the cantons in the data
  }
  cantons$in_region <- cantons$KTKZ %in% region_cantons                 # flag which canton polygons belong to the region

  ggplot2::ggplot() +                                                   # start an empty ggplot canvas
    ggplot2::geom_sf(data = cantons, fill = "grey95", color = "grey70", # draw all Swiss cantons as the background
                     linewidth = 0.3) +
    ggplot2::geom_sf(data = dplyr::filter(cantons, .data$in_region),    # overdraw the region's cantons...
                     fill = "#e8f0e8", color = "grey40", linewidth = 0.5) +  # ...in a highlighted green tone
    ggplot2::geom_point(                                                # plot the destination cities as points
      data = dest,
      ggplot2::aes(x = .data$longitude, y = .data$latitude,            # position by lon/lat
                   size = .data$population, fill = .data$median_wait),  # size = population, fill colour = median wait
      shape = 21, color = "grey20", alpha = 0.9                         # filled circle with a thin dark border
    ) +
    ggplot2::geom_point(                                                # plot the origin station on top
      data = origin,
      ggplot2::aes(x = .data$longitude, y = .data$latitude),           # position by lon/lat
      shape = 23, size = 6, fill = "gold", color = "black", stroke = 1.1  # a gold diamond to make it stand out
    ) +
    ggplot2::geom_text(                                                 # label every destination city
      data = dest,
      ggplot2::aes(x = .data$longitude, y = .data$latitude, label = .data$city),  # text placed at the city point
      size = 2.8, vjust = -1.1, color = "grey10"                        # small label nudged above the point
    ) +
    ggplot2::geom_text(                                                 # label the origin city
      data = origin,
      ggplot2::aes(x = .data$longitude, y = .data$latitude, label = .data$city),  # text placed at the origin point
      size = 3.4, fontface = "bold", vjust = -1.4, color = "black"      # larger bold label above the diamond
    ) +
    ggplot2::scale_fill_viridis_c(                                      # continuous colour scale for the waiting time
      name = "Median wait (min)", option = "plasma", direction = -1     # plasma palette, reversed (short wait = bright)
    ) +
    ggplot2::scale_size_area(                                           # map population to point area (not radius)
      name = "Population", max_size = 12, labels = scales::comma         # cap the biggest point, format legend with commas
    ) +
    ggplot2::coord_sf(                                                  # set the visible map window...
      xlim = grDevices::extendrange(c(origin$longitude, dest$longitude), f = 0.15),  # ...x-range padded by 15%
      ylim = grDevices::extendrange(c(origin$latitude, dest$latitude), f = 0.15)     # ...y-range padded by 15%
    ) +
    ggplot2::labs(                                                      # titles and axis labels
      title = title,                                                    # main title (passed in by the caller)
      subtitle = paste0("Origin ", origin$city,                         # subtitle explaining the encodings...
                        " = gold diamond. Point colour = median wait to next",
                        " departure, size = population."),
      x = NULL, y = NULL                                                # hide the lon/lat axis titles
    ) +
    ggplot2::theme_minimal() +                                          # use a clean minimal theme
    ggplot2::theme(                                                     # a couple of theme tweaks:
      panel.grid = ggplot2::element_line(color = "grey92"),             # very light grid lines
      legend.position = "right"                                         # keep the legends on the right
    )
}
