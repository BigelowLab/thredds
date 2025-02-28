#### thredds: THREDDS Crawler for R using xml2 package

[![Build Status](https://github.com/BigelowLab/thredds/actions/workflows/r-cmd-check.yml/badge.svg?branch=master)](https://github.com/BigelowLab/thredds/actions/workflows/r-cmd-check.yml)
[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/thredds)](https://cran.r-project.org/package=thredds)
[![cran checks](https://badges.cranchecks.info/worst/thredds.svg)](https://cran.r-project.org/web/checks/check_results_thredds.html)
[![Github_Status_Badge](https://img.shields.io/badge/Github-0.1--3-blue.svg)](https://github.com/BigelowLab/thredds)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6027224.svg)](https://doi.org/10.5281/zenodo.6027224)

[THREDDS](https://www.unidata.ucar.edu/software/tds/) catalogs
are well described.  This package provides only client-side functionality where the user provides
prior knowledge about how the catalog is organized, as on the server side the provider has some 
latitude in how to design the catalog system.


A user's workflow likely is to fetch a top-level catalog, then drill down to a particular sub-catalog
by hop-skipping through lightweight catalog references.  Often, but not always these
catalogs are organized around date (a year of observation, a month of observation, etc) or
a data source ("MODISA" vs "MODIST"), etc. Catalogs may contain references to other catalogs or 
to datasets (often OPeNDAP resources.)

This package replaces [threddscrawler](https://github.com/BigelowLab/threddscrawler) which is
based upon the [XML](https://CRAN.R-project.org/package=XML). Instead this package
is based upon [xml2](https://CRAN.R-project.org/package=xml2), and uses 
[R6](https://CRAN.R-project.org/package=R6) classes.


#### Requirements

[R6](https://CRAN.R-project.org/package=R6)

[magrittr](https://CRAN.R-project.org/package=magrittr)

[httr](https://CRAN.R-project.org/package=httr)

[xml2](https://CRAN.R-project.org/package=xml2)

#### Installation

It is easy to install with [devtools](https://CRAN.R-project.org/package=devtools)
```R
library(devtools)
install_github("BigelowLab/thredds")
```

#### An example from [OBPG](https://oceancolor.gsfc.nasa.gov/)

Start with this [page](https://oceandata.sci.gsfc.nasa.gov/opendap/) and it's [XML companion](https://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml). We find a top level
catalog with a number of sub-catalogs.

```
library(ncdf4)
library(thredds)
top_uri <- 'https://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml'
Top <- thredds::CatalogNode$new(top_uri, prefix = "thredds")
Top
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: thredds
#   url: https://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml
#   services [3]: OPeNDAP HTTPServer WCS
#   catalogRefs [14]: CZCS MERIS MODISA ... SeaWiFS VIIRS VIIRSJ1
#   datasets [1]: /

Top$browse()
```

We'll drill down into `MODISA` which only contains one sub-catalog, `L3SMI` - 
the gridded level 3 standard mapped image. Knowing that we'll actually chain the
methods to get the contents of the L3SMI catalog, where thinsg get interesting. Note
the get_catalogs *always* returns a list, so you must index into it if you want just one result.

```
L3 <- Top$get_catalogs("MODISA")[["MODISA"]]$get_catalogs()
L3
# $L3SMI
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: thredds
#   url: https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/catalog.xml
#   services [3]: OPeNDAP HTTPServer WCS
#   catalogRefs [22]: 2002 2003 2004 ... 2021 2022 2023
#   datasets [1]: /MODISA/L3SMI
L3[[1]]$browse()
```

Let's drill down into 2009, and see what is available on January 20.

```
catalog2009 <- L3[[1]]$get_catalogs("2009")
# $`2009`
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: thredds
#   url: https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2009/catalog.xml
#   services [3]: OPeNDAP HTTPServer WCS
#   catalogRefs [365]: 0101 0102 0103 ... 1229 1230 1231
#   datasets [1]: /MODISA/L3SMI/2009
```

Hmmm. We have to conver '2009-01-20' to a three digit day of year (or 4 digit mmdd if looking for SST).

```
doy <- format(as.Date("2009-01-20"), "%m%d")
doy
# "0120"
```

Ehem, I suppose I could have thought of that without help.  

```
catalog20 <- catalog2009[['2009']]$get_catalogs(doy)
# $`0120`
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: thredds
#   url: https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2009/0120/catalog.xml
#   services [3]: OPeNDAP HTTPServer WCS
#   catalogRefs [0]: none
#   datasets [100]: AQUA_MODIS.20090120.L3m.DAY.CHL.chlor_a.4km.nc AQUA_MODIS.20090120.L3m.DAY.CHL.chlor_a.9km.nc ... AQUA_MODIS.20090120.L3m.DAY.SST4.sst4.4km.nc AQUA_MODIS.20090120.L3m.DAY.SST4.sst4.9km.nc
```

Let's did out just the 9km chlor_a data for that day.

```
chl <- catalog20[[doy]]$get_datasets("AQUA_MODIS.20090120.L3m.DAY.CHL.chlor_a.4km.nc")
# $AQUA_MODIS.20090120.L3m.DAY.CHL.chlor_a.4km.nc
# DatasetNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: thredds
#   url: /MODISA/L3SMI/2009/0120/AQUA_MODIS.20090120.L3m.DAY.CHL.chlor_a.4km.nc
#   name: AQUA_MODIS.20090120.L3m.DAY.CHL.chlor_a.4km.nc
#   dataSize: 14194791
#   date: 2022-07-25T16:41:08Z
```

Now we need only retrieve the relative URL, and add it to the base URL for the service.
Somewhat awkwardly, the relaive URL comes prepended with a path separator, so we 
use straight up `paste0` to append to the base_uri.

```
base_uri <- "https://oceandata.sci.gsfc.nasa.gov:443/opendap"
uri <- paste0(base_uri, chl[["AQUA_MODIS.20090120.L3m.DAY.CHL.chlor_a.4km.nc"]]$url)
NC <- ncdf4::nc_open(uri)
```

Alternatively, you can provide the base URL to the service when you instantiate the top level catalog.
The base URL will be passed down to it's children.

#### An example from [GoMOFS](https://tidesandcurrents.noaa.gov/ofs/gomofs/gomofs.html)

GOMOFS provides a different THREDDS catalog that has no explicit prefix for the namespace. 
So we use the default 'd1' prefix instead.

Start with the XML companion to this [catalog page](https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/catalog.html).
It isn't super obvious browsing the resource, but it is important to specify the namespace prefix
for searching the thredds genealogy - in this case there isn't any so the default, 'd1', would suffice.
Even though it is the default, we specify it explicitly for clarity. Also, note that this catalog 
hase changed over time, so the example may be out of date.

```
library(ncdf4)
library(thredds)
uri = "https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/catalog.xml"
top = thredds::get_catalog(uri, prefix = 'd1')
top
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: d1
#   url: https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/catalog.xml
#   children: service dataset
#   services [4]: Compound OPENDAP HTTPServer WMS
#   catalogRefs [1]: 
#   datasets [0]: none
#
# top$browse()  
```

A `CatalogNode` may contain zero or more `service` and zero or more `dataset` nodes.  
If there is a `dataset` node, it, it turn, may contain zero of more `catalogRef` nodes or
`dataset` nodes. In the above only `catalogs` are listed implying that there are 
no datasets listed at this level.  Below we retrieve a complete listing of catalog 
names, and then retrieve just one by name. Note that a list of catalogs are 
returned, even if just one is requested. Also, note that the `"name` attribute is an
empty string.  In lieu of `name` we then take the first non-empty instance of 
`title`, `ID`, `urlPath`, and finally `href`.

```
top$get_catalog_names()
# "2020""

cata = top$get_catalogs(index = "2020")
cata
# $`2020`
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: d1
#   url: https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/2020/catalog.xml
#   children: service dataset
#   services [4]: Compound OPENDAP HTTPServer WMS
#   catalogRefs [3]: 09 08 07
#   datasets [0]: none
  
```

Note that this is a Catalog - a pointer to other catalogs and/or datasets. It looks like 
Jcatalogs for July, Aug and Sep of 2020. Let's get September.


```
Months <- cata[["2020"]]$get_catalogs("09")
Months
# $`09`
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: d1
#   url: https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/2020/09/catalog.xml
#   children: service dataset
#   services [4]: Compound OPENDAP HTTPServer WMS
#   catalogRefs [28]: 28 27 26 ... 03 02 01
#   datasets [0]: none
```

So, they appear to be listed by day.  So, let's get the most recent...

```
Recent = Months[["09"]]$get_catalogs("28")
Recent
# $`28`
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: d1
#   url: https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/2020/09/28/catalog.xml
#   children: service dataset
#   services [4]: Compound OPENDAP HTTPServer WMS
#   catalogRefs [0]: none
#   datasets [396]: nos.gomofs.stations.nowcast.20200928.t12z.nc nos.gomofs.stations.nowcast.20200928.t06z.nc ... # nos.gomofs.2ds.f001.20200928.t06z.nc nos.gomofs.2ds.f001.20200928.t00z.nc
```

Note that we are down to a level without any further catalogs, but instead we have 396 datasets.
Datasets hold the relative file specification for the resource it identifies.  Let's retrieve the
dataset for the second item listed.

```
nowcast <- Recent[['28']]$get_datasets('nos.gomofs.stations.nowcast.20200928.t06z.nc')
nowcast
  $nos.gomofs.stations.nowcast.20200928.t06z.nc
  DatasetNode (R6): 
    verbose: FALSE    tries: 3    namespace prefix: d1
    url: NOAA/GOMOFS/MODELS/2020/09/28/nos.gomofs.stations.nowcast.20200928.t06z.nc
    children: dataSize date
    name: nos.gomofs.stations.nowcast.20200928.t06z.nc
    dataSize: 4.871
    date: 2020-09-28T07:25:47Z
```

If we know the URL for the base service, then we append the relative URL to that.

```
base_uri <- 'https://opendap.co-ops.nos.noaa.gov/thredds/dodsC'
nowcast_uri <- file.path(base_uri, nowcast[['nos.gomofs.stations.nowcast.20200928.t06z.nc']]$url)
NC <- ncdf4::nc_open(nowcast_uri)
```


### Note on searching within a prefixed namespace

A given implementation of a THREDDS catalog system may rely upon an [XML namespace](https://en.wikipedia.org/wiki/XML_namespace) with a prefix. We have encountered these: [d1](https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/catalog.xml) and [thredds](https://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml).


```
uri = "https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/catalog.xml"
thredds::get_xml_ns(uri)
# d1    <-> http://www.unidata.ucar.edu/namespaces/thredds/InvCatalog/v1.0
# xlink <-> http://www.w3.org/1999/xlink
```

`xlink` is a standard xml namespace.  Other ones we have encountered include `bes`,
which is part of the THREDDS specification for back end server, and `thredds` which
is used for thredds-centric elements. In general, you can specify
the prefix in a call to \code{build_xpath()} or provide it when you instatiate a
new \code{CatalogNode} object, but the reality is that you have to have some
awareness of how the server is configured.  These crawler tools can't successfully navigate
without some higher level management provided by the user.



