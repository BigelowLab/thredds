
# A dataset element represents a named, logical set of data at a level of
# granularity appropriate for presentation to a user. A dataset is direct if it
# contains at least one dataset access method, otherwise it is just a container
# for nested datasets, called a collection dataset. The name of the dataset
# element should be a human readable name that will be displayed to users.
# Multiple access methods specify different services for accessing the same
# dataset.


#' A class for a single datatset reference
#'
#' @description A direct Dataset representation that subclasses from ThreddsNode
#' @export
DatasetNode <- R6::R6Class("DatasetNode",
   inherit = ThreddsNode,
   public = list(
      #' @field name character, often the filename
      name = NULL,
      #' @field dataSize numeric, size in bytes
      dataSize = NULL,
      #' @field date character, modification date
      date = NULL,

      #' @description initialize an instance of ServiceNode
      #' @param x url or xml2::xml_node
      #' @param ... arguments for superclass initialization
      initialize = function(x, ...){
         self$name <- NA_character_
         self$dataSize <- NA_real_
         self$date <- NA_character_
         super$initialize(x, ...)
         if (is_xmlNode(self$node)){
            self$name <-  xml2::xml_attrs(self$node)[['name']]

            self$dataSize <- self$node %>%
                xml2::xml_find_first(build_xpath("dataSize",  prefix = self$prefix)) %>%
                xml2::xml_double()

            self$date <- self$node %>%
                xml2::xml_find_first(build_xpath("date",  prefix = self$prefix)) %>%
                xml2::xml_text()

            self$url <- self$get_url()
         } # is_xmlNode?
      },

      #' @description Overrides the GET method of the superclass.  GET is not permitted
      #' @return NULL
      GET = function(){
         cat("DatasetNode$GET() is not permitted. Try ncdf4::nc_open(DatasetNode$url)\n")
      }, # GET

      #' @description Retrieve the relative URL for a dataset.
      #'
      #' @param service character, the service to use.  (default 'dap' equivalent to 'opendap')
      #'    Ignored if `urlPath` or `href` is in the nodes' attributes.
      #' @param sep character, typically "/" or "" (default), used for joined base_url to relative url
      #' @param ... other arguments for \code{DatasetNode$list_access}
      #' @return character
      get_url = function(service = c("dap", "opendap", "wms")[1], sep = c("/", "")[2], ...){

         att <- xml2::xml_attrs(self$node)
         natts <- names(att)
         if ('href' %in% natts && nchar(att[['href']]) > 0) {
            return(att[['href']])
         }
         if ('urlPath' %in% natts && nchar(att[['urlPath']]) > 0){
            return(att[['urlPath']])
         }

         # otherwise hope there is an 'access' node
         index <- switch(tolower(service[1]),
                         "opendap" = "dap",
                         tolower(service[1]))
         a <- self$list_access(...)[[index]]
         if (length(a) == 0) return(NULL)

         if (nchar(self$base_url) > 0){
            uri <- paste(self$base_url, a[['urlPath']], sep = sep[1])
         } else {
            uri <- a[['urlPath']]
         }
         return(uri)
      }, #get_url

      #' @description list access methods
      #' @param xpath charcater, xpath descriptor
      #' @return named list of character vectors or NULL
      list_access = function(xpath = build_xpath("access", prefix = self$prefix)){
         x <- xml2::xml_find_all(self$node, xpath) %>%
            sapply( function(x) xml2::xml_attrs(x) , simplify = FALSE)
         if (length(x) == 0) return(NULL)
         names(x) <- sapply(x, "[[", "serviceName")
         x
      },

      #' @description print method
      #' @param prefix character, to be printed before each line of output (like spaces)
      #' @param ... other arguments for superclass
      print = function(prefix = ""){
         super$print(prefix = prefix)
         if (is_xmlNode(self$node)){
            cat(prefix, "  name: ", self$name, "\n", sep = "")
            cat(prefix, "  dataSize: ", self$dataSize, "\n", sep = "")
            cat(prefix, "  date: ", self$date, "\n", sep = "")
         }
      }
   )
)

