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

#' A class for Catalogs (which may contain catalogs references or datasets)
#'
#' @description A catalog representation that sublcasses from ThreddsNode
#' 
#' @examples
#'  \donttest{
#'   library(thredds)
#'   top_uri <- 'https://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml'
#'   Top <- thredds::CatalogNode$new(top_uri)
#'   Top$browse()
#'   
#'   #go down in 'MODISA' catalog
#'   L3 <- Top$get_catalogs("MODISA")[["MODISA"]]$get_catalogs()[[1]]
#'   
#'   #see what's available for 2009
#'   catalog2009 <- L3$get_catalogs("2009")[[1]]
#'   
#'   #get catalog for 2009-01-20 
#'   doy <- format(as.Date("2009-01-20"), "%j")
#'   catalog20 <- catalog2009$get_catalogs(doy)[[doy]]
#'   
#'   #get dataset node
#'   chl <- catalog20$get_datasets("A2009020.L3m_DAY_CHL_chlor_a_9km.nc")[[1]]
#'   
#'   #retrieve the relative URL, and add it to the base URL for the service.
#'   #Somewhat awkwardly, the relative URL comes prepended with a path separator, so we 
#'   #use straight up `paste0` to append to the base_uri.
#'   #if(require("ncdf4")){
#'   #  base_uri <- "https://oceandata.sci.gsfc.nasa.gov:443/opendap"
#'   #  uri <- paste0(base_uri, chl$url)
#'   #  NC <- ncdf4::nc_open(uri)
#'   #}
#'  }
#' 
#' @export
CatalogNode <- R6::R6Class("CatalogNode",
  inherit = ThreddsNode,
  public = list(

    #' @description list available services
    #' @param xpath character, the xpath specifications
    #' @param form character, either "list" or "table"
    #' @return list of zero or more character vectors
    list_services = function(xpath = build_xpath("service",
                                                 prefix = self$prefix),
                             form = "list"){
      x <- self$node %>%
        xml2::xml_find_all(xpath) %>%
        sapply( function(x) xml2::xml_attrs(x) , simplify = FALSE)

      if (length(x) == 0) return(list())

      if (tolower(form[1]) =='table'){
        x <- do.call(rbind, x) %>% as.data.frame()
      } else {
        #if ("name" %in% names(x[[1]])) names(x) <- sapply(x, "[[", "name")
        id <- sapply(x, xml_id, USE.NAMES = FALSE)
        if (!all(is.na(id)) && !all(nchar(x) == 0)) names(x) <- id
      }
      x
    },  # list_services

    #' @description list available catalogRefs
    #' @param xpath character, the xpath descriptor
    #' @param form character, either "list" or "table"
    #' @return a list with zero or more character vectors
    list_catalogs = function(xpath = build_xpath(c("dataset", "catalogRef"),
                                                 prefix = self$prefix),
                             form = "list"){
      x <- self$node %>%
        xml2::xml_find_all(xpath) %>%
        sapply( function(x) xml2::xml_attrs(x) , simplify = FALSE)

      if (length(x) == 0) return(list())

      if (tolower(form[1]) =='table'){
        x <- do.call(rbind, x) %>% as.data.frame()
      } else {
        #if ("name" %in% names(x[[1]])) names(x) <- sapply(x, "[[", "name")
        id <- sapply(x, xml_id, USE.NAMES = FALSE)
        if (!all(is.na(id)) && !all(nchar(x) == 0)) names(x) <- id
      }
      x
    }, #list_catalogs

    #' @description list available datasets
    #' @param xpath character, the xpath descriptor
    #' @param form character, either "list" or "table"
    #' @return a list with zero or more character vectors
    list_datasets = function(xpath = build_xpath(c("dataset", "dataset"),
                                                 prefix = self$prefix),
                             form = "list"){
      x <- self$node %>%
        xml2::xml_find_all(xpath) %>%
        sapply( function(x) xml2::xml_attrs(x) , simplify = FALSE)

      xpath_dataset_flat <- build_xpath(c("dataset"),prefix = self$prefix)
      if(length(x) == 0 && xpath != xpath_dataset_flat){
        #we try to look for non-nested datasets
        x <- self$node %>%
          xml2::xml_find_all(xpath_dataset_flat) %>%
          sapply( function(x) xml2::xml_attrs(x), simplify = FALSE)
      }

      if (length(x) == 0) return(list())

      if (tolower(form[1]) =='table'){
        x <- do.call(rbind, x) %>% as.data.frame()
      } else {
        #if ("name" %in% names(x[[1]])) names(x) <- sapply(x, "[[", "name")
        id <- sapply(x, xml_id, USE.NAMES = FALSE)
        if (!all(is.na(id)) && !all(nchar(x) == 0)) names(x) <- id
      }
      x
    }, #list_datasets

    #' @description Retrieve a list one or more of child catalogs
    #' @param index integer index (1,...,nChild), indices or name(s)
    #' @param xpath character xpath representation
    #' @return a list of Catalog class objects, possibly NULL
    get_catalogs = function(index, xpath = build_xpath(c("dataset", "catalogRef"), prefix = self$prefix)){

      catalogRefs <- self$list_catalogs(xpath)

      if (length(catalogRefs) == 0) return(NULL)

      if (!missing(index)) {
        ix <- match(index, names(catalogRefs))
        catalogRefs <- catalogRefs[ix[!is.na(ix)]]
      }

      if (length(catalogRefs) == 0) return(NULL)

      nms <- names(catalogRefs[[1]])
      parent_base <- dirname(self$url)
      if ("href" %in% nms) {
        uri <- sapply(catalogRefs,
                      function(ref) {
                        #gsub("catalog.xml", ref[['href']], self$url, fixed = TRUE)
                        file.path(parent_base, ref[['href']] )
                      } )
      } else if ("urlPath" %in% nms){
        uri <- sapply(catalogRefs,
                      function(ref) {
                        #gsub("catalog.xml", ref[['urlPath']], self$url, fixed = TRUE)
                        file.path(parent_base, ref[['urlPath']] )
                      } )
      } else {
        if (self$verbose){
          warning(paste("catalogRefs lack both 'href' and 'urlPath' elements",
                        "- must have at least one - returning NULL"))
        }
        return(NULL)
      }

      x <- lapply(unname(uri), function(u) CatalogNode$new(u,
                                                   verbose = self$verbose,
                                                   n_tries = self$tries,
                                                   prefix = self$prefix,
                                                   base_url = self$base_url,
                                                   encoding = self$encoding))
      names(x) <- names(catalogRefs)
      x
    }, #get_catalogs

    #' @description Retrieve list one or more dataset children
    #' @param index the integer index (1,...,nChild), indices or name(s)
    #' @param xpath character xpath representation
    #' @return a list of Dataset objects or NULL
    get_datasets = function(index, xpath = build_xpath(c("dataset", "dataset"),
                                                       prefix = self$prefix)){

      datasets <- xml2::xml_find_all(self$node, xpath)

      xpath_dataset_flat <- build_xpath(c("dataset"),prefix = self$prefix)
      if(length(datasets) == 0 && xpath != xpath_dataset_flat) {
        #we try to look for non-nested datasets
        datasets <- xml2::xml_find_all(self$node, xpath_dataset_flat)
      }

      if (length(datasets) == 0) return(NULL)

      dataset_names <- sapply(datasets, xml_id)

      if (!missing(index)) {
        if (inherits(index, 'character')){
          ix <- match(index, dataset_names)
          ix <- ix[!is.na(ix)]
          datasets <- datasets[ix]
          dataset_names <- dataset_names[ix]
        } else {
          datasets <- datasets[index]
          datasets <- dataset_names[index]
        }
      }
      if (length(datasets) == 0) return(NULL)

      x <- lapply(datasets, function(node) DatasetNode$new(node,
                                               verbose = self$verbose,
                                               n_tries = self$tries,
                                               prefix = self$prefix,
                                               base_url = self$base_url,
                                               encoding = self$encoding))
      names(x) <- dataset_names
      x
    }, # get_datasets


    #' @description Retrieve list zero or more dataset child names.  If unnnamed, then
    #'   we substitute "title", "ID", "urlPath", or "href" in that order of availability.
    #' @param index the integer index (1,...,nChild), indices or name(s)
    #' @param xpath character xpath representation
    #' @return character vector of zero or more names
    get_dataset_names = function(xpath = build_xpath(c("dataset", "dataset"),
                                                     prefix = self$prefix)){

      x <- self$list_datasets(xpath = xpath)
      if (length(x) == 0) return(character())
      return(names(x))

    }, # get_dataset_names


    #' @description Retrieve list zero or more catalog child names.  If unnnamed, then
    #'   we substitute "title", "ID", "urlPath" or href" in that order of availability.
    #' @param index the integer index (1,...,nChild), indices or name(s)
    #' @param xpath character xpath representation
    #' @return character vector of zero or more names
    get_catalog_names = function(xpath = build_xpath(c("dataset", "catalogRef"),
                                                     prefix = self$prefix)){

      x <- self$list_catalogs(xpath = xpath)
      if (length(x) == 0) return(character())
      return(names(x))

    }, # get_catalog_names


    #' @description Parse a catalog node
    #' @param x xml_node
    #' @return Catalog class object
    parse_catalog_node = function(x){
      n <- parse_node(x, n_tries = self$tries,
                      verbose = self$verbose, prefix = self$prefix,
                      encoding = self$encoding, base_url = self$base_url)
      n$url <- gsub("catalog.xml", file.path(n$name, "catalog.xml"), self$url)
      return(n)
    }, #parse_catalog_node

    #' @description Parse a dataset node
    #' @param x xml_node
    #' @return Dataset class object
    parse_dataset_node = function(x){
      n <- parse_node(x, n_tries = self$tries,
                      verbose = self$verbose, prefix = self$prefix,
                      encoding = self$encoding, base_url = self$base_url)
      n$url <- gsub("catalog.xml", n$name, self$url)
      return(n)
    }, #parse_dataset_node

    #' @description print method
    #' @param prefix character, to be printed before each line of output (like spaces)
    #' @param ... other arguments for superclass
    print = function(prefix = ""){
       super$print(prefix = prefix)
       if (is_xmlNode(self$node)){
         child_names <- xml_children_names(self$node)
         if ("service" %in% child_names){
           services <- self$list_services()
           if (length(services) > 0){
             x <- sapply(services, "[[", "serviceType")
           } else {
             x = "none"
           }
           cat(prefix, paste0("  services [", length(services), "]: "),
               paste(x, collapse = " "), "\n", sep = "")
         }

         if ("dataset" %in% child_names){
           catalogs <- self$list_catalogs()
           if (length(catalogs) > 0){
             x <- names(catalogs)
             nx <- length(x)
             n <- 3
             if (nx > 10) x = c(x[1:n], "...", x[(nx-n+1):nx])
           } else {
             nx <- 0
             x <- "none"
           }
           cat(prefix, paste0("  catalogRefs [", nx, "]: "),
               paste(x, collapse = " "), "\n", sep = "")

           datasets <- self$list_datasets()
           if (length(datasets)> 0){
             x <- names(datasets)
             nx <- length(x)
             n <- 2
             if (nx > 10) x = c(x[1:n], "...", x[(nx-n+1):nx])
           } else {
             nx <- 0
             x <- "none"
           }
           cat(prefix, paste0("  datasets [", nx, "]: "),
               paste(x, collapse = " "), "\n", sep = "")
        } # has datasets

       } #is_xmlNode
    })
  )
