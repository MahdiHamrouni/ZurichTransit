#' @title Fetch a single route from the search.ch API
#'
#' @description
#' Queries the search.ch timetable API for connections between two stations.
#' Results are cached locally as `.rds` files so repeated calls with the same
#' arguments skip the API.
#'
#' @param from Departure station ID or name.
#' @param to Arrival station ID or name.
#' @param date Query date in `"DD.MM.YYYY"` format.
#' @param time Query time in `"HH:MM"` format.
#' @param num Maximum number of connections to return. Defaults to `5`.
#' @param cache_dir Directory for cached responses. Defaults to `"cache"`.
#'
#' @return A parsed list from the API JSON response.
#'
#' @noRd


get_route <- function(from, to, date, time, num = 5, cache_dir="cache") {

  #check if file exists
  cache_file <- file.path(
    cache_dir,
    stringr::str_c(from, "_", to, "_", stringr::str_replace_all(date, "\\.", "-"), "_", stringr::str_remove_all(time, ":"),".rds")
  )

  if(file.exists(cache_file)){
    message("Loading file")
    parsed_file <- readRDS(cache_file)
  }else{
    # create API request call
    response <- httr::GET(
      url   = "https://search.ch/timetable/api/route.json",
      query = list(
        from = from,
        to   = to,
        date = date,
        time = time,
        num  = num
      )
    )
    Sys.sleep(4)
    # parse JSON response
    parsed_file <- httr::content(response, as = "parsed", type = "application/json")

    # save response locally
    if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)
    saveRDS(parsed_file, cache_file)
  }
  return(parsed_file)
}

#' @title Print a formatted summary of API connections
#'
#' @description
#' Prints each connection in a parsed API response showing departure, arrival,
#' duration and occupancy.
#'
#' @param parsed_response A parsed API response from [get_route()].
#'
#' @return Called for its side effect (printing). Returns `NULL` invisibly.
#'
#' @noRd
print_routes <- function(parsed_response) {

  connections <- parsed_response$connections

  cat(stringr::str_c("Connessioni trovate: ", parsed_response$count, "\n\n"))

  purrr::walk(seq_along(connections), function(i) {
    conn <- connections[[i]]

    durata_min <- conn$duration / 60

    cat(stringr::str_c("\u2500\u2500 Connessione ", i, " ", strrep("\u2500", 25), "\n"))
    cat(stringr::str_c("  Da:       ", conn$from, "  \u2192  ", conn$to, "\n"))
    cat(stringr::str_c("  Partenza: ", conn$departure, "\n"))
    cat(stringr::str_c("  Arrivo:   ", conn$arrival, "\n"))
    cat(stringr::str_c("  Durata:   ", durata_min, " min\n"))
    cat(stringr::str_c("  Occupaz.: ", conn$occupancy, "%\n"))
    cat("\n")
  })
}

#' @title Fetch all connections for the Zurich / Eastern Switzerland region
#'
#' @description
#' Orchestrates a full batch of API queries for the region defined in
#' `SwissCities.csv`. Builds the query table via [generate_routes()], calls
#' [get_route()] for every origin-destination / time combination, and prints
#' results with [print_routes()].
#'
#' @return A list of two elements: the raw API responses and the query table.
#'
#' @noRd
get_all_connections <- function() {
  group_id <- '3'
  region <- "Zurich / Eastern Switzerland"
  path <- "SwissCities.csv"
  query_date  <- format(Sys.Date(), "%d.%m.%Y")
  query_time <- c("08:00", "10:00", "12:00", "15:00", "18:00")

  result_routes <- generate_routes(path, group_id, region, query_date, query_time)
  print(result_routes)

  results_data <- list()

  for (i in seq_len(nrow(result_routes))) {
    results_data[[i]] <- get_route(
      from = result_routes$from_station_id[i],
      to   = result_routes$to_station_id[i],
      date = result_routes$query_date[i] ,
      time = result_routes$query_time[i]
    )
  }

  for(i in seq_along(results_data)) {
    print_routes(results_data[[i]])
  }

  return(list(results_data, result_routes))
}


