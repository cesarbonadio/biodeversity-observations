options(shiny.maxRequestSize = 100*1024^2)

# Load required libraries
library(shiny)
library(leaflet)
library(readr)
library(dplyr)
library(lubridate)
library(plotly)

source("ui.R")
source("server.R")

input_file <- "data/occurence.csv"
input_file_multimedia <- "data/multimedia.csv"
output_file <- "data/poland_observations.csv"

if (!file.exists(output_file)) {
  process_chunk <- function(chunk, pos) {
    chunk <- chunk[
      chunk$country == 'Poland', ]
    return(chunk)
  }
  filtered_data <- read_csv_chunked(
    file = input_file,
    callback = DataFrameCallback$new(process_chunk),
    chunk_size = 10000
  )
  multimedia_data <- read_csv(input_file_multimedia, col_types = cols(
    CoreId = col_character(),
    accessURI = col_character()
  ))
  merged_data <- filtered_data %>% left_join(multimedia_data, by = c("id" = "CoreId"))
  write_csv(merged_data, output_file)
  message("Preprocessing completed!")
} else {
  message("Preprocessed file already exists.")
}

# Run the application
shinyApp(ui, server)