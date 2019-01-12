# Load required package
library(leaflet)

fluidPage(
  # Display a title
  headerPanel(
    "Individuelle Wohnlagenkarte"
  ),
  # Provide drop-down lists for input
  fluidRow(
    fluidRow(
      column(
        width = 3,
        selectizeInput(
          inputId = "feature",
          label = "Waehlen Sie ein Kriterium aus:",
          choices = choices_feature,
          selected = NULL,
          multiple = FALSE,
          width = '100%'
        ),
        offset = 1
      ),
      column(
        width = 3,
        selectizeInput(
          inputId = "transportation",
          label = "Waehlen Sie die Art der Fortbewegung aus:",
          choices = choices_transportation,
          selected = NULL,
          multiple = FALSE,
          width = '100%'
        ),
        offset = 1
      )
    ),
    # Create rating-button
    fluidRow(
      column(
        width = 3,
        actionButton(
          inputId = "button_rating",
          label = "Bewertung erzeugen",
          width = '100%'
        ),
        br(),br(),
        offset = 1
      )
    ),
    # Display the map in (currently) fixed format
    fluidRow(
      column(
        width = 10,
        leafletOutput("leaflet_map", width="800", height="600"),
        offset = 1
      )
    )
  )
)
