#### thredds: THREDDS Crawler for R using xml2 package

[![Build Status](https://github.com/BigelowLab/thredds/actions/workflows/r-cmd-check.yml/badge.svg?branch=master)](https://github.com/BigelowLab/thredds/actions/workflows/r-cmd-check.yml)
[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/thredds)](https://cran.r-project.org/package=thredds)
[![cran checks](https://badges.cranchecks.info/worst/thredds.svg)](https://cran.r-project.org/web/checks/check_results_thredds.html)
[![Github_Status_Badge](https://img.shields.io/badge/Github-0.1--5-blue.svg)](https://github.com/BigelowLab/thredds)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6027224.svg)](https://doi.org/10.5281/zenodo.6027224)

[THREDDS](https://www.unidata.ucar.edu/software/tds) catalogs
are well described.  This package provides only client-side functionality where the user provides
prior knowledge about how the catalog is organized, as on the server side the provider has some 
latitude in how to design the catalog system.


A user's workflow likely is to fetch a top-level catalog, then drill down to a particular sub-catalog
by hop-skipping through lightweight catalog references.  Often, but not always these
catalogs are organized around date (a year of observation, a month of observation, etc) or
a data source, etc. Catalogs may contain references to other catalogs or 
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

It is easy to install, either from CRAN:

```R
install.packages("remotes")
```

or with [remotes](https://CRAN.R-project.org/package=remotes):

```R
library(remotes)
install_github("BigelowLab/thredds")
```

#### An example from [OBPG](https://psl.noaa.gov/)

Start with this [page](https://psl.noaa.gov/thredds/catalog/Datasets/catalog.html) and it's [XML companion](https://psl.noaa.gov/thredds/catalog/Datasets/catalog.xml). We find a top level
catalog with a number of sub-catalogs.

```R
library(ncdf4)
library(thredds)
top_uri <- 'https://psl.noaa.gov/thredds/catalog/Datasets/catalog.xml'
Top <- thredds::CatalogNode$new(top_uri, prefix = "thredds")
Top
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: d1
#   url: https://psl.noaa.gov/thredds/catalog/Datasets/catalog.xml
#   services [4]: Compound OpenDAP HTTPServer NetcdfSubset
#   catalogRefs [71]: 20thC_ReanV2 20thC_ReanV2c 20thC_ReanV3 ... snowcover udel.airt.precip uninterp_OLR
#   datasets [1]: Datasets

Top$browse()
```

We'll drill down into `godas` sub-catalog, and then the `Derived` sub-catalog to find derived datasets.

```R
cat_name = "godas"
subcat <- Top$get_catalogs(cat_name)[[cat_name]]
dev <- subcat$get_catalogs("Derived")[["Derived"]]
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: d1
#   url: https://psl.noaa.gov/thredds/catalog/Datasets/godas/Derived/catalog.xml
#   services [4]: Compound OpenDAP HTTPServer NetcdfSubset
#   catalogRefs [0]: none
#   datasets [25]: dbss_obil.mon.ltm.1991-2020.nc dbss_obil.mon.ltm.nc ... vflx.mon.ltm.1991-2020.nc vflx.mon.ltm.nc

dev$browse()
```

Let's fetch a dataset and get its NC file.

```R
ds = dev$get_datasets("dbss_obil.mon.ltm.nc")[[1]]
# DatasetNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: d1
#   url: Datasets/godas/Derived/dbss_obil.mon.ltm.nc
#   name: dbss_obil.mon.ltm.nc
#   dataSize: 7.549
#   date: 2022-01-28T20:33:42.909Z
```

Now we need only retrieve the relative URL, and add it to the base URL for the service.
Somewhat awkwardly, the relative URL comes prepended with a path separator, so we 
use straight up `paste0` to append to the `base_uri`.

```R
base_uri = paste0("https://", gsub("^(https?://)?([^/]+).*", "\\2", dev$url), dev$list_services()$odap[["base"]])
uri <- paste0(base_uri, ds$url)
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

```R
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

```R
top$get_catalog_names()
# "2026""

cata = top$get_catalogs(index = "2026")
cata
# $`2026`
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: d1
#   url: https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/2026/catalog.xml
#   services [4]: compound OpenDAP HTTPServer WMS
#   catalogRefs [2]: 09 08
#   datasets [1]: 2026/
  
```

Note that this is a Catalog - a pointer to other catalogs and/or datasets. It looks like 
there are catalogs for few months of 2026. Let's get September.


```R
Months <- cata[["2026"]]$get_catalogs("09")
Months
# $`09`
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: d1
#   url: https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/2026/09/catalog.xml
#   services [4]: compound OpenDAP HTTPServer WMS
#   catalogRefs [4]: 04 03 02 01
#   datasets [1]: 2026/09/
```

Let's take one day of data:

```R
Recent = Months[["09"]]$get_catalogs("04")
Recent
$`04`
# CatalogNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: d1
#   url: https://opendap.co-ops.nos.noaa.gov/thredds/catalog/NOAA/GOMOFS/MODELS/2026/09/04/catalog.xml
#   services [4]: compound OpenDAP HTTPServer WMS
#   catalogRefs [0]: none
#   datasets [396]: gomofs.t12z.20260904.stations.nowcast.nc gomofs.t12z.20260904.stations.forecast.nc ... gomofs.t00z.20260904.2ds.f002.nc gomofs.t00z.20260904.2ds.f001.nc
```

Note that we are down to a level without any further catalogs, but instead we have 396 datasets.
Datasets hold the relative file specification for the resource it identifies.  Let's retrieve the
dataset for the second item listed.

```R
nowcast <- Recent[['04']]$get_datasets('gomofs.t12z.20260904.stations.nowcast.nc')
nowcast
# $gomofs.t12z.20260904.stations.nowcast.nc
# DatasetNode (R6): 
#   verbose: FALSE    tries: 3    namespace prefix: d1
#   url: NOAA/GOMOFS/MODELS/2026/09/04/gomofs.t12z.20260904.stations.nowcast.nc
#   name: gomofs.t12z.20260904.stations.nowcast.nc
#   dataSize: 4.87
#   date: 2026-09-04T13:10:01Z
```

If we know the URL for the base service, then we append the relative URL to that.

```R
base_uri = paste0("https://", gsub("^(https?://)?([^/]+).*", "\\2", Recent[['04']]$url), Recent[['04']]$list_services()$dapService[["base"]])
uri <- paste0(base_uri, nowcast[[1]]$url)
NC <- ncdf4::nc_open(uri)
```


### Note on searching within a prefixed namespace

A given implementation of a THREDDS catalog system may rely upon an [XML namespace](https://en.wikipedia.org/wiki/XML_namespace) with a prefix.

```R
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



