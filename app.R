#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tmap)

source("pahelper.R")


ui <- fluidPage(
  "This map shows the number of Covid-19 cases in PA and the number of ICU Beds Ready at hospitals throughout the state.
  ICU beds ready are indicated by size of blue dots, which indicate hospital locations.",
  br(),
  "You can click on the dot representing hospitals and get hospital information such as Licensed Beds, Beds Ready, ICU Beds, and ICU Beds Ready.",
  br(),
  "Clicking on the county will give you number of cases.",br(),
  tmapOutput("map"),
  "Data from PA Department of Health. Shapefiles from Pennsylvania Spatial Data Access."
)

server <- function(input, output, session) {
  
  output$map = renderTmap({
    # tmap_mode("view")
    tm_shape(covidmap) +
      tm_polygons("Cases", id="COUNTY_NAM") +
      tm_text("COUNTY_NAM", col = "black", size = .5) +
      # add hospital data
      tm_shape(hospitaldata) +
      tm_symbols(size = "ICUBedsReady", scale = 2, alpha = 0.5, 
                 col = "navyblue", id="FACILITY_N", 
                 legend.format = list(text.align="right", text.to.columns = TRUE),
                 popup.vars = c("FACILITY_N","LicensedBeds","BedsReady","ICUBeds","ICUBedsReady")) +
      tm_layout(frame = FALSE, 
                legend.title.size = 1,
                title = "Pennsylvania ICU Beds Available and Covid Cases",
                inner.margins = c(0,0,0.1,0.1))
    
  })
}


shinyApp(ui, server)


