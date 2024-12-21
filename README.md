# Poland Species Observation Viewer

Welcome to the **Poland Species Observation Viewer**, a Shiny web application designed to visualize species observation data on a map and a timeline. This app allows you to filter observations by various attributes such as scientific name, vernacular name, sex, and kingdom. It also supports selecting and processing specific countries before launching the app.

[You can download the initial data here](https://drive.google.com/file/d/1l1ymMg-K_xLriFv1b8MgddH851d6n2sU/view?usp=sharing)

---

## Features

- **Dynamic Data Loading**: The app checks for the existence of the file `data/poland_observations.csv`:
  - If it exists, the preprocessed data is loaded directly into the app.
  - If it does not exist, the app reads the file `data/occurence.csv`, filters observations for Poland, and creates the `data/poland_observations.csv` file.
- **Interactive Map**: Displays observations as markers on a map with filters for species attributes.
- **Timeline Visualization**: Plots a timeline of species observations.
- **Dynamic Filters**:
  - Search by scientific or vernacular name.
  - Filter by sex or kingdom (including handling `NA` values explicitly).
  - Clear all filters dynamically.
- **Preprocessing for Large Datasets**: Allows chunked processing of large files during the initial setup.

---

## Getting Started

### Prerequisites

- Install R (>= 4.0.0)
- Install the following R packages:
  ```R
  install.packages(c("shiny", "leaflet", "readr", "dplyr", "plotly"))
  ```

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd <repository-folder>
   ```

2. Ensure the required directory structure exists:
   ```bash
   mkdir -p data
   ```

3. Place the `occurence.csv` file in the `data` folder (if not already provided).

---

## Running the App

1. Launch the app using R:
   ```R
   library(shiny)
   runApp('path/to/main/script.R')
   ```

2. The app will perform the following checks:
   - **Check for `data/poland_observations.csv`**:
     - If the file exists, it will be loaded.
     - If the file does not exist, the app will:
       1. Process the `data/occurence.csv` file.
       2. Filter for observations in Poland (or user-selected countries).
       3. Generate the `data/poland_observations.csv` file.
       4. Display a status bar during processing.

---

## App Overview

### Map Tab
- Displays an interactive map centered on Poland.
- Filters:
  - Scientific Name
  - Vernacular Name
  - Sex
  - Kingdom
- **Markers**: Click on any marker to view observation details.

### Timeline Tab
- Displays a timeline of species observations.
- Dynamically updates based on applied filters.
- If no data is loaded, a message prompts the user to upload a file.

---

## File Structure

```
├── app.R                 # Main application script
├── data/
│   ├── occurence.csv     # Input file (required for first run)
│   └── poland_observations.csv  # Preprocessed file (auto-generated)
├── README.md             # Documentation
```

---

## Usage Notes

- **Handling Large Files**: The app uses chunked processing for large input files, ensuring memory efficiency.
- **Dynamic Dropdowns**:
  - Filters like "sex" and "kingdom" do not pre-select a value by default.
  - Selecting "NA" in kingdom explicitly filters missing values.
- **Reset Filters**: Use the "Clear Filters" button to remove all applied filters without affecting the UI.

## Contact

For questions or feedback, contact Cesar Bonadio at cesarbonadio123@gmail.com

---

Happy Observing! 🌍
