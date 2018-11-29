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
               if (xml2::xml_length(catalogRefs) > 0){
                  x <- sapply(catalogRefs,
                     function(x) {
                        atts <- xml2::xmt_atts(x)
                        natts <- names(atts)
                        name <- if ('name' %in% natts) name <- atts[['name']] else ""
                        if (!nzchar(name) && ('title' %in% natts) ) name <- atts[['title']]
                        if (!nzchar(name) && ('ID' %in% natts) ) name <- basename(atts[['ID']])
                        if (!nzchar(name) && ('href' %in% natts) ) name <- dirname(atts[['href']])
                        name
                     })

                  cat(prefix, "  catalogs: ", paste(x, collapse = " "), "\n", sep = "")
               } #has catalogRef
               datasets <- xml_find_all(.self$node, ".//dataset/dataset")
               if (xml2::xml_length(datasets)>0){
                  x <- sapply(datasets,
                     function(x) xmls::xml_attrs(x)[['name']])
                  cat(prefix, "  datasets: ", paste(x, collapse = " "), "\n", sep = "")
               } #has datasets (sub-datasets)
            } #has dataset
         } #is_xmlNode
      })
   )





#' Get a list of CatalogRef Children
#'
#' @family TopCatalog
#' @name TopCatalogRefClass_get_catalogs
#' @return a list of CatalogRefClass, possibly NULL
NULL
TopCatalogRefClass$methods(
    get_catalogs = function(){

    catalogRefs <- xml2::xml_find_all(.self$node, ".//dataset/catalogRef")
    if (xml2::xml_length(catalogRefs) > 0){
        x <- lapply(catalogRefs,
           function(x, uri = NULL, verbose = FALSE) {
              n <- parse_node(x, verbose = verbose)
              n$url <- gsub("catalog.xml", n$href, uri)
              return(n)
           }, uri = .self$url, verbose = .self$verbose_mode )
        names(x) <- sapply(x, "[[", "name")
    } else {
        x <- NULL
    }

      return(x)
   })


#' Get a list of Dataset Children
#'
#' @family TopCatalog
#' @name TopCatalogRefClass_get_datasets
#' @return a list of DatasetRefClass, possibly NULL
NULL
TopCatalogRefClass$methods(
   get_datasets = function(){

    datasets <- xml2::xml_find_all(.self$node, ".//dataset/dataset")
    if (xml2::xml_length(datasets)>0){
        x <- lapply(datasets,
           function(x, uri = NULL, verbose = FALSE) {
              n <- parse_node(x)
              n$url <- gsub("catalog.xml", n$name, uri)
              return(n)
           }, uri = .self$url, verbose = .self$verbose_mode )
        names(x) <- sapply(x, "[[", "name")
    } else {
        x <- NULL
    }
      return(x)
   })

