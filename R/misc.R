#' Determine if a vector of names match the greplargs
#'
#' @export
#' @param x a vector of names
#' @param greplargs NULL, vector or list
#' @return logical vector
grepl_it <- function(x, greplargs = NULL){
   ix <- rep(FALSE, length(x))
   if (is.null(greplargs)) return(!ix)
   if (!is.list(greplargs[[1]])) greplargs <- list(greplargs)

   for (g in greplargs){
         ix <- ix | grepl(g[['pattern']], x, fixed = g[['fixed']])
   }
   ix
}

#' Test if an object inherits from xml2::xml_node
#'
#' @export
#' @param x object to test
#' @param classname character, the class name to test against, by default 'xml_node'
#' @return logical
is_xmlNode <- function(x, classname = 'xml_node'){
   inherits(x, classname)
}

#' Convert xm2::xml_node to character
#'
#' @export
#' @param x xmlNode
#' @return character
xmlString <- function(x){
   gsub("\n","", as.character(x))
}


#' Get the names of children
#' @export
#' @param x xml2::xml_node
#' @param unique_only logical if TRUE remove duplicates
#' @return zero or more child names.  If none an empty character string is returned
xml_children_names <- function(x, unique_only = TRUE){
    nm <- if (is_xmlNode(x)) {
        x %>%
            xml2::xml_children() %>%
            sapply(xml2::xml_name)
    } else {
        ""
    }
    if (unique_only) nm <- unique(nm)
    return(nm)
}


#' Retrieve the namespaces for a resource
#'
#' @export
#' @param uri the URI of the catalog
#' @return the output of \code{\link[xml2]{xml_ns}}
get_xml_ns <- function(uri){

  x <- httr::GET(uri)
  if (httr::status_code(x) == 200){

  } else {
    stop("unable to retrieve url: ", uri)
  }
  x %>%
    httr::content(type = 'text/xml', encoding = 'UTF-8') %>%
    xml2::xml_ns()
}


#' Retrieve a catalog
#'
#' @export
#' @param uri the URI of the catalog
#' @param ... further arguments for parse_node
#' @return ThreddsNodeRefClass or subclass or NULL
get_catalog <- function(uri, ...){

   x <- httr::GET(uri)
   if (httr::status_code(x) == 200){
      node <- parse_node(x, ...)
   } else {
      node <- NULL
   }
   return(node)
}

#' Convert a node to an object inheriting from ThreddsNodeRefClass
#'
#' @export
#' @param node xml2::xml_node or an httr::response object
#' @param url character, optional url if a catalog or direct dataset
#' @param verbose logical, by default FALSE
#' @param encoding character, by default UTF-8
#' @param ... further arguments for instantiation of classes (such as ns = "foo")
#' @return ThreddsNodeRefClass object or subclass
parse_node <- function(node, url = NULL, verbose = FALSE, encoding = 'UTF-8', ...){

   # given an 'dataset' xml2::xml_node determine if the node is a collection or
   # direct (to data) and return the appropriate data type
   parse_dataset <- function(x, verbose = FALSE, ...){
      if ('dataset' %in% xml_children_names(x)){
         r <- DatasetsRefClass$new(x, verbose = verbose, ...)
      } else {
         r <- DatasetRefClass$new(x, verbose = verbose, ...)
      }
      return(r)
   }

   if (inherits(node, 'response')){
      if (httr::status_code(node) == 200){
         if (is.null(url)) url <- node$url
         node <- httr::content(node, type = 'text/xml', encoding = 'UTF-8')
      } else {
         cat("response status ==",httr::status_code(node), "\n")
         cat("response url = ", node$url, "\n")
         print(httr::content(node))
         return(NULL)
      }
   }

   if (!is_xmlNode(node)) stop("assign_node: node must be xml2::xml_node")

   nm <- xml2::xml_name(node)[1]
   n <- switch(nm,
       'catalog' = TopCatalogRefClass$new(node, verbose = verbose, ...),
       'catalogRef' = CatalogRefClass$new(node, verbose = verbose, ...),
       'service' = ServiceRefClass$new(node, verbose = verbose, ...),
       'dataset' = parse_dataset(node, verbose = verbose, ...),
       ThreddsNodeRefClass$new(node, verbose = verbose, ...))

   if (!is.null(url)) n$url <- url

   return(n)
}

#' Build and xpath string, possibly using the user specified namespace
#' declaration.
#'
#' @export
#' @param x character one or more path segments
#' @param prefix character either "./", ".//" or "//" or if NA or NA then ignored
#' @param ns if "" or NA then ignored otherwise it is appended to each segment
#' @return xpath descriptor
build_xpath <- function(x,
  prefix = ".//",
  ns = ""){

  if (!is.na(ns) && nchar(ns) >= 1){
    x <- paste(ns, x, sep = ":")
  }

  x <- paste(x, collapse = "/")

  if (!is.na(ns) || nchar(ns) > 0){
   x <- paste0(prefix, x)
  }

  x
}
