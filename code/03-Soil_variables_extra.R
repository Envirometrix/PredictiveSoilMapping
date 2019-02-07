library(GSIF)
library(plotKML)
library(rgdal)
library(sp)
library(raster)

data(landmask)
gridded(landmask) <- ~x+y
proj4string(landmask) <- "+proj=longlat +datum=WGS84"
require(maps)
country.m = map('world', plot=FALSE, fill=TRUE)
IDs <- sapply(strsplit(country.m$names, ":"), function(x) x[1])
require(maptools)
country <- as(map2SpatialPolygons(country.m, IDs=IDs), "SpatialLines")
require(rgeos)
bbx <- readWKT("POLYGON((-178 89, 178 89, 178 -89, -178 -89, -178 89))")
country.cut <- gIntersection(country, bbx)
 
spplot(landmask["mask"], col.regions="grey", sp.layout=list("sp.lines", country))
spplot(landmask["soilmask"], col.regions="grey", sp.layout=list("sp.lines", country))
## also available in the Robinson projection at 20 km grid:
data(landmask20km)
image(landmask20km[1])
summary(landmask20km$suborder)

data(soil.legends)
proj4string(country.cut) <- "+proj=longlat +datum=WGS84"
country.rob <- spTransform(country.cut, CRS(proj4string(landmask20km)))
landmask20km$suborder.i <- as.integer(landmask20km$suborder)
TAXOUSDA <- as.data.frame(landmask20km["suborder"])
tbl <- merge(TAXOUSDA, soil.legends[["TAXOUSDA"]], all.x=TRUE, by.x="suborder", by.y="Group")
gridded(tbl) <- ~ x+y
par(mar=c(0,0,0,0), oma=c(0,0,0,0))
#pal = grey(c(rev(seq(0,0.97,1/length(levels(landmask20km$suborder))))))
#pal = runif(length(levels(landmask20km$suborder)))
#image(raster(landmask20km["suborder.i"]), col=pal, axes=FALSE, xlab="", ylab="", asp=1)
#lines(country.rob, col="red")
pal = merge(data.frame(Generic=levels(tbl$Generic)), soil.legends[["TAXOUSDA"]][,c("Generic","COLOR")], all.y=FALSE)
pal[pal$Generic=="Ocean","COLOR"] <- "#B8D3FF"
spplot(tbl["Generic"], col.regions=pal$COLOR[!duplicated(pal$Generic)], xlab="", ylab="", sp.layout=list("sp.lines", country.rob, col="black"), ylim=c(-7700000,7600000))



x <- sort(table(landmask20km$suborder), decreasing = TRUE)[-(1:2)]
names.arg = attr(x, "dimnames")[[1]]
par(las=2, mar=c(5.5,4.0,0.5,0.5))
barplot(x, main = "", cex.axis=.8, cex=.8)

download.file("http://worldgrids.org/lib/exe/fetch.php?media=lammod0a.tif.gz", "lammod0a.tif.gz")
system("7za e lammod0a.tif.gz")
lam <- raster("lammod0a.tif")
lam.rob <- gdalwarp(lam, proj4s=proj4string(landmask20km), GridTopology=landmask20km@grid, pixsize=20000)
data(SAGA_pal)
greens = SAGA_pal[["SG_COLORS_YELLOW_GREEN"]]
par(mar=c(0,0,0,0), oma=c(0,0,0,0))
landmask20km$lam <- readGDAL("LAMMOD0a_ll.tif")$band1
landmask20km$lam <- ifelse(is.na(landmask20km$mask)|landmask20km$lam>100, NA, landmask20km$lam)
image(raster(landmask20km["lam"]), col=greens, axes=FALSE, xlab="", ylab="", asp=1)
lines(country.rob, col="red")