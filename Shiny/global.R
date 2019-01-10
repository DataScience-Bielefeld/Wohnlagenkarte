# Load required packages
library(dplyr)
library(sp)
library(RSQLite)
library(DBI)

# Decompress SQLite-files if necessary
gunzip(
  "./data/wohnlagenkarte.sqlite.gz",
  temporary=FALSE,
  skip=TRUE,
  overwrite=FALSE,
  remove=FALSE
)
gunzip(
  "./data/wohnlagenkarte_feature.sqlite.gz",
  temporary=FALSE,
  skip=TRUE,
  overwrite=FALSE,
  remove=FALSE
)

# Provide names list of features and means of transportation to select
choices_feature <- list(
  "Bar" = "bar",
  "Biergarten" ="biergarten",
  "Cafe" = "cafe",
  "Eisdiele" = "ice_cream",
  "Kneipe" = "pub",
  "Restaurant" = "restaurant",
  "Kindergarten" = "kindergarten",
  "Schule" = "school",
  "Hochschule" = "university"
)
choices_transportation <- list(
  "Gehen" = "foot",
  "Radfahren" ="bike",
  "Auto" = "car"
)


################################################################################
#### Functions
################################################################################

# Based on prepared SQLite-DB return SpatialLinesDataFrame of all ...
# ... buildings within a GPS-rectangle
get_building_polygons <- function(path, north, south, west, east) {
  # Establish connection to SQLite-DB
  con <- dbConnect(
    drv = RSQLite::SQLite(),
    dbname = path
  )
  # Retrieve data.frame with columns "id", "lon" and "lat"
  res <- dbSendQuery(
    con,
    paste0(
      "
      SELECT
        id, lon, lat
      FROM
        building_line
      WHERE
        id IN (
          SELECT
            id
          FROM
            building_coord
          WHERE ", "lon <= ", east,
          " AND lon >= ", west,
          " AND lat <= ", north,
          " AND lat >= ", south,
        ")"
      )
    )
  df_res <- dbFetch(res)
  dbClearResult(res)
  # Initialise list to store Lines
  lst_lines <- list()
  # Run through all id's and create Lines from longitude and latitude
  for (id in unique(df_res$id)) {
    lst_lines[[id]] <- sp::Lines(
      list(
        sp::Line(df_res[df_res$id == id,c("lon", "lat")])
      ),
      ID = id
    )
  }

# Retrieve data.frame with metadata of buildings
  res <- dbSendQuery(
    con,
    paste0(
      "
      SELECT
        osm_id AS id, code, fclass, name, type
      FROM
        building
      WHERE
        osm_id IN (
          SELECT
            id
          FROM
            building_coord
          WHERE ", "lon <= ", east,
          " AND lon >= ", west,
          " AND lat <= ", north,
          " AND lat >= ", south,
      ")"
      )
    )
  df_res <- dbFetch(res)
  rownames(df_res) <- df_res$id
  dbClearResult(res)
  # Close connection to SQLite-DB
  dbDisconnect(con)
  # Return SpatialLinesDataFrame
  return(sp::SpatialLinesDataFrame(sp::SpatialLines(lst_lines), data = df_res))
}

# Based on prepared SQLite-DB return data.frame of all ...
# ... ratings for provided building id's
get_rating_building <- function(path, ids, feature, transportation) {
  # Establish connection to SQLite-DB
  con <- dbConnect(
    drv = RSQLite::SQLite(),
    dbname = path
  )
  # Retrieve data.frame with columns "id" and some density
  # (density = our preliminary rating for now)
  res <- dbSendQuery(
    con,
    paste0(
      "
      SELECT
        id, DENSITY_", feature, "_", transportation," as rating
      FROM
        building_feature
      WHERE
        id IN ( ",
        paste0(ids, collapse = ",")
        ,")
      ORDER BY id ASC"
    )
  )
  df_res <- dbFetch(res)
  dbClearResult(res)
  # Close connection to SQLite-DB
  dbDisconnect(con)
  # Return data.frame
  return(df_res)
}
