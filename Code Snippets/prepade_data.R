# See https://blog.exploratory.io/calculating-distances-between-two-geo-coded-locations-358e65fcafae
get_geo_distance = function(long1, lat1, long2, lat2, units = "miles") {
  loadNamespace("purrr")
  loadNamespace("geosphere")
  longlat1 = purrr::map2(long1, lat1, function(x,y) c(x,y))
  longlat2 = purrr::map2(long2, lat2, function(x,y) c(x,y))
  distance_list = purrr::map2(longlat1, longlat2, function(x,y) geosphere::distHaversine(x, y))
  distance_m = distance_list[[1]]
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

# get_geo_distance(13.43871, 52.47730, 13.57896, 52.45816, units = "km")

##############################################################

library(overpass)

# get all GPS-coordinates of features

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

list_df_features <- list()
list_features_query_result <- list()

# feat <- features[3]
for (feat in features) {
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

  query_result <- overpass::overpass_query(query_txt)
  list_features_query_result[[feat]] <- query_result

  if( class(query_result)[1] == "SpatialLinesDataFrame" ) {
    res <- lapply(
      slot(query_result, "lines"),
      function(x) lapply(slot(x, "Lines"), function(y) as.data.frame(slot(y, "coords")))
    )
    res <- lapply(res, function(x) c(mean(x[[1]]$lon), mean(x[[1]]$lat)))

    list_df_features[[feat]] <- data.frame(
      ID = names(res),
      lon = sapply(res, function(x) x[1]),
      lat = sapply(res, function(x) x[2])
    )
    rm(res)
  } else if ( class(query_result)[1] == "SpatialPointsDataFrame" ) {
    list_df_features[[feat]] <- data.frame(
      ID = query_result@data$id,
      lon = query_result@data$lon,
      lat = query_result@data$lat
    )
  }
  rm(query_txt, query_result)
}

features <- features[features %in% names(list_df_features)]

# Download file 'detmold-regbez-latest-free.shp.zip' from https://download.geofabrik.de/europe/germany/nordrhein-westfalen/detmold-regbez.html
# Use shapefile 'gis_osm_buildings_a_free_1.shp'
bieleld_buildings <- read_sf(dsn = "./data", layer = "gis_osm_buildings_a_free_1")

bielefeld_square <- list()
bielefeld_square[['north']] <- 52.1147
bielefeld_square[['south']] <- 51.9155
bielefeld_square[['west']] <- 8.3778
bielefeld_square[['east']] <- 8.6644

require(tibble)

# Add columns with longitude and latitude of building centres
bieleld_buildings <- add_column(bieleld_buildings, "lon" = sapply(bieleld_buildings$geometry, function(x) mean(st_bbox(x)$xmin, st_bbox(x)$xmax)) )
bieleld_buildings <- add_column(bieleld_buildings, "lat" = sapply(bieleld_buildings$geometry, function(x) mean(st_bbox(x)$ymin,st_bbox(x)$ymax)) )

# Only use those buildings of Regierungsbezirk Detmold which lie within a square around Bielefeld
bieleld_buildings <- bieleld_buildings[
  bieleld_buildings$lon > bielefeld_square$west &
    bieleld_buildings$lon < bielefeld_square$east &
    bieleld_buildings$lat > bielefeld_square$south &
    bieleld_buildings$lat > bielefeld_square$north,
]

# Construct list of distance data.frame's
list_building_feature_distance <- list()
for (feat in features) {
  list_building_feature_distance[[feat]] <- as.data.frame(apply(
    list_df_features[[feat]][, c('lon', 'lat')],
    1,
    function(y)
      apply(
        bieleld_buildings[, c('lon', 'lat')],
        1,
        function(x)
          get_geo_distance(x[1], x[2], y[1], y[2], units = "km")
      )
  ))
}
