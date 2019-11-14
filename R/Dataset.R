
# A dataset element represents a named, logical set of data at a level of
# granularity appropriate for presentation to a user. A dataset is direct if it
# contains at least one dataset access method, otherwise it is just a container
# for nested datasets, called a collection dataset. The name of the dataset
# element should be a human readable name that will be displayed to users.
# Multiple access methods specify different services for accessing the same
# dataset.



#' A direct Dataset representation that subclasses from ThreddsNodeRefClass
#'
#' @family Thredds
#' @include Datasets.R Thredds.R
#' @field dataSize numeric size in bytes
#' @field date character
#' @field urlPath character relative URL, use url or get_url() instead
#' @export
DatasetRefClass <- setRefClass("DatasetRefClass",
   contains = 'DatasetsRefClass',

   fields = list(
      dataSize = 'numeric',
      date = 'character',
      serviceName = 'character',
      urlPath = 'character'
      ),

   methods = list(
      initialize = function(x, ...){
         .self$dataSize <- NA_real_
         .self$date <- NA_character_
         .self$serviceName <- NA_character_
         .self$urlPath <- NA_character_
         callSuper(x, ...)
         if (!is_xmlNode(.self$node)){
            .self$dataSize <- NA_real_
            .self$date <- NA_character_
            .self$serviceName <- NA_character_
            .self$urlPath <- NA_character_
         } else {

            .self$dataSize <- .self$node %>%
                xml2::xml_find_first(.self$xpath("dataSize", prefix = ".//")) %>%
                xml2::xml_double()

            .self$date <- .self$node %>%
                xml2::xml_find_first(.self$xpath("date", prefix = ".//")) %>%
                xml2::xml_text()

            tmp <- .self$node %>% xml2::xml_find_first(.self$xpath("access", prefix = ".//"))
            if (length(tmp) > 0){
               atts <- xml2::xml_attrs(tmp)
               natts <- names(atts)
               nm <- c("serviceName", "urlPath")
               for (n in nm) {
                  if (n %in% natts) .self[[n]] <- atts[[n]]
               }
            } # access?
            # last chance to get the urlPath or others if not already found
            # sometimes these are placed as attributes of the node, rather
            # than as attributes of the 'access' child
            if (is.null(.self$urlPath) || is.na(.self$urlPath) || (nchar(.self$urlPath) == 0) ){
              atts <- xml2::xml_attrs(.self$node)
              natts <- names(atts)
              nm <- c("urlPath")
              for (n in nm) {
                if (n %in% natts) .self[[n]] <- atts[[n]]
              }
            }
         } # is_xmlNode?
      },

      show = function(prefix = ""){
         "show the contents"
         callSuper(prefix = prefix)
         if (is_xmlNode(.self$node)){
            cat(prefix, "  dataSize: ", .self$dataSize, "\n", sep = "")
            cat(prefix, "  date: ", .self$date, "\n", sep = "")
            cat(prefix, "  serviceName: ", .self$serviceName, "\n", sep = "")
            cat(prefix, "  urlPath: ", .self$urlPath, "\n", sep = "")
         }
      }
   )
)


#' Overrides the GET method of the superclass.  GET is not permitted
#'
#' @name DatasetRefClass_GET
#' @return NULL
NULL
DatasetRefClass$methods(
   GET = function(){
      cat("DatasetRefClass$GET is not permitted. Try ncdf4::nc_open(ref$url)\n")
   })



#' Retrieve the URL for a dataset
#'
#' Datasets may not be aware of the the way they are served (OPeNDAP, WMS, NCML, etc)
#' Typically this maybe known at the TopCatalog that reference the dataset.
#' This function provides a convenient way to form the URL for data access rather than
#' simple HMTL viewing.
#'
#' @name DatasetRefClass_get_url
#' @param service character or NULL.  If not NULL then substitute the value
#'      of \code{replace} with this.  OPeNDAP is "thredds/dodsC".
#' @return character
NULL
DatasetRefClass$methods(
    get_url = function(service = NULL, replace = '/thredds/catalog/'){

        x <- if (!is.null(service)){
            sub(replace, service, .self$url, fixed = TRUE)
        } else {
            .self$url
        }
        x
   })
