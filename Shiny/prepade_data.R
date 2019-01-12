# Make sure to set the correct working directory
setwd("~/MeetUp/Wohnlagenkarte/Shiny")

################################################################################
#### Functions
################################################################################

# See https://blog.exploratory.io/calculating-distances-between-two-geo-coded-locations-358e65fcafae
get_geo_distance = function(long1, lat1, long2, lat2, units = "miles") {
  loadNamespace("purrr")
  loadNamespace("geosphere")
  longlat1 = purrr::map2(long1, lat1, function(x,y) c(x,y))
  longlat2 = purrr::map2(long2, lat2, function(x,y) c(x,y))
  distance_list = purrr::map2(
    longlat1,
    longlat2,
    function(x,y) geosphere::distHaversine(x, y)
  )
  distance_m = unlist(distance_list)
  if (units == "km") {
    distance = distance_m / 1000.0;
  }
  else if (units == "miles") {
    distance = distance_m / 1609.344
  }
  else {
    distance = distance_m
    # This will return in meter as same way as distHaversine function.
  }
  distance
}

################################################################################
#### Retrieve features from OpenStreetMap via overpass
################################################################################

# Load required libary
library(overpass)

# Define vector with all feature names
# See https://wiki.openstreetmap.org/wiki/DE:Key:amenity for more details
features <- c(
  "bar",
  "biergarten",
  "cafe",
  "ice_cream",
  "pub",
  "restaurant",
  "kindergarten",
  "school",
  "university",
  "research_institute"
)

# Initialise lists to store retrieved data
list_df_features <- list()

# Loop over all feature names, ...
for (feat in features) {
  # ... build quiery string ...
  query_txt <- paste0(
    '
    [out:xml][timeout:2500];
    area(3600062646)->.searchArea;
    (
    node["amenity"="', feat,'"](area.searchArea);
    way["amenity"="', feat,'"](area.searchArea);
    relation["amenity"="', feat,'"](area.searchArea);
    );
    out body;
    >;
    out skel qt;'
  )

  # ... retrieve result from Overpass-API ...
  query_result <- overpass::overpass_query(query_txt)

  # ... if returned result is a SpatialLinesDataFrame (multiple results) ...
  if( class(query_result)[1] == "SpatialLinesDataFrame" ) {
    # ... obtain GPS-coordinates of frames of buildings ...
    res <- lapply(
      slot(query_result, "lines"),
      function(x) lapply(slot(x, "Lines"), function(y) as.data.frame(slot(y, "coords")))
    )
    # ... compute mean longitude and latitude as center of buildings ...
    res <- lapply(res, function(x) c(mean(x[[1]]$lon), mean(x[[1]]$lat)))

    # ... store data in previously initialised list of data.frame's ...
    list_df_features[[feat]] <- data.frame(
      ID = names(res),
      lon = sapply(res, function(x) x[1]),
      lat = sapply(res, function(x) x[2])
    )
    # ... remove obsolete object(s) ...
    rm(res)
  # ... if returned result is a SpatialPointsDataFrame (single result) ...
  } else if ( class(query_result)[1] == "SpatialPointsDataFrame" ) {
    # ... store data in previously initialised list of data.frame's ...
    list_df_features[[feat]] <- data.frame(
      ID = query_result@data$id,
      lon = query_result@data$lon,
      lat = query_result@data$lat
    )
  }
  # ... remove obsolete object(s) ...
  rm(query_txt, query_result)
}

# Restrict to only those features with instances in Bielefeld
features <- features[features %in% names(list_df_features)]

################################################################################
#### Retrieve GPS-coordinates of buildings in Bielefeld
################################################################################

# 1. Go to https://download.geofabrik.de/europe/germany/nordrhein-westfalen/detmold-regbez.html
# 2. Download 'detmold-regbez-latest-free.shp.zip'
# 3. Store shapefile 'gis_osm_buildings_a_free_1.shp' in subfolder ./data

library(sf) # for working with shapefiles
library(progress) # display progess bar in lengthy for-loops
library(tibble) # additional functions to alter tibble's/data.frame's

# Read shapefile
bieleld_buildings <- read_sf(
  dsn = "./data",
  layer = "gis_osm_buildings_a_free_1"
)

# Use approximate GPS-coordinates to subset buildings ...
# ... from Regierungsbezirk Detmold
# To-Do: Use GPS-line of city border from OpenStreetMap
bielefeld_square <- list()
bielefeld_square[['north']] <- 52.1147
bielefeld_square[['south']] <- 51.9155
bielefeld_square[['west']] <- 8.3778
bielefeld_square[['east']] <- 8.6644

# Add columns with longitude and latitude of center of buildings
bieleld_buildings <- add_column(
  bieleld_buildings,
  "lon" = sapply(
    bieleld_buildings$geometry,
    function(x) mean(st_bbox(x)$xmin, st_bbox(x)$xmax)
  )
)
bieleld_buildings <- add_column(
  bieleld_buildings,
  "lat" = sapply(
    bieleld_buildings$geometry,
    function(x) mean(st_bbox(x)$ymin,st_bbox(x)$ymax)
  )
)
# Add columns with min/max values of longitude and latitude of buildings
bieleld_buildings <- add_column(
  bieleld_buildings,
  "lon_min" = sapply(bieleld_buildings$geometry, function(x) st_bbox(x)$xmin)
)
bieleld_buildings <- add_column(
  bieleld_buildings,
  "lat_min" = sapply(bieleld_buildings$geometry, function(x) st_bbox(x)$ymin)
)
bieleld_buildings <- add_column(
  bieleld_buildings,
  "lon_max" = sapply(bieleld_buildings$geometry, function(x) st_bbox(x)$xmax)
)
bieleld_buildings <- add_column(
  bieleld_buildings,
  "lat_max" = sapply(bieleld_buildings$geometry, function(x) st_bbox(x)$ymax)
)

# Only use those buildings of Regierungsbezirk Detmold which lie ...
# ... within a square around Bielefeld
bieleld_buildings <- bieleld_buildings[
  bieleld_buildings$lon_min > bielefeld_square$west &
  bieleld_buildings$lon_max < bielefeld_square$east &
  bieleld_buildings$lat_min > bielefeld_square$south &
  bieleld_buildings$lat_max < bielefeld_square$north,
]

# Initialise list of distance data.frame's
list_building_feature_distance <- list()

# For every feature ...
for (feat in features) {
  # ... construct a data.frame with ...
  list_building_feature_distance[[feat]] <- as.data.frame(
    matrix(
      # ... number of rows given by buildings in Bielefeld ...
      nrow = nrow(bieleld_buildings),
      # ... number of columns given by number of elements of featuer ...
      ncol = nrow(list_df_features[[feat]])
    )
  )

  # ... setup progress bar ...
  total <- nrow(list_df_features[[feat]])
  pb <- progress_bar$new(format = "processing [:bar] :current/:total (:percent) eta: :eta", total = total)

  # ... for every row index ...
  for (i in 1:nrow(list_df_features[[feat]])) {
    # ... use pre-defined function to compute geographic distance between ...
    # ... buildings and features ...
    list_building_feature_distance[[feat]][,i] <- get_geo_distance(
      list_df_features[[feat]]$lon[i],
      list_df_features[[feat]]$lat[i],
      bieleld_buildings$lon,
      bieleld_buildings$lat,
      units = "km"
    )
    # ... update counter of progress bar
    pb$tick()
  }
}

# Initialise data.frame to hold building id and GPS-coordinates of its border
building_coord_lines <- data.frame(id = NA, lon = NA, lat = NA)

# Setup progress bar
total <- nrow(bieleld_buildings)
pb <- progress_bar$new(
  format = "processing [:bar] :current/:total (:percent) eta: :eta",
  total = total
)

# For every row i.e. building ...
for (i in 1:nrow(bieleld_buildings)){
  # ... obtain GPS-coordinates of frame ...
  coord_i <- as(bieleld_buildings$geometry[i], "Spatial")@polygons[[1]]@Polygons[[1]]@coords
  # ... add rows to data.frame ...
  building_coord_lines <- rbind(
    building_coord_lines,
    data.frame(
      id = bieleld_buildings$osm_id[i],
      lon = coord_i[,1],
      lat = coord_i[,2]
    )
  )
  # ... update counter of progress bar
  pb$tick()
}

# Initialise data.frame for quick lookup of building id when restricting ...
# ... to particular GPS frame
building_coord_frame <- data.frame(
  id = rep(bieleld_buildings$osm_id, each = 4),
  lon = NA,
  lat = NA
)

# Setup progress bar
total <- nrow(bieleld_buildings)
pb <- progress_bar$new(
  format = "processing [:bar] :current/:total (:percent) eta: :eta",
  total = total
)

# For every row i.e. building ...
for ( i in 1:nrow(bieleld_buildings)) {
  # ... get combination min/max longitude and latitude ...
  building_coord_frame[((i-1)*4+1):(i*4),c("lon", "lat")] <- expand.grid(
    c(bieleld_buildings$lon_min[i], bieleld_buildings$lon_max[i]),
    c(bieleld_buildings$lat_min[i], bieleld_buildings$lat_max[i])
  )
  # ... update counter of progress bar
  pb$tick()
}

# Now that all GPS information has been stored in other data.frame's ...
# ... we may shrink the metadata data.frame
bieleld_buildings <- bieleld_buildings[
  ,
  c("osm_id", "code", "fclass", "name", "type")
]

################################################################################
#### Compute count of features and density for various means of transportation
################################################################################

# List of km-distances for desired maximum distance per transportation type
distance_transport <- list()
distance_transport[['car']] <- 5
distance_transport[['bike']] <- 2
distance_transport[['foot']] <- 1

# Initialise data.frame and fill column 'id'
df_building <- as.data.frame(matrix(nrow = nrow(bieleld_buildings), ncol = 0))
df_building[['id']] <- bieleld_buildings$osm_id

# For every feature ...
for (feat in features) {
  # ... and every mean of transportation ...
  for (trans in names(distance_transport)) {
    # ... compute the number of points within the predefined distances ...
    tmp_colnames <- colnames(list_building_feature_distance[[feat]])
    if (length(tmp_colnames)==1) {
      df_building[[paste0("COUNT_", feat, "_", trans)]] <- sapply(
        list_building_feature_distance[[feat]][, tmp_colnames],
        function(x) length(which( x <= distance_transport[[trans]] ))
      )
    } else {
      df_building[[paste0("COUNT_", feat, "_", trans)]] <- apply(
        list_building_feature_distance[[feat]][, tmp_colnames],
        1,
        function(x) length(which( x <= distance_transport[[trans]] ))
      )
    }

    # ... remove obsolete object(s) ...
    rm(tmp_colnames)

    # ... compute the density
    tmp_max_count <- max(df_building[, paste0("COUNT_", feat, "_", trans)], na.rm = TRUE)
    df_building[[paste0("DENSITY_", feat, "_", trans)]] <- sapply(
      df_building[, paste0("COUNT_", feat, "_", trans)],
      function(x) x/tmp_max_count
    )

    # ... remove obsolete object(s) ...
    rm(tmp_max_count)
  }
}

################################################################################
#### Store computed data.frame's in individual SQLite-files
################################################################################

# Load requried packages
library(RSQLite)
library(DBI)
library(R.utils)

# Create new SQLite-file
con <- dbConnect(
  drv = RSQLite::SQLite(),
  "./data/wohnlagenkarte.sqlite"
)

# Write data.frame's to SQLite-file
dbWriteTable(con, "building", bieleld_buildings) # remove geometry!
dbWriteTable(con, "building_line", building_coord_lines)
dbWriteTable(con, "building_coord", building_coord_frame)

# Disconnect from the database
dbDisconnect(con)

# Create new SQLite-file
con <- dbConnect(
  drv = RSQLite::SQLite(),
  "./data/wohnlagenkarte_feature.sqlite"
)
# Write data.frame to SQLite-file
dbWriteTable(con, "building_feature", df_building)

# Disconnect from the database
dbDisconnect(con)

gzip(
  "./data/wohnlagenkarte.sqlite",
  temporary=FALSE,
  skip=TRUE,
  overwrite=FALSE,
  remove=FALSE
)

gzip(
  "./data/wohnlagenkarte_feature.sqlite",
  temporary=FALSE,
  skip=TRUE,
  overwrite=FALSE,
  remove=FALSE
)

################################################################################
#### Clean-up
################################################################################

rm(list=ls(all=TRUE))
gc()
