library(leaflet)

fluidPage(

  headerPanel(
    "Persona-Wohnlagenkarte"
  ),
  fluidRow(
    fluidRow(
      column(
        width = 4,
        selectizeInput(
          inputId = "persona",
          label = "Waehlen Sie eine Persona aus:",
          choices = c("Student", "Junge Familie", "Rentner"),
          selected = NULL,
          multiple = FALSE,
          width = '100%'
        ),
        offset = 1
      ),
      column(
        width = 4,
        actionButton(
          inputId = "button_rating",
          label = "Bewertung erzeugen",
          width = '100%'
        ),
        offset = 1
      )
    ),
    fluidRow(
      column(
        width = 10,
        # If not using custom CSS, set height of leafletOutput to a number instead of percent
        leafletOutput("leaflet_map", width="800", height="600"),
        offset = 1
      )
    )
  )

)
