# UI components

ui <- fluidPage(
  titlePanel("Poland Map with Points from CSV"),
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload CSV File", accept = c(".csv"),placeholder = "Choose a CSV file"),
      conditionalPanel(
        condition = "input.tab == 'Map'",
        uiOutput("scientific_search"),
        uiOutput("vernacular_search"),
        uiOutput("sex_selector"),
        uiOutput("kingdom_selector"),
        uiOutput("has_image_sele"),
        uiOutput("filter_images")
      ),
      conditionalPanel(
        condition = "input.tab == 'Map'",
        div(style = "margin-bottom: 15px;", 
          actionButton("apply_filter", "Apply Filters"),
          actionButton("remove_all_filters", "Remove Filters")
        ),
      ),
      conditionalPanel(
        condition = "input.tab == 'Timeline'",
        uiOutput("species_selector")
      )
    ),
    mainPanel(
      tabsetPanel(
        id="tab",
        tabPanel(
          "Map", 
          div(
            id = "map_container",
            style = "position: relative;",
            leafletOutput("map", height = "600px"),
            uiOutput("map_overlay")
          )
        ),
        tabPanel("Timeline", uiOutput("timeline_content"))
      )
    )
  )
)