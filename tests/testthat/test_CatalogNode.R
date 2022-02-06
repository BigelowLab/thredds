# test_CatalogNode.R
# Author: Emmanuel Blondel <emmanuel.blondel1@gmail.com>
#
# Description: Integration tests for CatalogNode
#=======================
require(thredds, quietly = TRUE)
require(testthat)

test_that("browse catalog node",{
 
  top_uri <- 'https://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml'
  Top <- thredds::CatalogNode$new(top_uri)
  expect_is(Top, "CatalogNode")
  
})
