# PACovid19
This is an interactive look at hospitals in Pennsylvania and their ICU beds available and the number of Covid-19 cases. This was created in R using shapefiles from Pennsylvania Spatial Data Access (https://www.pasda.psu.edu/) and Covid-19 case numbers web-scrpaed from the Pennsylvania Department of Health (https://www.health.pa.gov/topics/disease/coronavirus/Pages/Cases.aspx).  

I haven't been able to get the legend for ICU Beds (the blue dots) to show up on the map as {tmap} doesn't allow legends for symbols in the view mode.  

The app.R file is the main shiny app file, while the pahelper.R file contains a lot of the code to pull/scrape the data, clean it and combine it in the form for the maps. 
