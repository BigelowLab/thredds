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
install_github("bigelowlab/threddscrawler2")
```

#### An example from [GoMOFS](https://tidesandcurrents.noaa.gov/ofs/gomofs/gomofs.html)

```
library(thredds)
```
