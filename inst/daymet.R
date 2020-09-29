# DAYMET https://thredds.daac.ornl.gov/thredds/catalog/ornldaac/1328/catalog.html
#        https://thredds.daac.ornl.gov/thredds/catalog/ornldaac/1328/catalog.xml

top_uri <- 'https://thredds.daac.ornl.gov/thredds/catalog/ornldaac/1328/catalog.xml'
Top <- thredds::CatalogNode$new(top_uri)
Y2019 <- Top$get_catalogs("2019")[[1]]
Y2019$get_dataset_names()
# [1] "Daymet v3 daylength for hawaii (2019)"                     "Daymet v3 daylength for na (2019)"                        
# [3] "Daymet v3 daylength for puertorico (2019)"                 "Daymet v3 precipitation for hawaii (2019)"                
# [5] "Daymet v3 precipitation for na (2019)"                     "Daymet v3 precipitation for puertorico (2019)"            
# [7] "Daymet v3 shortwave radiation for hawaii (2019)"           "Daymet v3 shortwave radiation for na (2019)"              
# [9] "Daymet v3 shortwave radiation for puertorico (2019)"       "Daymet v3 snow-water equivalent for hawaii (2019)"        
# [11] "Daymet v3 snow-water equivalent for na (2019)"             "Daymet v3 snow-water equivalent for puertorico (2019)"    
# [13] "Daymet v3 daily maximum temperature for hawaii (2019)"     "Daymet v3 daily maximum temperature for na (2019)"        
# [15] "Daymet v3 daily maximum temperature for puertorico (2019)" "Daymet v3 daily minimum temperature for hawaii (2019)"    
# [17] "Daymet v3 daily minimum temperature for na (2019)"         "Daymet v3 daily minimum temperature for puertorico (2019)"
# [19] "Daymet v3 vapor pressure for hawaii (2019)"                "Daymet v3 vapor pressure for na (2019)"                   
# [21] "Daymet v3 vapor pressure for puertorico (2019)"      

precip <- Y2019$get_datasets("Daymet v3 precipitation for na (2019)")[[1]]
base_uri <- "https://thredds.daac.ornl.gov/thredds/dodsC"
uri <- file.path(base_uri, precip$url)
NC <- ncdf4::nc_open(uri)
ncdf4::nc_close()