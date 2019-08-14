library(shiny)
library(leaflet)
library(geosphere)
library(dplyr)

shipsData <- read.csv(file = "ships.csv", header = TRUE, sep = ",")
shipsTypes = unique(shipsData["ship_type"])
MIN_LAT <- min(shipsData["LAT"])
MAX_LAT <- max(shipsData["LAT"])
MIN_LON <- min(shipsData["LON"])
MAX_LON <- max(shipsData["LON"])

values <- reactiveValues()

calculateDistance <- function(x_lon, x_lat, y_lon, y_lat) {
  distGeo(c(x_lon, x_lat), c(y_lon, y_lat))
}


ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "shipTypeSelect",
        label = "Ship Type:",
        choices = shipsTypes,
        selected = shipsTypes[1]
      ),
      uiOutput("selectShipName"),
      textOutput("shipDistanceText")
    ),
    mainPanel(
      leafletOutput("map")
    )
  )
)

server <- function(input, output, session) {
  shipsFilteredByType <- reactive({
    filteredShips <- shipsData[shipsData[, "ship_type"] == input$shipTypeSelect,]
    values$shipName <- filteredShips[1, "SHIPNAME"]
    filteredShips
  })
  
  output$selectShipName <- renderUI({
    shipsNames <- unique(shipsFilteredByType()["SHIPNAME"])
    
    selectInput(
      "shipName",
      label = "Ship Name:",
      choices = shipsNames,
      selected = shipsNames[1]
    )
  })
  
  observeEvent(input$shipName, {
    req(input$shipName)
    values$shipName <- input$shipName
  })
  
  
  shipDistance <- reactive({
    req(values$shipName, shipsFilteredByType())
    
    filteredByType <- shipsFilteredByType()
    selectedShipData <- filteredByType[filteredByType[,"SHIPNAME"] == values$shipName,]
    ranks <- order(selectedShipData$DATETIME)
    
    nextLat <- lead(selectedShipData[ranks, "LAT"], n = 1L, default = NA)
    nextLon <- lead(selectedShipData[ranks, "LON"], n = 1L, default = NA)
    
    frameWithNextValues <- cbind(selectedShipData[ranks,], nextLat = nextLat, nextLon = nextLon)
    frameWithoutNA <- frameWithNextValues[0:(nrow(frameWithNextValues)-1),]
    
    distanceCalculation <- mapply(calculateDistance, frameWithoutNA$LON, frameWithoutNA$LAT, frameWithoutNA$nextLon, frameWithoutNA$nextLat)
    
    observationsIndexes <- which(distanceCalculation == max(distanceCalculation))
    print(observationsIndexes)
    print(frameWithoutNA[c(observationsIndexes -1, observationsIndexes, observationsIndexes + 1),])
    lastIndex <- tail(observationsIndexes, n=1)
    cbind(frameWithoutNA[lastIndex,], distance=distanceCalculation[lastIndex])
  })

  output$map <- renderLeaflet({
    #https://stackoverflow.com/questions/37446283/creating-legend-with-circles-leaflet-r
    addLegendCustom <- function(map, colors, labels, sizes, opacity = 0.5){
      colorAdditions <- paste0(colors, "; width:", sizes, "px; height:", sizes, "px")
      labelAdditions <- paste0("<div style='display: inline-block;height: ", sizes, "px;margin-top: 4px;line-height: ", sizes, "px;'>", labels, "</div>")
      
      return(addLegend(map, colors = colorAdditions, labels = labelAdditions, opacity = opacity))
    }
    
    leaflet() %>%
      addTiles() %>%
      fitBounds(MIN_LON, MIN_LAT, MAX_LON, MAX_LAT) %>%
      addLegendCustom(colors = c("orange", "blue"), labels = c("Start", "End"), sizes = c(10, 10))
  })
  
  output$shipDistanceText <- renderText({
    req(shipDistance())
    paste("Ship distance in meters:", format(round(shipDistance()$distance, 2), nsmall = 2), sep=" ") 
  })
  
  observe({
    shipDistanceVector <- shipDistance()

    leafletProxy('map') %>% # use the proxy to save computation
      clearShapes() %>%
      addCircles(lng=c(shipDistanceVector$LON), 
                 lat=c(shipDistanceVector$LAT), 
                 group='circles',
                 weight=1, radius=100, color='orange', 
                 fillColor='orange',
                fillOpacity=0.5, 
                opacity=1) %>%
      addCircles(lng=c(shipDistanceVector$nextLon), 
                 lat=c(shipDistanceVector$nextLat), 
                 group='circles',
                 weight=1, radius=100, color='blue', 
                 fillColor='blue',
                 fillOpacity=0.5, 
                 opacity=1)
      
  })
}

shinyApp(ui = ui, server = server)