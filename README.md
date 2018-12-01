#### thredds: THREDDS Crawler for R using xml2 package

[THREDDS](https://www.unidata.ucar.edu/software/thredds/current/tds/TDS.html) catalogs
are well described.  This package provides only client-side functionality. A user's
workflow likely is to fetch a top-level catalog, then drill down to a particular sub-catalog
by hop-skipping through lightweight catalog references.  Often, but not always these
catalogs are organized around date (a year of observation, a month of observation, etc).
Catalogs may contain references to other catalogs or to datasets (typically OPeNDAP resources.)

This package replaces [threddscrawler](https://github.com/BigelowLab/threddscrawler) which is
based upon the [XML](https://CRAN.R-project.org/package=XML). Instead this package
is based upon [xml2](https://CRAN.R-project.org/package=xml2).


#### Requirements

[R >= 3.0](http://cran.r-project.org)

[magrittr](https://CRAN.R-project.org/package=magrittr)

[httr](https://CRAN.R-project.org/package=httr)

[xml2](https://CRAN.R-project.org/package=xml2)

#### Installation

It is easy to install with [devtools](https://CRAN.R-project.org/package=devtools)

```R
library(devtools)
install_github("bigelowlab/thredds")
```

#### An example from [GoMOFS](https://tidesandcurrents.noaa.gov/ofs/gomofs/gomofs.html)


Start with the XML companion to this [catalog page](https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/catalog.html)

```
library(thredds)
library(ncdf4)
library(thredds)
uri = "https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/catalog.xml"
top = get_catalog(uri)
top
# Reference Class: "TopCatalogRef"
#   verbose_mode: FALSE
#   tries: 3
#   url: https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/catalog.xml
#   children: service dataset
#   catalogs[25]: 201811 201810 ... 201612 201611

```

A `TopCatalog` may contain catalogs or datasets under the `dataset` element. In the above only
`catalogs` are listed implying that there are no datasets listed at this level.  Below we
retrieve a complete listing of catalog names, and then retrieve just one by name. Note
that a list of catalogs are returned, even if just one is requested.

```
top$get_catalog_names()
#  [1] "201811" "201810" "201809" "201808" "201807" "201806" "201805" "201804"
#  [9] "201803" "201802" "201801" "201712" "201711" "201710" "201709" "201708"
# [17] "201707" "201706" "201705" "201704" "201703" "201702" "201701" "201612"
# [25] "201611"

cataRef = top$get_catalogs("201801")
cataRef
# $`201801`
# Reference Class: "CatalogRefClass"
#   verbose_mode: FALSE
#   tries: 3
#   url: https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/201801/catalog.xml
#   children:
#   name:201801
#   href:201801/catalog.xml
#   title:201801
#   type:
#   ID:NOAA/GOMOFS/MODELS/201801
```
It's HTML equivalent is [here](https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/201801/catalog.html)

Note that this is a CatalogRef - a pointer to the sub catalog with more content from
January 2018. To retrieve that content we need the get the catalog itself (not just its
reference.)  This catalog contains references to datasets - not to sub-catalogs.

```
nextTop = cataRef[[1]]$get_catalog()
# Reference Class: "TopCatalogRef"
#   verbose_mode: FALSE
#   tries: 3
#   url: https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/201801/catalog.xml
#   children: service dataset
#   datasets [976]: nos.gomofs.stations.nowcast.20180131.t18z.nc nos.gomofs.stations.nowcast.20180131.t12z.nc ...
#      nos.gomofs.2ds.n001.20180101.t06z.nc nos.gomofs.2ds.n001.20180101.t00z.nc
```

An important feature about TopCatalogs is that they provide info on your
[data access options](https://www.unidata.ucar.edu/software/thredds/v4.6/tds/reference/Services.html).
The options can be just one or many.  In this case there are three: [OPeNDAP](https://www.opendap.org/),
HTTPServer and [WMS](https://www.unidata.ucar.edu/software/thredds/current/tds/reference/WMS.html).


```
srv = nextTop$list_services()
srv
# $dapService
#              name       serviceType              base
#      "dapService"         "OPENDAP" "/thredds/dodsC/"
#
# $httpService
#                   name            serviceType                   base
#          "httpService"           "HTTPServer" "/thredds/fileServer/"
#
# $wms
#            name     serviceType            base
#           "wms"           "WMS" "/thredds/wms/"
```

We can retrieve on or more dataset references.  Using the dataset reference URL in combination
with the available data access services we can construct a data access URL.  Below we show
how to craft the URL for OPeNDAP.

```
ds = nextTop$get_datasets("nos.gomofs.stations.nowcast.20180131.t12z.nc")
ds[[1]]
# Reference Class: "DatasetRefClass"
#   verbose_mode: FALSE
#   tries: 3
#   url: https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/201801/nos.gomofs.stations.nowcast.20180131.t12z.nc
#   children: dataSize date
#   datasets: NA
#   dataSize: 4.791
#   date: 2018-01-31T13:36:46Z
#   serviceName:
#   urlPath:

uri = ds[[1]]$get_url(service = srv[['dapService']][['base']])
uri
# http://opendap.co-ops.nos.noaa.gov/thredds/dodsC/NOAA/GOMOFS/MODELS/201801/nos.gomofs.stations.nowcast.20180131.t12z.nc

x <- ncdf4::nc_open(uri)
```

