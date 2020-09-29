#' A simple class for parsing and holdoing service info
#' 
#' @description A Service representation that subclasses from ThreddsNode
#' @export
ServiceNode <- R6::R6Class("ServiceNode",
   inherit = ThreddsNode,
   public = list(
      #' @field name character
      name = NULL,
      #' @field serviceType character
      serviceType = NULL,
      #' @field base character base url
      base = NULL,
      
      #' @description initialize an instance of ServiceNode
      #' @param x url or xml2::xml_node
      #' @param ... arguments for superclass initialization
      initialize = function(x, ...){
         super$initialize(x, ...)
         self$name <- character()
         self$serviceType <- character()
         self$base <- character()
         cat("init\n")
         if (is_xmlNode(self$node)){
            atts <- xml2::xml_attrs(x)
            natts <- names(atts)
            if ("name" %in% natts) self$name <- atts[['name']]
            if ('serviceType' %in% natts) self$serviceType <- atts[['serviceType']]
            if ('base' %in% natts) self$base <- atts[['base']]
         }
      },
      
      #' @description print method
      #' @param prefix character, to be printed before each line of output (like spaces)
      #' @param ... other arguments for superclass
      print = function(prefix = ""){
         super$print(prefix = "")
         cat(prefix, "  name: ", self$name, "\n", sep = "")
         cat(prefix, "  serviceType: ", self$serviceType, "\n")
         cat(prefix, "  base: ", self$base, "\n", sep = "")
      })
   )
