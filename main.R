options(shiny.maxRequestSize = 100*1024^2)

# Load required librariess
library(shiny)
library(leaflet)
library(readr)
library(dplyr)
library(lubridate)
library(plotly)

input_file <- "data/occurence.csv"
output_file <- "data/poland_observations_2.csv"


if (!file.exists(output_file)) {
  process_chunk <- function(chunk, pos) {
    chunk <- chunk[
      chunk$country == 'Poland' | chunk$country == 'Venezuela', ]
    return(chunk)
  }
  filtered_data <- read_csv_chunked(
    file = input_file,
    callback = DataFrameCallback$new(process_chunk),
    chunk_size = 10000
  )
  write_csv(filtered_data, output_file)
  message("Preprocessing completed!")
} else {
  message("Preprocessed file already exists.")
}


# Define UI
ui <- fluidPage(
  titlePanel("Poland Map with Points from CSV"),
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload CSV File", accept = c(".csv"),placeholder = "Choose a CSV file"),
      conditionalPanel(
        condition = "input.tab == 'Map'",
        textInput("scientific_search", "Search by Scientific Name", placeholder = "Enter scientific name"),
        textInput("vernacular_search", "Search by Vernacular Name", placeholder = "Enter vernacular name"),
        uiOutput("sex_selector"),
        uiOutput("kingdom_selector")
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


# Server
server <- function(input, output, session) {
  # Reactive expression to read uploaded file
  data <- reactive({
    req(input$file)
    df <- read_csv(input$file$datapath, n_max=200000)
    validate(
      need(all(c(
        "latitudeDecimal", 
        "longitudeDecimal",
        "eventDate",
        "eventTime",
        "vernacularName",
        "scientificName"
      ) %in% names(df)), 
         "CSV must have
          'latitudeDecimal'
          'longitudeDecimal',
          'eventDate',
          'eventTime'',
          'vernacularName',
          'scientificName' columns."
      )
    )
    df <- df %>%
      mutate(eventTime = ifelse(is.na(eventTime), "00:00:00", eventTime)) %>%
      mutate(event_datetime = ymd_hms(paste(eventDate, eventTime), quiet = TRUE)) %>% 
      filter(!is.na(event_datetime))
    df
  })
  
  output$kingdom_selector <- renderUI ({
    req(data())
    selectInput("kingdom", "Search by kingdom",
                choices = c("", unique(data()$kingdom)),
                selected = NULL,
                multiple = FALSE)
  })
  
  output$sex_selector <- renderUI({
    req(data())
    selectInput("sex", "Search by sex",
                choices = c("", unique(data()$sex)),
                selected = NULL,
                multiple = FALSE)
  })
  
  output$species_selector <- renderUI({
    req(data())
    selectInput("selected_species", "Select Scientific Name:",
                choices = unique(data()$scientificName),
                selected = unique(data()$scientificName)[1],
                multiple = TRUE)
  })
  
  output$map_overlay <- renderUI({
    if (is.null(filtered_data())) {
      # Show overlay if data is not yet loaded
      div(
        "Please upload a file to view the map.",
        style = "
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(255, 255, 255, 0.8); /* Semi-transparent white */
        color: #333; /* Text color */
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 1000;
        font-size: 18px;
        font-weight: bold;
      "
      )
    } else {
      # No overlay when data is available
      NULL
    }
  })
  
  output$timeline_content <- renderUI({
    if (is.null(filtered_data())) {
      div(
        h3("Please upload a file view the timeline"),
        style = "text-align: center; color: gray; margin-top:8%;"
      )
    } else {
      plotlyOutput("timeline_plot")
    }
  })
  
  # Render the timeline plot
  output$timeline_plot <- renderPlotly({
    req(data())
    selected_data <- data() %>%
      filter(scientificName %in% input$selected_species) %>%
      arrange(event_datetime)
    plot_ly(selected_data, x = ~event_datetime, y = ~scientificName,
            type = 'scatter', mode = 'markers',
            marker = list(size = 15, color = 'red')) %>%
      layout(
        title = "Observation Timeline",
        xaxis = list(title = "Date and Time"),
        yaxis = list(title = "Species"),
        hovermode = "closest"
      )
  })
  
  filtered_data <- reactiveVal(NULL)
  
  observeEvent(data(), {
    filtered_data(data())  # By default, set filtered data to all data
  })
  
  observeEvent(input$apply_filter, {
    req(data())
    df <- data()
    if (input$scientific_search != "") {
      df <- df %>% filter(grepl(input$scientific_search, scientificName, ignore.case = TRUE))
    }
    if (input$vernacular_search != "") {
      df <- df %>% filter(grepl(input$vernacular_search, vernacularName, ignore.case = TRUE))
    }
    if (!is.null(input$sex) && input$sex != "") {
      df <- df[df$sex == input$sex, ]
    }
    if (!is.null(input$kingdom) && input$kingdom != "") {
      if (input$kingdom == "NA") {
        df <- df[is.na(df$kingdom), ]
      } else {
        df <- df[df$kingdom == input$kingdom, ] 
      }
    }
    filtered_data(df)
  })
  
  observeEvent(input$remove_all_filters, {
    req(data())
    filtered_data(data())
    updateTextInput(session, "scientific_search", value = "")
    updateTextInput(session, "vernacular_search", value = "")
    updateSelectInput(session, "sex", selected = "")
    updateSelectInput(session, "kingdom", selected = "")
  })
  
  # Render Leaflet map
  output$map <- renderLeaflet({
    leaflet() %>% 
      addTiles() %>%  # Add default OpenStreetMap tiles
      setView(lng = 19.1451, lat = 51.9194, zoom = 6)  # Center on Poland
  })
  
  # Add points to the map when data is uploaded
  observe({
    req(filtered_data())  # Ensure data is loaded
    leafletProxy("map", data = filtered_data()) %>% 
      clearMarkers() %>%  # Clear previous markers
      addCircleMarkers(
        ~longitudeDecimal, ~latitudeDecimal,
        popup = ~paste(
            "<b>ID:</b>",
            id, 
            "<br><b>Scientific name:</b>", 
            scientificName,
            "<br><b>Vernacular name:</b>", 
            vernacularName,
            "<br><b>Sex: </b>",
            sex,
            "<br><b>Kingdom: </b>",
            kingdom
        ),
        radius = 6,
        color = "blue",
        fillOpacity = 0.7
      )
  })
}

# Run the application
shinyApp(ui, server)
