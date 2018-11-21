library(leaflet)
library(RColorBrewer)
library(scales)
library(lattice)
library(dplyr)
library(overpass)

function(input, output, session) {

  # Create the map
  output$leaflet_map <- renderLeaflet({
    leaflet() %>%
      addTiles(
        urlTemplate = "//{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png", # For more options see https://leaflet-extras.github.io/leaflet-providers/preview/
        attribution = '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>, Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>',
        options = providerTileOptions(opacity = 0.8)
      ) %>%
      setView(lng = 8.531990, lat = 52.020615, zoom = 16)
  })

  react_coord <- reactiveValues(north = 0, east = 0, south = 0, west = 0, lat = 0, lon = 0, values = 0)

  map_bound_coord <- observe({
    if(!is.null(input$leaflet_map_bounds)) {
      print(c(input$leaflet_map_bounds$`north`, input$leaflet_map_bounds$`east`, input$leaflet_map_bounds$`south`, input$leaflet_map_bounds$`west`))
      react_coord$north <- input$leaflet_map_bounds$`north`
      react_coord$east <- input$leaflet_map_bounds$`east`
      react_coord$south <- input$leaflet_map_bounds$`south`
      react_coord$west <- input$leaflet_map_bounds$`west`
      react_coord$lat <- c(react_coord$north, react_coord$north, react_coord$south, react_coord$south)
      react_coord$lon <- c(react_coord$west, react_coord$east, react_coord$east, react_coord$west)
      react_coord$values <- cbind(react_coord$lat, react_coord$lon)
      print(input$leaflet_map_zoom)
    }
  })

  counter_button <- reactiveValues(prev = 0)

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
      }
    }
  )

}
