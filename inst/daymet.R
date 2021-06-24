# DAYMET https://thredds.daac.ornl.gov/thredds/catalog/ornldaac/1328/catalog.html
#        https://thredds.daac.ornl.gov/thredds/catalog/ornldaac/1328/catalog.xml

library(thredds)

top_uri <- 'https://thredds.daac.ornl.gov/thredds/catalog/ornldaac/1328/catalog.xml'
Top <- CatalogNode$new(top_uri)
CC <- Top$get_catalogs()
year <- names(CC)[length(CC)]
Year <- CC[[year]]
Year$get_dataset_names()
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

ds_names <- Year$get_dataset_names()
ds_name <- ds_names[length(ds_names)]
ds <- Year$get_datasets(ds_name)[[1]]
base_uri <- "https://thredds.daac.ornl.gov/thredds/dodsC"
uri <- file.path(base_uri, ds$url)
NC <- ncdf4::nc_open(uri)
ncdf4::nc_close(NC)
