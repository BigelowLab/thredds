# http://www.unidata.ucar.edu/software/thredds/current/tds/catalog/InvCatalogSpec.html#catalog
# The catalog element is the top-level element. It may contain zero or more
# service elements, followed by zero or more datasetRoot elements, followed by
# zero or more property elements, followed by one or more dataset elements. The
# base is used to resolve any reletive URLsin the catalog such as catalogRefs,
# services, etc. It is usually the URL of the catalog document itself. Optionally
# the catalog may have a display name. The expires element tells clients when
# this catalog should be reread, so they can cache the catalog information. The
# value of the version attribute indicates the version of the InvCatalog
# specification to which the catalog conforms. The version attribute is optional,
# but should be used to document which version of the schema was used.

#' An catalog representation that sublcasses from ThreddsNodeRefClass
#'
#' @family Thredds TopCatalog
#' @include Thredds.R
#' @export
TopCatalogRefClass <- setRefClass("TopCatalogRef",
   contains = 'ThreddsNodeRefClass',
   methods = list(
      show = function(prefix = ""){
         callSuper(prefix = prefix)
         if (is_xmlNode(.self$node)){
            if ("dataset" %in% xml_children_names(.self$node)){
               catalogRefs <- xml2::xml_find_all(.self$node, ".//dataset/catalogRef")
               if (length(catalogRefs) > 0){
                  x <- sapply(catalogRefs,
                     function(x) {
                        atts <- xml2::xml_attrs(x)
                        natts <- names(atts)
                        name <- if ('name' %in% natts) name <- atts[['name']] else ""
                        if (!nzchar(name) && ('title' %in% natts) ) name <- atts[['title']]
                        if (!nzchar(name) && ('ID' %in% natts) ) name <- basename(atts[['ID']])
                        if (!nzchar(name) && ('href' %in% natts) ) name <- dirname(atts[['href']])
                        name
                     })

                  nx = length(x)
                  n = 2
                  if (nx > 10) x = c(x[1:n], "...", x[(nx-n+1):nx])
                  cat(prefix, paste0("  catalogs [", nx, "]: "), paste(x, collapse = " "), "\n", sep = "")
               } #has catalogRef
               datasets <- xml2::xml_find_all(.self$node, ".//dataset/dataset")
               if (length(datasets) > 0){
                  x <- sapply(datasets,
                     function(x) xml2::xml_attrs(x)[['name']])
                  nx = length(x)
                  n = 2
                  if (nx > 10) x = c(x[1:n], "...", x[(nx-n+1):nx])
                  cat(prefix, paste0("  datasets [", nx, "]: "), paste(x, collapse = " "), "\n", sep = "")
               } #has datasets (sub-datasets)
               datasets <- xml2::xml_find_all(.self$node, ".//dataset")
               if (length(datasets) > 0){
                 x <- sapply(datasets,
                             function(x) xml2::xml_attrs(x)[['name']])
                 nx = length(x)
                 n = 2
                 if (nx > 10) x = c(x[1:n], "...", x[(nx-n+1):nx])
                 cat(prefix, paste0("  datasets [", nx, "]: "), paste(x, collapse = " "), "\n", sep = "")
               } #has datasets (sub-datasets)
            } #has dataset
         } #is_xmlNode
      })
   )

#' List the services (if any)
#'
#' @family TopCatalog
#' @name TopCatalogRefClass_list_services
#' @param xpath character xpath representation
#' @return list of zero or more character vectors
NULL
TopCatalogRefClass$methods(
    list_services = function(xpath = ".//service/service"){

        x <- .self$node %>%
            xml2::xml_find_all(xpath) %>%
            sapply( function(x) xml2::xml_attrs(x) , simplify = FALSE)
        names(x) <- sapply(x, "[[", "name")
        x
    })



#' Get a list one or more of CatalogRef Children
#'
#' @family TopCatalog
#' @name TopCatalogRefClass_get_catalogs
#' @param index the integer index (1,...,nChild), indices or name(s)
#' @param xpath character xpath representation
#' @return a list of CatalogRefClass, possibly NULL
NULL
TopCatalogRefClass$methods(
    get_catalogs = function(index, xpath = ".//dataset/catalogRef"){

        ds <- .self$node %>% xml2::xml_find_all(xpath)

        if (length(ds) == 0) return(NULL)

        if (missing(index)) index <- seq_along(ds)

        if (inherits(index, "character")){
            allnames = .self$get_catalog_names()
            dd <- ds[allnames %in% index]
        } else {
            dd <- ds[index]
        }
        x <- lapply(dd, .self$parse_catalog_node)
        names(x) <- sapply(x, "[[", "name")
        x
   })


#' Get list one or more dataset children
#' @family TopCatalog
#' @name TopCatalogRefClass_get_datasets
#' @param index the integer index (1,...,nChild), indices or name(s)
#' @param xpath character xpath representation
#' @return a list of DatasetRefClass or NULL
NULL
TopCatalogRefClass$methods(
    get_datasets = function(index, xpath = ".//dataset/dataset"){

        ds <- .self$node %>% xml2::xml_find_all(xpath)

        if (length(ds) == 0) return(NULL)

        if (missing(index)) index <- seq_along(ds)

        if (inherits(index, "character")){
            dd <- ds[sapply(ds, function(x) xml2::xml_attrs(x)[['name']]) %in% index]
        } else {
            dd <- ds[index]
        }
        x <- lapply(dd, .self$parse_dataset_node)
        names(x) <- sapply(x, "[[", "name")
        x
})


#' Get a list of CalatogRef child names
#'
#' Not all catalog refs have a name attribute.  When absent we try to substitute
#'  title, ID and finally href in that order.
#' @family TopCatalog
#' @name TopCatalogRefClass_get_catalog_names
#' @param xpath character xpath representation
#' @return character vector
NULL
TopCatalogRefClass$methods(
   get_catalog_names = function(xpath = ".//dataset/catalogRef"){

    .self$node %>%
        xml2::xml_find_all(xpath) %>%
        sapply(function(x) {
                        atts <- xml2::xml_attrs(x)
                        natts <- names(atts)
                        name <- if ('name' %in% natts) name <- atts[['name']] else ""
                        if (!nzchar(name) && ('title' %in% natts) ) name <- atts[['title']]
                        if (!nzchar(name) && ('ID' %in% natts) ) name <- basename(atts[['ID']])
                        if (!nzchar(name) && ('href' %in% natts) ) name <- dirname(atts[['href']])
                        name
                     })
})


#' Get a list of Dataset child names
#'
#' @family TopCatalog
#' @name TopCatalogRefClass_get_dataset_names
#' @param xpath character xpath representation
#' @return character vector
NULL
TopCatalogRefClass$methods(
   get_dataset_names = function(xpath = ".//dataset/dataset"){

    .self$node %>%
        xml2::xml_find_all(xpath) %>%
        sapply(function(x) xml2::xml_attrs(x)[['name']])
})


#' Parse a catlog node
#'
#' @family TopCatalog
#' @name TopCatalogRefClass_parse_dataset
#' @param x xml_node
#' @return CatalogRefNode
NULL
TopCatalogRefClass$methods(
    parse_catalog_node = function(x){
        n <- parse_node(x)
        n$url <- gsub("catalog.xml", file.path(n$name, "catalog.xml"), .self$url)
        n$verbose_mode <- .self$verbose_mode
        return(n)
    })


#' Parse a dataset node
#'
#' @family TopCatalog
#' @name TopCatalogRefClass_parse_dataset
#' @param x xml_node
#' @return DatasetRefNode
NULL
TopCatalogRefClass$methods(
    parse_dataset_node = function(x){
        n <- parse_node(x)
        n$url <- gsub("catalog.xml", n$name, .self$url)
        n$verbose_mode <- .self$verbose_mode
        return(n)
    })
