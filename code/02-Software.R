## ----software-triangle, echo=FALSE, fig.cap="Software combination used in this book.", out.width="55%"----
knitr::include_graphics("figures/software_triangle.png")

## sudo apt-get install libgdal-dev libproj-dev

## wget https://mran.blob.core.windows.net/install/mro/3.4.3/microsoft-r-open-3.4.3.tar.gz

## ------------------------------------------------------------------------
sessionInfo()

## ---- eval=FALSE---------------------------------------------------------
## system("gdalinfo --version")

## sudo apt-get install gdebi-core

## sudo add-apt-repository ppa:ubuntugis/ubuntugis-unstable

## ---- eval=FALSE---------------------------------------------------------
## system("saga_cmd --version")

## sudo sh -c 'echo "deb http://qgis.org/debian xenial main" >> /etc/apt/sources.list'

## sudo apt-get install htop iotop

## sudo apt-get install build-essential automake;

## sudo apt-get install pigz zip unzip p7zip-full

## ----whiteboxtools-preview, echo=FALSE, fig.cap="Calling WhiteboxTools from QGIS via the WhiteboxTools plugin.", out.width="100%"----
knitr::include_graphics("figures/whiteboxtools-preview.jpg")

## ---- eval=FALSE---------------------------------------------------------
## system(paste0('"/home/tomislav/software/WBT/whitebox_tools" ',
##   '--run=FlowAccumulationFullWorkflow --dem="./extdata/DEMTOPx.tif" ',
##   '--out_type="Specific Contributing Area" --log="False" --clip="False" ',
##   '--esri_pntr="False" ',
##   '--out_dem="./extdata/DEMTOPx_out.tif" ',
##   '--out_pntr="./extdata/DEMTOPx_pntr.tif" ',
##   '--out_accum="./extdata/DEMTOPx_accum.tif" -v'))

## ----eberg-hydroflow-preview-3d, echo=FALSE, fig.cap="Hydrological flow accummulation map based on the Ebergotzen DEM derived using WhiteboxTools.", out.width="100%"----
knitr::include_graphics("figures/eberg_hydroflow_preview_3d.jpg")

## ----rstudio-example, echo=FALSE, fig.cap="RStudio is a commonly used R editor written in C++.", out.width="100%"----
knitr::include_graphics("figures/rstudio_example.png")

## ---- eval=FALSE---------------------------------------------------------
## ls <- c("reshape", "Hmisc", "rgdal", "raster", "sf", "GSIF", "plotKML",
##         "nnet", "plyr", "ROCR", "randomForest", "quantregForest",
##         "psych", "mda", "h2o", "h2oEnsemble", "dismo", "grDevices",
##         "snowfall", "hexbin", "lattice", "ranger",
##         "soiltexture", "aqp", "colorspace", "Cubist",
##         "randomForestSRC", "ggRandomForests", "scales",
##         "xgboost", "parallel", "doParallel", "caret",
##         "gam", "glmnet", "matrixStats", "SuperLearner",
##         "quantregForest", "intamap", "fasterize", "viridis")
## new.packages <- ls[!(ls %in% installed.packages()[,"Package"])]
## if(length(new.packages)) install.packages(new.packages)

## sudo add-apt-repository ppa:webupd8team/java

## ------------------------------------------------------------------------
if(!require(GSIF)){
  install.packages("GSIF", repos=c("http://R-Forge.R-project.org"), 
                 type = "source", dependencies = TRUE)
}

## ---- eval=FALSE---------------------------------------------------------
## source_https <- function(url, ...) {
##    # load package
##    require(RCurl)
##    # download:
##    cat(getURL(url, followlocation = TRUE,
##        cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl")),
##        file = basename(url))
##    source(basename(url))
## }
## source_https("https://raw.githubusercontent.com/cran/GSIF/master/R/OCSKGM.R")

## ------------------------------------------------------------------------
library(GSIF)
library(sp)
library(boot)
library(aqp)
library(plyr)
library(rpart)
library(splines)
library(gstat)
library(quantregForest)
library(plotKML)
demo(meuse, echo=FALSE)
omm <- fit.gstatModel(meuse, om~dist+ffreq, meuse.grid, method="quantregForest")
om.rk <- predict(omm, meuse.grid)
om.rk
#plotKML(om.rk)

## ----ge-preview, echo=FALSE, fig.cap="Example of a plotKML output for geostatistical model and prediction.", out.width="90%"----
knitr::include_graphics("figures/ge_preview.jpg")

## ------------------------------------------------------------------------
if(Sys.info()['sysname']=="Windows"){
  saga_cmd = "C:/Progra~1/SAGA-GIS/saga_cmd.exe"
} else {
  saga_cmd = "saga_cmd"
}
system(paste(saga_cmd, "-v"))

## ------------------------------------------------------------------------
library(plotKML)
library(rgdal)
library(raster)
data("eberg_grid")
gridded(eberg_grid) <- ~x+y
proj4string(eberg_grid) <- CRS("+init=epsg:31467")
writeGDAL(eberg_grid["DEMSRT6"], "./extdata/DEMSRT6.sdat", "SAGA")
system(paste(saga_cmd, 'ta_lighting 0 -ELEVATION "./extdata/DEMSRT6.sgrd" 
             -SHADE "./extdata/hillshade.sgrd" -EXAGGERATION 2'))

## ----rstudio-saga-gis, echo=FALSE, fig.cap="Deriving hillshading using SAGA GIS and then visualizing the result in R.", out.width="100%"----
knitr::include_graphics("figures/rstudio_saga_gis.png")

## ------------------------------------------------------------------------
if(.Platform$OS.type == "windows"){
  gdal.dir <- shortPathName("C:/Program files/GDAL")
  gdal_translate <- paste0(gdal.dir, "/gdal_translate.exe")
  gdalwarp <- paste0(gdal.dir, "/gdalwarp.exe") 
} else {
  gdal_translate = "gdal_translate"
  gdalwarp = "gdalwarp"
}
system(paste(gdalwarp, "--help"))

## ----plot-eberg-ll, fig.width=7, fig.cap="Ebergotzen DEM reprojected in geographical coordinates.", out.width="80%"----
system(paste('gdalwarp ./extdata/DEMSRT6.sdat ./extdata/DEMSRT6_ll.tif',  
             '-t_srs \"+proj=longlat +datum=WGS84\"'))
library(raster)
plot(raster("./extdata/DEMSRT6_ll.tif"))

