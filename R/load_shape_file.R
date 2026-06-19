#' @title Locate (and if needed unzip) the Swiss boundary shapefile
#'
#' @description
#' Prepare the base-map shapefile shipped in the `2026_GEOM_TK` folder. If
#' `source` points to a `.zip` archive it is extracted into `cache_dir`;
#' otherwise the folder is scanned for a suitable `.shp` (by default a canton
#' boundary layer). The chosen shapefile and all its sidecar files
#' (`.shx`, `.dbf`, `.prj`, `.cpg`, ...) are copied into `cache_dir` so later
#' calls reuse the cache instead of re-scanning or re-extracting.
#'
#' @param source Path to the `2026_GEOM_TK` folder or to its `.zip` archive.
#' @param cache_dir Directory used to cache the extracted/selected shapefile.
#'   Defaults to a stable per-session folder under [tempdir()].
#' @param pattern Regular expression used to pick the `.shp` among several.
#'   Defaults to canton boundaries (`"Canton"`).
#' @param refresh If `TRUE`, ignore an existing cache and rebuild it.
#'
#' @return Path to the cached `.shp` file, ready for [read_map_wgs84()].
#'
#' @examples
#' \dontrun{
#' shp <- prepare_shapefile("2026_GEOM_TK")
#' }
#'
#' @export
prepare_shapefile <- function(source = "2026_GEOM_TK",                        # folder or .zip holding the geodata
                              cache_dir = file.path(tempdir(), "zt_shapefile"),# where the chosen shapefile is cached
                              pattern = "Canton",                             # which layer to prefer when several exist
                              refresh = FALSE) {                              # force a cache rebuild when TRUE

  # make sure the source exist on disk
  if (!file.exists(source)) {
    stop("Shapefile source not found: ", source, call. = FALSE)
  }

  # make sure the cache directory exists
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  # Reuse the cache if it already holds a matching shapefile.
  if (!refresh) {
    cached <- list.files(cache_dir, pattern = "\\.shp$", full.names = TRUE)
    cached <- grep(pattern, cached, value = TRUE)
    if (length(cached) >= 1L) {
      return(cached[[1]])
    }
  }

  # If the source is a zip archive, extract it into a working directory first.
  search_dir <- source
  if (grepl("\\.zip$", source, ignore.case = TRUE)) {
    extract_dir <- file.path(cache_dir, "unzipped")
    utils::unzip(source, exdir = extract_dir)
    search_dir <- extract_dir
  }

  # Find candidate .shp files, preferring those matching `pattern`.
  shp_files <- list.files(search_dir, pattern = "\\.shp$",
                          recursive = TRUE, full.names = TRUE)
  if (length(shp_files) == 0L) {
    stop("No .shp file found under: ", search_dir, call. = FALSE)
  }
  matched <- grep(pattern, shp_files, value = TRUE)
  chosen <- if (length(matched) >= 1L) matched[[1]] else shp_files[[1]]

  # Cache the chosen shapefile together with all its sidecar files.
  stem <- tools::file_path_sans_ext(chosen)
  sidecars <- list.files(
    dirname(chosen),
    pattern = paste0("^", basename(stem), "\\."),
    full.names = TRUE
  )
  file.copy(sidecars, cache_dir, overwrite = TRUE)                            # copy shp/shx/dbf/prj/cpg into the cache

  file.path(cache_dir, basename(chosen))                                      # return the path to the cached .shp
}
