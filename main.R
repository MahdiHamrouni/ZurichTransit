# main.R ---------------------------------------------------------------------
# Entry point: build the mandatory regional waiting-time map (assignment 3.7)
# for the Zurich / Eastern Switzerland region by calling the pipeline in
# R/pipeline.R.
#
# Run from the project root:  Rscript main.R
# ----------------------------------------------------------------------------

# --- Packages ---------------------------------------------------------------
library(readr)      # read_csv() used by city_swss_extract.R
library(jsonlite)   # fromJSON()/toJSON() for the city + waiting-time JSON
library(dplyr)      # data wrangling (filter/select/joins) across the pipeline
library(ggplot2)    # the map is a ggplot object
library(sf)         # read and reproject the shapefile
library(scales)     # comma-formatted population legend

# --- Locate project files ---------------------------------------------------
project_root <- tryCatch(dirname(sys.frame(1)$ofile), error = function(e) getwd())  # this file's folder when sourced...
if (is.null(project_root) || !nzchar(project_root)) project_root <- getwd()         # ...else fall back to the working dir

REGION    <- "Zurich / Eastern Switzerland"                                   # the region this group must map
csv_path  <- file.path(project_root, "Data", "SwissCities.csv")               # city coordinates / population
json_path <- file.path(project_root, "Data", "example_waiting_time_data_map.json")  # waiting-time fallback data
geom_dir  <- file.path(project_root, "2026_GEOM_TK")                          # base-map shapefile folder

# --- Load the pipeline functions --------------------------------------------
for (f in c("city_swss_extract.R", "load_shapefile.R", "transform_map.R",     # source every R/ file the pipeline needs
            "fetch_api.R", "align_cities.R", "plot_waiting_map.R",
            "pipeline.R")) {
  source(file.path(project_root, "R", f))                                     # make each function available in this session
}

# --- Run the pipeline -------------------------------------------------------
waiting_map <- generate_waiting_map(                                          # run all stages and get the map back
  region    = REGION,                                                         # which region to map
  csv_path  = csv_path,                                                       # where the city data lives
  json_path = json_path,                                                      # where the waiting-time fallback lives
  geom_dir  = geom_dir,                                                       # where the shapefile lives
  output    = file.path(project_root, "waiting_map.png")                      # also save the map to this PNG
)

print(waiting_map)                                                            # display the map (e.g. in RStudio)
