# Load requried packages
package_lib = "/home/gitpod/R/library"

library(leaflet)
library(RColorBrewer)
library(scales)
library(lattice)
library(dplyr)

function(input, output, session) {

  # Reactive value to store number of times the rating-button has been pressed
  counter_button <- reactiveValues(prev = -1)

  # Reactive value to store the leaflet object (map)
  leaflet_object <- reactiveValues(
    map = leaflet() %>%
      addTiles(
        urlTemplate = "//{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png", # For more options see https://leaflet-extras.github.io/leaflet-providers/preview/
        attribution = '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>, Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>',
        options = providerTileOptions(opacity = 0.8)
      ) %>%
      setView(lng = 8.531990, lat = 52.020615, zoom = 16)
  )

  # Initialise reactive values to hold information of GPS-data of map
  react_coord <- reactiveValues(
    north = 0,
    east = 0,
    south = 0,
    west = 0,
    lat = 0,
    lon = 0,
    values = 0
  )

  # Every time the map has changed (due to zooming or dragging) ...
  # ... fill reactive value
  observe({
    if(!is.null(input$leaflet_map_bounds)) {
      # See https://rstudio.github.io/leaflet/shiny.html for all parameters passed back from leaflet-map
      react_coord$north <- input$leaflet_map_bounds$`north`
      react_coord$east <- input$leaflet_map_bounds$`east`
      react_coord$south <- input$leaflet_map_bounds$`south`
      react_coord$west <- input$leaflet_map_bounds$`west`
      react_coord$lat <- c(
        react_coord$north,
        react_coord$north,
        react_coord$south,
        react_coord$south
      )
      react_coord$lon <- c(
        react_coord$west,
        react_coord$east,
        react_coord$east,
        react_coord$west
      )
      react_coord$values <- cbind(react_coord$lat, react_coord$lon)
    }
  })

  # If the rating-button gets pressed ...
  observeEvent(
    input$button_rating,
    {
      # ... if the zoom level is too low ...
      if (input$leaflet_map_zoom < 16) {
        # ... display an error notification ...
        showNotification(
          "Bitte zoomen Sie weiter in die Karte rein.",
          duration = 5,
          closeButton = TRUE,
          type = "error"
        )
      } else {
        # ... retrieve building data based on GPS-coordinates of current map ...
        building_polygons <- get_building_polygons(
          "./data/wohnlagenkarte.sqlite",
          react_coord$north,
          react_coord$south,
          react_coord$west,
          react_coord$east
        )

        # ... use those coordinates to draw new leaflet map and layer ...
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

        # ... obtain rating of buildings inside the map pane ...
        # ... based on selected criterion and means of transportation ...
        building_rating <- get_rating_building(
          "./data/wohnlagenkarte_feature.sqlite",
          building_polygons@data$id,
          input$feature,
          input$transportation
        )

        # ... create continuous colour palette ...
        pal <- colorNumeric(
          palette = "Blues",
          domain = building_rating$rating
        )

        # ... for each building ...
        for (i in 1:length(building_polygons@lines)) {
          # ... add lines to map to draw the frame of building and ...
          # ... fill the inside with colour based on rating
          lf <- lf %>% addPolylines(
            data = building_polygons@lines[[i]],
            color = "black",
            weight = 2,
            opacity = 1.0,
            fill = TRUE,
            fillColor = pal(building_rating$rating[building_rating$id == building_polygons@data$id[i]][1]),
            fillOpacity = 1.0
          )
        }

        # ... write new leaflet object to reactive value
        leaflet_object$map <- lf
      }
    }
  )

  # Render leaflet object to map
  output$leaflet_map <- renderLeaflet({
    leaflet_object$map
  })

}
