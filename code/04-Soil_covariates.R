## ----eberg-zones-spplot, fig.cap="Ebergotzen parent material polygon map with legend.", out.width="70%"----
library(rgdal)
library(raster)
library(plotKML)
library(viridis)
data(eberg_zones)
spplot(eberg_zones[1])

## ------------------------------------------------------------------------
library(plotKML)
data("eberg_grid25")
gridded(eberg_grid25) <- ~x+y
proj4string(eberg_grid25) <- CRS("+init=epsg:31467")
r <- raster(eberg_grid25)
r

## ----eberg-zones-grid, fig.cap="Ebergotzen parent material polygon map rasterized to 25 m spatial resolution.", out.width="70%"----
names(eberg_zones)
eberg_zones_r <- rasterize(eberg_zones, r, field="ZONES")
plot(eberg_zones_r)

## ------------------------------------------------------------------------
library(sf)
library(fasterize)
eberg_zones_sf <- as(eberg_zones, "sf")
eberg_zones_r <- fasterize(eberg_zones_sf, r, field="ZONES")

## ------------------------------------------------------------------------
eberg_zones$ZONES_int <- as.integer(eberg_zones$ZONES)
writeOGR(eberg_zones["ZONES_int"], "extdata/eberg_zones.shp", ".", "ESRI Shapefile")

## ------------------------------------------------------------------------
if(.Platform$OS.type=="unix"){
  saga_cmd = "saga_cmd"
}
if(.Platform$OS.type=="windows"){
  saga_cmd = "C:/Progra~1/SAGA-GIS/saga_cmd.exe"
}
saga_cmd

## ------------------------------------------------------------------------
pix = 25
system(paste0(saga_cmd, ' grid_gridding 0 -INPUT \"extdata/eberg_zones.shp\" ',
      '-FIELD \"ZONES_int\" -GRID \"extdata/eberg_zones.sgrd\" -GRID_TYPE 0 ',
      '-TARGET_DEFINITION 0 -TARGET_USER_SIZE ', pix, ' -TARGET_USER_XMIN ', 
      extent(r)[1]+pix/2,' -TARGET_USER_XMAX ', extent(r)[2]-pix/2, 
      ' -TARGET_USER_YMIN ', extent(r)[3]+pix/2,' -TARGET_USER_YMAX ', 
      extent(r)[4]-pix/2))
eberg_zones_r2 <- readGDAL("extdata/eberg_zones.sdat")

## ------------------------------------------------------------------------
levels(eberg_zones$ZONES)
eberg_zones_r2$ZONES <- as.factor(eberg_zones_r2$band1)
levels(eberg_zones_r2$ZONES) <- levels(eberg_zones$ZONES)
summary(eberg_zones_r2$ZONES)

## ----eberg-zones-rasterized, echo=FALSE, fig.cap="Ebergotzen zones rasterized to 25 m resolution and with correct factor labels.", out.width="65%"----
knitr::include_graphics("figures/eberg_zones_rasterized.png")

## ------------------------------------------------------------------------
data(eberg_grid)
gridded(eberg_grid) <- ~x+y
proj4string(eberg_grid) <- CRS("+init=epsg:31467")
names(eberg_grid)

## ------------------------------------------------------------------------
writeGDAL(eberg_grid["TWISRT6"], "extdata/eberg_grid_TWISRT6.tif")
system(paste0('gdalwarp extdata/eberg_grid_TWISRT6.tif',
              ' extdata/eberg_grid_TWISRT6_25m.tif -r \"cubicspline\" -te ', 
              paste(as.vector(extent(r))[c(1,3,2,4)], collapse=" "),
              ' -tr ', pix, ' ', pix, ' -overwrite'))

## "C:/Progra~1/GDAL/gdalwarp.exe eberg_grid_TWISRT6.tif

## ---- eval=FALSE, echo=FALSE, results='hide', fig.keep='none'------------
## par(mfrow=c(1,2))
## zlim = range(eberg_grid$TWISRT6, na.rm=TRUE)
## image(raster(eberg_grid["TWISRT6"]), col=SAGA_pal[[1]], zlim=zlim, main="Original", asp=1)
## image(raster("extdata/eberg_grid_TWISRT6_25m.tif"), col=SAGA_pal[[1]], zlim=zlim, main="Downscaled", asp=1)

## ----eberg-original-vs-downscaled, echo=FALSE, fig.cap="Original TWI vs downscaled map from 100 m to 25 m.", out.width="100%"----
knitr::include_graphics("figures/eberg_original_vs_downscaled.png")

## ------------------------------------------------------------------------
system(paste0('gdalwarp extdata/eberg_grid_TWISRT6.tif',
              ' extdata/eberg_grid_TWISRT6_250m.tif -r \"average\" -te ', 
              paste(as.vector(extent(r))[c(1,3,2,4)], collapse=" "),
              ' -tr 250 250 -overwrite'))

## ----eberg-original-vs-aggregated, echo=FALSE, fig.cap="Original TWI vs aggregated map from 100 m to 250 m.", out.width="100%"----
knitr::include_graphics("figures/eberg_original_vs_aggregated.png")

## ------------------------------------------------------------------------
saga_DEM_derivatives <- function(INPUT, MASK=NULL, 
                                 sel=c("SLP","TWI","CRV","VBF","VDP","OPN","DVM")){
  if(!is.null(MASK)){
    ## Fill in missing DEM pixels:
    suppressWarnings( system(paste0(saga_cmd, 
                                    ' grid_tools 25 -GRID=\"', INPUT, 
                                    '\" -MASK=\"', MASK, '\" -CLOSED=\"', 
                                    INPUT, '\"')) )
  }
  ## Slope:
  if(any(sel %in% "SLP")){
    try( suppressWarnings( system(paste0(saga_cmd, 
                                         ' ta_morphometry 0 -ELEVATION=\"', 
                                         INPUT, '\" -SLOPE=\"', 
                                         gsub(".sgrd", "_slope.sgrd", INPUT), 
                                         '\" -C_PROF=\"', 
                                         gsub(".sgrd", "_cprof.sgrd", INPUT), '\"') ) ) )
  }
  ## TWI:
  if(any(sel %in% "TWI")){
    try( suppressWarnings( system(paste0(saga_cmd, 
                                         ' ta_hydrology 15 -DEM=\"', 
                                         INPUT, '\" -TWI=\"', 
                                         gsub(".sgrd", "_twi.sgrd", INPUT), '\"') ) ) )
  }
  ## MrVBF:
  if(any(sel %in% "VBF")){
    try( suppressWarnings( system(paste0(saga_cmd, 
                                         ' ta_morphometry 8 -DEM=\"', 
                                         INPUT, '\" -MRVBF=\"',
                                         gsub(".sgrd", "_vbf.sgrd", INPUT),
                                         '\" -T_SLOPE=10 -P_SLOPE=3') ) ) )
  }
  ## Valley depth:
  if(any(sel %in% "VDP")){
    try( suppressWarnings( system(paste0(saga_cmd, 
                                         ' ta_channels 7 -ELEVATION=\"', 
                                         INPUT, '\" -VALLEY_DEPTH=\"', 
                                         gsub(".sgrd", "_vdepth.sgrd", 
                                              INPUT), '\"') ) ) )
  }
  ## Openness:
  if(any(sel %in% "OPN")){
    try( suppressWarnings( system(paste0(saga_cmd, 
                                         ' ta_lighting 5 -DEM=\"', 
                                         INPUT, '\" -POS=\"', 
                                         gsub(".sgrd", "_openp.sgrd", INPUT), 
                                         '\" -NEG=\"', 
                                         gsub(".sgrd", "_openn.sgrd", INPUT), 
                                         '\" -METHOD=0' ) ) ) )
  }
  ## Deviation from Mean Value:
  if(any(sel %in% "DVM")){
    suppressWarnings( system(paste0(saga_cmd, 
                                    ' statistics_grid 1 -GRID=\"', 
                                    INPUT, '\" -DEVMEAN=\"', 
                                    gsub(".sgrd", "_devmean.sgrd", INPUT), 
                                    '\" -RADIUS=11' ) ) )
  }
}

## ---- eval=FALSE---------------------------------------------------------
## writeGDAL(eberg_grid["DEMSRT6"], "extdata/DEMSRT6.sdat", "SAGA")
## saga_DEM_derivatives("DEMSRT6.sgrd")

## ---- eval=FALSE---------------------------------------------------------
## dem.lst <- list.files("extdata", pattern=glob2rx("^DEMSRT6_*.sdat"), full.names = TRUE)
## plot(raster::stack(dem.lst), col=rev(magma(10, alpha = 0.8)))

## ----dem-derivatives-plot, echo=FALSE, fig.cap="Some standard DEM derivatives calculated using SAGA GIS.", out.width="90%"----
knitr::include_graphics("figures/dem_derivatives_plot.png")

## ---- eval=FALSE---------------------------------------------------------
## par(mfrow=c(1,2))
## image(raster(eberg_grid["test"]), col=SAGA_pal[[1]], zlim=zlim, main="Original", asp=1)
## image(raster("test.sdat"), col=SAGA_pal[[1]], zlim=zlim, main="Filtered", asp=1)

## ---- eval=FALSE---------------------------------------------------------
## data(eberg_grid)
## gridded(eberg_grid) <- ~x+y
## proj4string(eberg_grid) <- CRS("+init=epsg:31467")
## formulaString <- ~ PRMGEO6+DEMSRT6+TWISRT6+TIRAST6
## eberg_spc <- GSIF::spc(eberg_grid, formulaString)
## names(eberg_spc@predicted) # 11 components on the end;

## ---- eval=FALSE, echo=FALSE, results='hide', fig.keep='none'------------
## rd <- range(eberg_spc@predicted@data[,1], na.rm=TRUE)
## plot(stack(eberg_spc@predicted[1:11]), zlim=rd, col=rev(viridis(10, alpha = 0.8)))

## ----eberg-spc-11-plot, echo=FALSE, fig.cap="11 PCs derived using input Ebergotzen covariates.", out.width="100%"----
knitr::include_graphics("figures/eberg_spc_11_plot.png")

## ---- eval=FALSE---------------------------------------------------------
## library(raster)
## grd.lst <- list.files(pattern="25m")
## grd.lst
## grid25m <- stack(grd.lst)
## grid25m <- as(grid25m, "SpatialGridDataFrame")
## str(grid25m)

## ---- eval=FALSE---------------------------------------------------------
## saveRDS(grid25m, file = "extdata/covariates25m.rds")

## ---- eval=FALSE---------------------------------------------------------
## library(sp)
## data(eberg)
## coordinates(eberg) <- ~X+Y
## proj4string(eberg) <- CRS("+init=epsg:31467")
## ov <- as.data.frame(extract(stack(grd.lst), eberg))
## str(ov[complete.cases(ov),])

## ---- eval=FALSE---------------------------------------------------------
## overlay.fun <- function(i, y){
##   raster::extract(raster(i), na.rm=FALSE,
##       spTransform(y, proj4string(raster(i))))}

## ---- eval=FALSE---------------------------------------------------------
## ov  <- data.frame(mclapply(grd.lst, FUN=overlay.fun, y=eberg))
## names(ov) <- basename(grd.lst)

## ------------------------------------------------------------------------
fn = system.file("pictures/SP27GTIF.TIF", package = "rgdal")
obj <- rgdal::GDALinfo(fn)

## ---- eval=FALSE, fig.keep='none'----------------------------------------
## tiles <- GSIF::getSpatialTiles(obj, block.x=5000, return.SpatialPolygons = FALSE)
## tiles.pol <- GSIF::getSpatialTiles(obj, block.x=5000, return.SpatialPolygons = TRUE)
## tile.pol  <- SpatialPolygonsDataFrame(tiles.pol, tiles)
## plot(raster(fn), col=bpy.colors(20))
## lines(tile.pol, lwd=2)

## ----rplot-large-raster-tiles, echo=FALSE, fig.cap="Example of a tiling system derived using the GSIF::getSpatialTiles function.", out.width="60%"----
knitr::include_graphics("figures/rplot_large_raster_tiles.png")

## ---- eval=FALSE---------------------------------------------------------
## x = readGDAL(fn, offset=unlist(tiles[1,c("offset.y","offset.x")]),
##              region.dim=unlist(tiles[1,c("region.dim.y","region.dim.x")]),
##              output.dim=unlist(tiles[1,c("region.dim.y","region.dim.x")]), silent = TRUE)
## spplot(x)

## ----sp27gtif-tile, echo=FALSE, fig.cap="A tile produced from a satellite image in the example in the previous figure.", out.width="60%"----
knitr::include_graphics("figures/sp27gtif_tile.png")

## ------------------------------------------------------------------------
fun_mask <- function(i, tiles, dir="./tiled/", threshold=190){
  out.tif = paste0(dir, "T", i, ".tif")
  if(!file.exists(out.tif)){
    x = readGDAL(fn, offset=unlist(tiles[i,c("offset.y","offset.x")]),
                 region.dim=unlist(tiles[i,c("region.dim.y","region.dim.x")]), 
                 output.dim=unlist(tiles[i,c("region.dim.y","region.dim.x")]),
                 silent = TRUE)
    x$mask = ifelse(x$band1>threshold, 1, 0)
    writeGDAL(x["mask"], type="Byte", mvFlag = 255, 
              out.tif, options=c("COMPRESS=DEFLATE"))
  }
}

## ---- eval=FALSE---------------------------------------------------------
## x0 <- mclapply(1:nrow(tiles), FUN=fun_mask, tiles=tiles)

## ---- eval=FALSE---------------------------------------------------------
## t.lst <- list.files(path="extdata/tiled", pattern=glob2rx("^T*.tif$"),
##                     full.names=TRUE, recursive=TRUE)
## cat(t.lst, sep="\n", file="SP27GTIF_tiles.txt")
## system('gdalbuildvrt -input_file_list SP27GTIF_tiles.txt SP27GTIF.vrt')
## system('gdalwarp SP27GTIF.vrt SP27GTIF_mask.tif -ot \"Byte\"',
##   ' -dstnodata 255 -co \"BIGTIFF=YES\" -r \"near\" -overwrite -co \"COMPRESS=DEFLATE\"')

## ----sp27gtif-mask, echo=FALSE, fig.cap="Final processed output.", out.width="60%"----
knitr::include_graphics("figures/sp27gtif_mask.png")

