library(leaflet)
library(RColorBrewer)
library(scales)
library(lattice)
library(dplyr)
library(overpass) # See https://github.com/hrbrmstr/overpass

function(input, output, session) {

  ## Interactive Map ###########################################

  # Create the map
  output$leaflet_map <- renderLeaflet({
    leaflet_object$map
  })

  react_coord <- reactiveValues(north = 0, east = 0, south = 0, west = 0, lat = 0, lon = 0, values = 0)

  map_bound_coord <- observe({
    if(!is.null(input$leaflet_map_bounds)) {
      react_coord$north <- input$leaflet_map_bounds$`north`
      react_coord$east <- input$leaflet_map_bounds$`east`
      react_coord$south <- input$leaflet_map_bounds$`south`
      react_coord$west <- input$leaflet_map_bounds$`west`
      react_coord$lat <- c(react_coord$north, react_coord$north, react_coord$south, react_coord$south)
      react_coord$lon <- c(react_coord$west, react_coord$east, react_coord$east, react_coord$west)
      react_coord$values <- cbind(react_coord$lat, react_coord$lon)
    }
  })

  counter_button <- reactiveValues(prev = -1)
  leaflet_object <- reactiveValues(
    map = leaflet() %>%
      addTiles(
        urlTemplate = "//{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png", # For more options see https://leaflet-extras.github.io/leaflet-providers/preview/
        attribution = '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>, Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>',
        options = providerTileOptions(opacity = 0.8)
      ) %>%
      setView(lng = 8.531990, lat = 52.020615, zoom = 16)
  )

  observeEvent(
    input$button_rating,
    {
      if (input$leaflet_map_zoom < 17) {
        showNotification(
          "Bitte zoomen Sie weiter in die Karte rein.",
          duration = 5,
          closeButton = TRUE,
          type = "error"
        )
      } else {
        query_txt <- paste0(
          '[out:xml][timeout:25];
          (
          node["building"](', react_coord$south, ',', react_coord$west, ',', react_coord$north, ',', react_coord$east, ');
          way["building"](', react_coord$south, ',', react_coord$west, ',', react_coord$north, ',', react_coord$east, ');
          relation["building"](', react_coord$south, ',', react_coord$west, ',', react_coord$north, ',', react_coord$east, ');
          );
          out body;
          >;
          out skel qt;'
        )

        building_polygons <- overpass::overpass_query(query_txt)

        lf <- leaflet(data = building_polygons) %>%
          addTiles(
            urlTemplate = "//{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png", # For more options see https://leaflet-extras.github.io/leaflet-providers/preview/
            attribution = '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>, Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>',
            options = providerTileOptions(opacity = 0.8)
          ) %>%
          setView(
            lng = input$leaflet_map_center$`lng`,
            lat = input$leaflet_map_center$`lat`,
            zoom = input$leaflet_map_zoom
          )

        for (i in 1:length(building_polygons@lines)) {
          lf <- lf %>% addPolylines(data=building_polygons@lines[[i]], color = "black", weight = 2, opacity = 1.0,
                                    fill = TRUE, fillColor = "white", fillOpacity = 1.0)
        }
        leaflet_object$map <- lf

      }
    }
  )

}
