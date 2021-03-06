#' Basic plot of WSB based on huc
#' 
#' Basic plot
#' @param sites character vector of site ids
#' @param col for basin fill
#' @param mapRange vector of map limits (min long, max long, min lat, max lat)
#' @import sp 
#' @import rgdal
#' @export
#' @examples
#' sites <- c("01137500","01491000", "01573000", "01576000","06485500")
#' path <- system.file("extdata", package="hydroMap")
#' siteInfo <- readRDS(file.path(path,"siteInfo.rds"))
#' png("test.png")
#' plotWSB(sites)
#' points(siteInfo$dec_long_va, siteInfo$dec_lat_va, pch=20, col="red", cex=1)
#' dev.off()
#' 
#' plotWSB(sites[4], mapRange=c(-80,-74, 38, 46))
#' points(siteInfo$dec_long_va[4], siteInfo$dec_lat_va[4], pch=20, col="red", cex=1)
plotWSB <- function(sites,col="#A8A8A850", mapRange = NA){

  shape_hydropoly <- shape_hydropoly
  shape_polibounds <- shape_polibounds
  shape_hydroline <- shape_hydroline
  basins <- getBasin(sites)
  basins <- spTransform(basins,CRS(proj4string(shape_polibounds)))
  if(all(is.na(mapRange))){
    plot(basins, col=col)
    mapRange <- par()$usr
    shape_hydropoly <- clipShape(shape_hydropoly, mapRange)
    shape_polibounds <- clipShape(shape_polibounds, mapRange)
    shape_hydroline <- clipShape(shape_hydroline, mapRange)
    
    plot(shape_hydropoly,col="lightskyblue2",add=TRUE)
    lines(shape_hydroline,col="lightskyblue2")
    plot(shape_polibounds,add=TRUE)    
  } else {

    shape_hydropoly <- clipShape(shape_hydropoly, mapRange)
    shape_polibounds <- clipShape(shape_polibounds, mapRange)
    shape_hydroline <- clipShape(shape_hydroline, mapRange)
    basins <- crop(basins, extent(mapRange)) #should figure this out...clipping a SpatialPolygonsDataFrame
    
    plot(shape_hydropoly,col="lightskyblue2")
    lines(shape_hydroline,col="lightskyblue2")
    plot(shape_polibounds,add=TRUE)
    plot(basins, col=col,add=TRUE)
  }
 
}

#' Basic plot of WSB based on huc
#' 
#' Basic plot
#' @param shapefile shapefile to clip
#' @param mapRange vector of map limits (min long, max long, min lat, max lat)
#' @import sp 
#' @import rgdal
#' @import rgeos 
#' @import raster
#' @export
#' @examples
#' mapRange=c(-80,-74, 38, 46)
#' shape_hydropoly <- shape_hydropoly
#' clippedShape <- clipShape(shape_hydropoly, mapRange)
clipShape <- function(shapefile, mapRange){
  ext <- extent(mapRange) 
  clipe <- as(ext, "SpatialPolygons") 
  
  proj4string(clipe) <- CRS(proj4string(shapefile)) 
  cropd <- SpatialPolygonsDataFrame(clipe, data.frame(x = 1), match.ID = FALSE) 
  shapeClipped <- gIntersection(shapefile, cropd,byid=TRUE) 
  return(shapeClipped)
}

#' Get shapefile basins
#' 
#' Get shapefile basins
#' @param sites character id
#' @return shapefile
#' @importFrom httr GET
#' @importFrom httr write_disk
#' @importFrom utils URLencode
#' @import sp 
#' @import rgdal 
#' @export
#' @examples
#' sites <- c("01491000", "01573000", "01576000","01137500","06485500")
#' getBasin(sites)
getBasin <- function(sites){
  baseURL <- "http://cida-eros-wsdev.er.usgs.gov:8081/geoserver/NWC/ows?service=WFS&version=1.1.0&srsName=EPSG:4326&request=GetFeature&typeName=NWC:epa_basins"
  
  siteText <- ""
  for(i in sites){
    siteText <- paste0(siteText,'<ogc:PropertyIsEqualTo  matchCase="true">',
                       '<ogc:PropertyName>site_no</ogc:PropertyName>',
                       '<ogc:Literal>',i,'</ogc:Literal>',
                       '</ogc:PropertyIsEqualTo>')
  }
  
  if(length(sites) > 1){
    filterXML <- paste0('<ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">',
                        '<ogc:Or>',siteText,'</ogc:Or>',
                        '</ogc:Filter>')
    
  } else {
    filterXML <- paste0('<ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">',
                        '<ogc:PropertyIsEqualTo matchCase="true">',
                        '<ogc:PropertyName>site_no</ogc:PropertyName>',
                        '<ogc:Literal>',sites,'</ogc:Literal>',
                        '</ogc:PropertyIsEqualTo>',
                        '</ogc:Filter>')
  }
  
  filterXML <- URLencode(filterXML,reserved = TRUE)
  
  requestURL <- paste0(baseURL,"&outputFormat=shape-zip", "&filter=", filterXML)
  destination = tempfile(pattern = 'basins_shape', fileext='.zip')
  file <- GET(requestURL, write_disk(destination, overwrite=T))
  shp.path <- tempdir()
  unzip(destination, exdir = shp.path)
  basins = readOGR(shp.path, layer='epa_basins')
  return(basins)
}
