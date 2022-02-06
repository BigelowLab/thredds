#' A base representation that other nodes subclass from
#'
#' @description R6 base class for all other to inherit from
#' 
#' @note Abstract class
#' 
#' @export
ThreddsNode <- R6::R6Class("ThreddsNode",
   public = list(
      #' @field url character - possibly wrong but usually right!
      url = NULL,
      #' @field node xml2::xml_node
      node = NULL,
      #' @field verbose logical
      verbose = NULL,
      #' @field prefix xpath namespace prefix, NA or NULL or charcater() to ignore
      prefix = NULL,
      #' @field tries numeric number of requests attempts before failing
      tries = NULL,
      #' @field encoding character, by default 'UTF-8'
      encoding = NULL,
      #' @field base_url character, the base URL for the service
      base_url = NULL,


      #' @description initialize an instance of ThreddsNode
      #' @param x url or xml2::xml_node
      #' @param verbose logical, TRUE to be noisy (default FALSE)
      #' @param n_tries numeric, defaults to 3
      #' @param prefix character, the namespace to examine (default NULL, inherited when initialized)
      #' @param ns_strip logical, if TRUE then strip namespace (default FALSE)
      #' @param encoding character, by default 'UTF-8'
      #' @param base_url character, the base URL for the service
      initialize = function(x, verbose = FALSE, n_tries = 3, prefix = NULL,
                            ns_strip = FALSE, encoding = "UTF-8",
                            base_url = ""){
         self$url <- 'none'
         self$verbose <- verbose[1]
         self$tries <- n_tries[1]
         if(!is.null(prefix)) self$prefix <- prefix[1]
         self$encoding <- encoding[1]
         self$base_url <- base_url[1]
         if (!missing(x)){
            if (is_xmlNode(x)) {
               self$node <- x
               if (ns_strip){
                  xml2::xml_ns_strip(self$node)
               }
               #inherit thredds namespace
               ns <- as.list(xml2::xml_ns(self$node))
               self$prefix <- names(ns)[ns == "http://www.unidata.ucar.edu/namespaces/thredds/InvCatalog/v1.0"]
            } else if (is.character(x)) {
               r <- try(httr::GET(x))
               if (inherits(r, "try-error")){
                  warning("unable to GET:", x)
               } else {
                  if (httr::status_code(r) == 200){
                     self$node <- try(httr::content(r,
                                                    type = 'text/xml',
                                                    encoding = self$encoding))
                     if (inherits(self$node, "try-error")){
                        warning("unable to extract http content to XML")
                     } else {
                        if (ns_strip){
                           xml2::xml_ns_strip(self$node)
                        }
                        #inherit thredds namespace
                        ns <- as.list(xml2::xml_ns(self$node))
                        self$prefix <- names(ns)[ns == "http://www.unidata.ucar.edu/namespaces/thredds/InvCatalog/v1.0"]
                     }
                  }
               }
               self$url <- x
            }
         }
      },

      #' @description print method
      #' @param prefix character, to be printed before each line of output (like spaces)
      #' @param ... other argum,ents (ignored for now)
      print = function(prefix = "", ...){
         cat(prefix, class(self)[1]," (R6): \n", sep = "")
         s <- sprintf("  verbose: %s    tries: %i    namespace prefix: %s",
                      as.character(self$verbose),
                      self$tries,
                      self$prefix)
         cat(prefix, s, "\n", sep = "")
         cat(prefix, "  url: ", self$url, "\n", sep = "")
         #if (is_xmlNode(self$node)) {
         #   cat(prefix, "  children: ",
         #       paste(self$children_names(), collapse = " "), "\n", sep = "")
         #}
      },

      #' @description
      #' Retrieve a node of the contents at this nodes URL
      #'
      #' @return ThreddsNode or subclass or NULL
      GET = function(){
         if (is.na(self$url) || self$url == "none") {
            if (self$verbose) cat("GET url is missing\n")
            return(NULL)
         }
         if (self$verbose) cat("GET", self$url, "\n")
         i <- 1
         r <- NULL
         while(i <= self$tries){
            r <- try(httr::GET(self$url))
            if (inherits(r, "try-error")){
               if (self$verbose) {
                  cat(sprintf("*** GET failed after attempt %i\n", i))
                  if (i < self$tries) {
                     cat("  will try again\n")
                  } else {
                     cat("  exhausted permitted tries, returning NULL\n")
                  }
               }
               r <- NULL
               i <- i + 1
            } else {
               if (i > 1) cat(sprintf("  whew!  attempt %i successful\n", i))
               r <- parse_node(r,
                               prefix = self$prefix,
                               verbose = self$verbose,
                               n_tries = self$tries)
               break
            }
         }
         return(r)
      },

      #' @description Browse the URL if possible
      browse = function(){

         if (interactive() &&
             !is.na(self$url) &&
             nchar(self$url) > 0 &&
             (grepl("^.*\\.html$", self$url) || grepl("^.*\\.xml$", self$url)) ){
            httr::BROWSE(self$url)
         } else {
            warning("unable to browse URL:" , self$url)
         }
         invisible(NULL)
      },

      #' @description Retrieve a vector of unique child names
      #' @param ... further arguments for \code{\link{xml_children_names}}
      #' @return a vector of zero or more child names
      children_names = function(...){
        xml_children_names(self$node, ...)
      }

   ) # end public

   ) # end of class definition

