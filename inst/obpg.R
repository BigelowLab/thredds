# OBPG example

library(thredds)

top_uri <- 'https://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml'
Top <- thredds::CatalogNode$new(top_uri) #, prefix = "thredds")

L3 <- Top$get_catalogs("MODISA")[["MODISA"]]$get_catalogs()
catalog2009 <- L3[[1]]$get_catalogs("2009")
catalog20 <- catalog2009[['2009']]$get_catalogs("020")

chl <- catalog20[['020']]$get_datasets("A2009020.L3m_DAY_CHL_chlor_a_9km.nc")

base_uri <- "https://oceandata.sci.gsfc.nasa.gov:443/opendap"
uri <- paste0(base_uri, chl[["A2009020.L3m_DAY_CHL_chlor_a_9km.nc"]]$url)

