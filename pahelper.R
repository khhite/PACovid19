library(tidyverse)
library(openxlsx)
library(sf)
library(tmap)
library(rvest)
library(leaflet)

# read in PA counties shape file (https://www.pasda.psu.edu/uci/DataSummary.aspx?dataset=24)
pacounties <- read_sf("PaCounty2020_01.geojson")

# read in hospitals shapefile (http://www.pasda.psu.edu/uci/DataSummary.aspx?dataset=909)
hospitals <- read_sf("DOH_Hospitals201912.geojson")

# only keep columns we need in hospitals df
hospitals <- hospitals %>% select(LONGITUDE, LATITUDE, FACILITY_N, STREET, CITY, ZIP_CODE, COUNTY, geometry)

# Pennsylvania Hospital data can be found in a 2018 hospital report found at 
# https://www.health.pa.gov/topics/HealthStatistics/HealthFacilities/HospitalReports/Pages/hospital-reports.aspx
# This analysis will only use data from general acute care hospitals.
# read in Hospital Report 1-A - utilization data for general acute care hospitals
util_gen <- read.xlsx("PA_Hospital_Report_2018.xlsx", sheet = 1, startRow = 8, cols=c(1,2,3,4,5,12))
# read in Hospital Report 2-A - inpatient hospital unit data for general acute care hospitals
beds_gen <- read.xlsx("PA_Hospital_Report_2018.xlsx", sheet = 3, startRow = 8, cols=c(1,2,3,4,5,9))

# remove last 6 rows of util_gen
util_gen <- slice(util_gen, 1:(n()-6))

### Clean util_gen df ###
# make column names friendlier 
names(util_gen) <- c("County","Facility","LongTermCareUnit","LicensedBeds",
                     "BedsReady","OccupancyRate")
# convert OccupancyRate to int 
util_gen$OccupancyRate <- as.numeric(util_gen$OccupancyRate)


### Clean beds_gen df ###
# make column names friendlier
names(beds_gen) <- c("County","Facility","TypeOfService","LicensedBeds","BedsReady","OccupancyRate")

# convert LicensedBeds, BedsReady, and OccupancyRate to int
cols.converted <- c("LicensedBeds","BedsReady","OccupancyRate")
beds_gen[cols.converted] <- sapply(beds_gen[cols.converted],as.numeric)

ICUservices <- c("INTENSIVE CARE","MIXED ICU / CCU")
ICUbeds <- beds_gen %>% 
  filter(TypeOfService %in% ICUservices & LicensedBeds != 0) %>%
  group_by(County,Facility) %>%
  summarize(ICUBeds = sum(LicensedBeds),
            ICUBedsReady = sum(BedsReady)) %>%
  ungroup()

# combine ICUbeds with util_gen hospital data
beds <- merge(x = util_gen, y = ICUbeds[ , c("Facility", "ICUBeds","ICUBedsReady")], by = "Facility", all.x=TRUE)
# replace NAs with 0
beds[is.na(beds)] = 0

# combine beds data with hospital file
hospitaldata <- merge(x = hospitals, y = beds[ , c("Facility", "LicensedBeds","BedsReady","ICUBeds","ICUBedsReady")], by.x = "FACILITY_N",  by.y="Facility", all.x=TRUE)

# replace all NAs with 0
hospitaldata[is.na(hospitaldata)] = 0

# Web-scrape PA county case data from https://www.health.pa.gov/topics/disease/coronavirus/Pages/Cases.aspx
url <- "https://www.health.pa.gov/topics/disease/coronavirus/Pages/Cases.aspx"

# extract table of data
pacovid <- url %>% 
  xml2::read_html() %>% 
  #html_nodes(xpath='//*[@id="ctl00_PlaceHolderMain_PageContent__ControlWrapper_RichHtmlField"]/div[1]/table') %>%
  html_nodes(xpath='/html/body/form/div/div[2]/div/div[4]/div[5]/div/div/div/div/div[1]/div/div/div[2]/div/div/div/div[2]/div/div[2]/div/div/table') %>%
  html_table()

# extract first item
pacovid <- pacovid[[1]]

# fix column names 
names(pacovid) = c("County","Cases","Deaths")

# remove first row
pacovid <- pacovid [-1,]

# convert cases and deaths to int
cols.converted2 <- c("Cases","Deaths")
pacovid[cols.converted2] <- sapply(pacovid[cols.converted2],as.numeric)

# replace NA with 0
pacovid <- pacovid %>% replace(is.na(.), 0)

# combine this data with pacounties df
# pacounties has county names in upper case 
# convert County to upper to match COUNTY_NAM in pamap dataframe
pacovid$County <- str_to_upper(pacovid$County)

# combine pacovid with pacounties
covidmap <- merge(x = pacounties, y = pacovid, by.x = "COUNTY_NAM",  by.y="County", all.x = TRUE)

# replace NA in Cases and Deaths with 0
covidmap$Cases <- covidmap$Cases %>% replace_na(0)
covidmap$Deaths <- covidmap$Deaths %>% replace_na(0)