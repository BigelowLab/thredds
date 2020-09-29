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

#' Retrieve an ID value for a node from it's attributes.
#'
#' @export
#' @param x xml node or a named character vector as per \code{xml_attrs}
#' @param atts character, ordered vector of attribute names to use as an ID value
#'    As the list is stepped through if an attribute is missing or empty character
#'    then advance to the next, otherwise return that value
#' @return character identifier, possibly an empty character (\code{character()})
xml_id <- function(x,
                   atts = c("name", "title", "ID", "urlPath", "href")){
   
   ret <- character()
   if (is.character(x)){
      a <- x
   } else {
      a <- xml2::xml_attrs(x)
   }
   
   if (length(a) == 0) return(ret)
   
   natts <- names(a)
   if (is.null(natts)){
      warning("attributes must be a named character vector")
      return(ret)
   }
   
   for (att in atts){
      if (att %in% natts && (nchar(a[[att]]) > 0)) {
         ret <- a[[att]]
         break
      }
   }
   return(ret)
}

#' Get the names of children
#' @export
#' @param x xml2::xml_node
#' @param unique_only logical if TRUE remove duplicates
#' @return zero or more child names.
xml_children_names <- function(x, unique_only = TRUE){
    nm <- if (is_xmlNode(x)) {
        x %>%
            xml2::xml_children() %>%
            sapply(xml2::xml_name)
    } else {
        character()
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

#' Convert a node to an object inheriting from ThreddsNode
#'
#' @export
#' @param node xml2::xml_node or an httr::response object
#' @param url character, optional url if a catalog or direct dataset
#' @param verbose logical, by default FALSE
#' @param encoding character, by default UTF-8
#' @param ... further arguments for instantiation of classes (such as ns = "foo")
#' @return ThreddsNode class object or subclass
parse_node <- function(node, url = NULL, verbose = FALSE, encoding = 'UTF-8', ...){

   if (inherits(node, 'response')){
      if (httr::status_code(node) == 200){
         if (is.null(url)) url <- node$url
         node <- httr::content(node, type = 'text/xml', encoding = encoding)
      } else {
         cat("response status ==",httr::status_code(node), "\n")
         cat("response url = ", node$url, "\n")
         print(httr::content(node, encoding = encoding))
         return(NULL)
      }
   }

   if (!is_xmlNode(node)) stop("assign_node: node must be xml2::xml_node")

   nm <- xml2::xml_name(node)[1]
   n <- switch(nm,
       'catalog' = CatalogNode$new(node, verbose = verbose, ...),
       'service' = ServiceNode$new(node, verbose = verbose, ...),
       'dataset' = DatasetNode$new(node, verbose = verbose, ...),
       ThreddsNode$new(node, verbose = verbose, ...))

   if (!is.null(url)) n$url <- url

   return(n)
}

#' Build and xpath string, possibly using the user specified namespace
#' prefix.
#'
#' @export
#' @param x character one or more path segments
#' @param prefix character by default "d1" prepended to each of the segements
#'        in \code{x}.  If NA or length is 0 then ignore.
#' @param select charcater, by default search anywhere in the current node with ".//"
#' @return xpath descriptor
build_xpath <- function(x,
                        prefix = "d1",
                        select = ".//"){

  has_prefix <- all(!is.null(prefix[1]), !is.na(prefix[1]),  nchar(prefix[1]) >= 1)
  if (has_prefix){
    x <- paste(prefix[1], x, sep = ":")
  }
  x <- paste(x, collapse = "/")
  
  has_select <- all(!is.null(select[1]), !is.na(select[1]),  nchar(select[1]) >= 1)
  if (has_select) x <- paste0(select[1], x)

  x
}
