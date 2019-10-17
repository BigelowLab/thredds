
# A dataset element represents a named, logical set of data at a level of
# granularity appropriate for presentation to a user. A dataset is direct if it
# contains at least one dataset access method, otherwise it is just a container
# for nested datasets, called a collection dataset. The name of the dataset
# element should be a human readable name that will be displayed to users.
# Multiple access methods specify different services for accessing the same
# dataset.


#' A Dataset collection that subclasses from ThreddsNodeRefClass
#' @family Thredds
#' @include Thredds.R
#' @field name character
#' field ID character - seems to be a relative path
#' @export
DatasetsRefClass <- setRefClass("DatasetsRefClass",
   contains = 'ThreddsNodeRefClass',
   fields = list(
      name = 'character',
      ID = 'character'),
   methods = list(
      initialize = function(x, ...){
         callSuper(x, ...)
         if (is_xmlNode(.self$node)){
            atts <- xml2::xml_attrs(.self$node)
            natts <- names(atts)
            nm <- c("name", "ID")
            for (n in nm) {
               if (n %in% natts) .self[[n]] <- atts[[n]]
            }
         }
      },

      show = function(prefix = ""){
         "show the contents"
         callSuper(prefix = prefix)
         if (is_xmlNode(.self$node) && inherits(.self, 'DatasetsRefClass')){
            x <- xml2::xml_find_all(.self$node, ".//dataset")
            nm <- if (length(x) > 0)
               sapply(x, function(x) xml2::xml_attrs(x)[['name']]) else
               "NA"
            cat(prefix, "  datasets: ", paste(nm, collapse = " "), "\n", sep = "")
         }
      })
   )

#' Retrieve the URL for a dataset
#'
#' @name DatasetsRefClass_get_url
#' @return character
NULL
DatasetsRefClass$methods(
   get_url = function(){
      .self$name
   })

#' Retrieve the datasets from a dataset collection
#'
#' @name DatasetsRefClass_get_collection
#' @param xpath character, xpath specification
#' @return a list of zero or more DatasetRefClass
NULL
DatasetsRefClass$methods(
   get_collection = function(xpath = ".//dataset/dataset"){
      if (!is_xmlNode(.self$node)) return(NULL)
      x <- .self$node %>% xml2::xml_find_all(xpath)
      x <- if (length(x) > 0){
            lapply(x, parse_node)
        } else {
            NULL
        }
    x
   })
