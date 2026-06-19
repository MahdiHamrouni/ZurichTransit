# ZurichTransit

An R package for downloading, analyzing, and visualizing public transport accessibility in Switzerland, focused on the **Zurich / Eastern Switzerland** region. It queries the [search.ch timetable API](https://search.ch/timetable/api/), computes the waiting time to the next departure for each destination, and produces a regional map of accessibility.

## Authors

| Name | Role |
|---|---|
| Mahdi Hamrouni | Author, Maintainer |
| Giorgio De Siena | Author |
| Anna Dell'Aquila | Author |
| Aron Maggisano | Author |
| Mattia Della Monica | Author |
| Manuel Grosso | Author |

## Installation

First, install all the necessary libraries by running the following command:

```r
install.packages(c("dplyr", "ggplot2", "httr", "jsonlite", "purrr", 
                   "readr", "rlang", "sf", "stringr", "tibble", "scales"))
```

Then, install the package using the following code:

```r
install.packages("PATH", repos = NULL, type = "source")
```

*(Note: Remember to replace **"PATH"** with the actual file path on your computer, e.g. `"ZurichTransit_0.1.0.tar.gz"`).*

## Required data

Before using the package, make sure you have:

- **`SwissCities.csv`** — table of Swiss cities with columns `city`, `is_origin`, `station_name`, `station_id`, `latitude`, `longitude`, `canton`, `population`, `region`.
- **`2026_GEOM_TK/`** — folder (or `.zip`) containing the Swiss canton boundary shapefile.

The region JSON (cities + waiting-time summary) consumed by the map is **not** required up front: it is produced by `save_region_data()` (see Step 1 below).

## Usage

The package has two main entry points: `save_region_data()` collects the data from the API and saves it to JSON, and `generate_waiting_map()` reads that JSON and draws the map.

```r
library(ZurichTransit)

# Step 1 — collect data from the API and save to JSON (run once)
save_region_data(
  csv_path    = "SwissCities.csv",
  group_id    = "3",
  region      = "Zurich / Eastern Switzerland",
  output_path = "Data/zurich_data.json"
)

# Step 2 — generate the map from the saved JSON
generate_waiting_map(
  region    = "Zurich / Eastern Switzerland",
  json_path = "Data/zurich_data.json",
  geom_dir  = "2026_GEOM_TK",
  output    = "waiting_map.png"   # optional: also save the map to file
)
```

### Step by step

`generate_waiting_map()` chains the exported building blocks below. You can call them directly for finer control, starting from the JSON written by `save_region_data()`:

```r
# Load cities and summary from the saved JSON
region_data <- jsonlite::fromJSON("Data/zurich_data.json")
cities  <- tibble::as_tibble(region_data$cities)
summary <- tibble::as_tibble(region_data$summary)

# 1. Align destination cities with their waiting times
aligned <- align_waiting_times(cities, summary)

# 2. Locate / unzip / cache the base-map shapefile
shp <- prepare_shapefile("2026_GEOM_TK")

# 3. Read the base map and reproject it to WGS84 (lon/lat)
cantons <- read_map_wgs84(shp)

# 4. Plot the map
plot_waiting_map(cantons, aligned, title = "Waiting times - Zurich region")
```

## Exported functions

| Function | Purpose |
|---|---|
| `save_region_data()` | Collect API data + city data and write them to a region JSON. |
| `generate_waiting_map()` | Full map pipeline: read the JSON, build and (optionally) save the map. |
| `extract_city_df()` | Filter `SwissCities.csv` by region into a data frame of cities. |
| `load_region_cities()` | Parse a cities JSON (string or `.json` path) into a tibble. |
| `fetch_waiting_times()` | Adapter that returns a per-destination waiting-time summary from the API. |
| `align_waiting_times()` | Join cities with their waiting times; split origin from destinations. |
| `prepare_shapefile()` | Locate, unzip and cache the Swiss canton boundary shapefile. |
| `read_map_wgs84()` | Read the shapefile and reproject it to EPSG:4326. |
| `plot_waiting_map()` | Draw the regional waiting-time map with `ggplot2`. |

## How it works

```
SwissCities.csv ──► extract_city_df() ──────────────► cities
                                                         │
search.ch API ──► get_all_connections() ──► compute_waiting_times() ──► summary
                                                         │
                                  save_region_data()  ◄──┘
                                          │
                            region JSON (cities + summary)
                                          │
2026_GEOM_TK ──► prepare_shapefile() ──► read_map_wgs84() ──► cantons
                                          │
                              align_waiting_times()
                                          │
                               plot_waiting_map()
                                          │
                            generate_waiting_map() ──► ggplot2 map
```

1. **City extraction** — `extract_city_df()` filters `SwissCities.csv` by region and selects the city columns (coordinates, station, canton, population, origin flag).
2. **API queries** — inside `save_region_data()`, `get_all_connections()` loops over every origin-destination / time combination, caches each API response as an `.rds` file under `cache/`, and `compute_waiting_times()` derives the minimum waiting time to the next departure per destination.
3. **Persistence** — `save_region_data()` writes a single JSON holding both the `cities` and the `summary` (median / mean / min / max waiting time per destination).
4. **Map** — `generate_waiting_map()` reads that JSON, aligns cities with their waiting times, loads the canton polygons, and calls `plot_waiting_map()`: point size encodes population, fill colour encodes the median waiting time (plasma palette), and the origin station is marked with a gold diamond.

## Dependencies

`dplyr`, `ggplot2`, `httr`, `jsonlite`, `purrr`, `readr`, `rlang`, `sf`, `stringr`, `tibble`, `scales`

## License

MIT — see [LICENSE](LICENSE.md)
