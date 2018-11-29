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
   
#' Test if an object inherits from XML::XMLAbstractNode
#'
#' @export
#' @param x object to test
#' @param classname character, the class name to test against, by default 'XMLAbstractNode'
#' @return logical
is_xmlNode <- function(x, classname = 'XMLAbstractNode'){
   inherits(x, classname)
}

#' Convert XML::xmlNode to character
#' 
#' @export
#' @param x xmlNode
#' @return character
xmlString <- function(x){
   gsub("\n","", XML::toString.XMLNode(x))
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
#' @param node XML::xmlNode or an httr::response object
#' @param url character, optional url if a catalog or direct dataset
#' @param verbose logical, by default FALSE
#' @param encoding character, by default UTF-8
#' @return ThreddsNodeRefClass object or subclass
parse_node <- function(node, url = NULL, verbose = FALSE, encoding = 'UTF-8'){

   # given an 'dataset' XML::xmlNode determine if the node is a collection or
   # direct (to data) and return the appropriate data type
   parse_dataset <- function(x, verbose = FALSE){
      if ('dataset' %in% names(XML::xmlChildren(x))){ # was 'access'
         r <- DatasetRefClass$new(x, verbose = verbose)
      } else {
         r <- DatasetsRefClass$new(x, verbose = verbose)
      }
      return(r)
   }
   
   if (inherits(node, 'response')){
      if (httr::status_code(node) == 200){
         if (is.null(url)) url <- node$url
         cnt <- httr::content(node, type = 'text/xml', encoding = 'UTF-8')
         node <- XML::xmlRoot(XML::xmlTreeParse(cnt))
      } else {
         cat("response status ==",httr::status_code(node), "\n")
         cat("response url = ", node$url, "\n")
         print(httr::content(node))
         return(NULL)
      }
   }

   if (!is_xmlNode(node)) stop("assign_node: node must be XML::xmlNode")
   
   nm <- XML::xmlName(node)[1]
   n <- switch(nm,
       'catalog' = TopCatalogRefClass$new(node, verbose = verbose),
       'catalogRef' = CatalogRefClass$new(node, verbose = verbose),
       'service' = ServiceRefClassr$new(node, verbose = verbose),
       'dataset' = parse_dataset(node, verbose = verbose),
       ThreddsNodeRefClass$new(node, verbose = verbose))

   if (!is.null(url)) n$url <- url

   return(n)
}

