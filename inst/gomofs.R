# GOMOFS example

base_uri = 'https://opendap.co-ops.nos.noaa.gov/thredds/dodsC'
uri = "https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/catalog.xml"
top = thredds::get_catalog(uri, prefix = 'd1')
cata = top$get_catalogs(index = "2020")
Months <- cata[["2020"]]$get_catalogs("09")
Recent = Months[["09"]]$get_catalogs("28")
nowcast <- Recent[['28']]$get_datasets('nos.gomofs.stations.nowcast.20200928.t06z.nc')
nowcast_uri <- file.path(base_uri, 
                         nowcast[['nos.gomofs.stations.nowcast.20200928.t06z.nc']]$url)