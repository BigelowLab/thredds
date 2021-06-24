# MUR https://podaac-opendap.jpl.nasa.gov/opendap/allData/ghrsst/data/GDS2/L4/GLOB/JPL/MUR/v4.1/
#     https://podaac-opendap.jpl.nasa.gov/opendap/allData/ghrsst/data/GDS2/L4/GLOB/JPL/MUR/v4.1/catalog.xml

library(thredds)

top_uri <- 'https://podaac-opendap.jpl.nasa.gov/opendap/allData/ghrsst/data/GDS2/L4/GLOB/JPL/MUR/v4.1/catalog.xml'
Top <- thredds::CatalogNode$new(top_uri) #, prefix = "thredds")

d271 <- Top$get_catalogs("2020")[[1]]$get_catalogs("271")[[1]]

dd <- d271$get_datasets("20200927090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc")[[1]]

base_uri <- "https://podaac-opendap.jpl.nasa.gov/opendap/hyrax"
uri <- paste0(base_uri, dd$url)
x <- ncdf4::nc_open(uri)
ncdf4::nc_close(x)
