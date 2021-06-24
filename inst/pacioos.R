top_uri <- "https://pae-paha.pacioos.hawaii.edu/thredds/satellite.xml"

Top <- thredds::CatalogNode$new(top_uri)

DD <- Top$get_datasets()
dnames <- names(DD)
dname <- dnames[length(dnames)]

D <- DD[[dname]]

base_uri <- "https://pae-paha.pacioos.hawaii.edu/thredds/dodsC"
uri <- file.path(base_uri, D$url)
NC <- ncdf4::nc_open(uri)
ncdf4::nc_close(NC)
