## ----carbon-density-plot, echo=FALSE, fig.cap="Correlation between soil organic carbon density and soil organic carbon content (displayed on a log-scale) created using a global compilations of soil profile data (WoSIS). Values 1, 2, 3, 4, 5 and 6 in the plot (log scale) correspond to values 2, 6, 19, 54, 147 and 402. Note that for ORC >12 percent, the OCD line flattens, which means that, organic carbon density practically stops to increase with the increase of ORC content.", out.width="55%"----
knitr::include_graphics("figures/rplot_soilcarbon_density_vs_orc.png")

## The average Organic Carbon Stock for the 0–100 cm depth interval for the land mask (148,940,000 km$^2$) is about 11 kg/m$^2$ or 110 tons/ha. The average soil Organic Carbon Density (OCD) is about 11 kg/m$^3$ (compared to the standard bulk density of fine earth of 1250 kg/m$^3$). Standard Organic Carbon Stock for 0–30 cm depth interval is 7 kg/m$^2$ i.e. the average OCD is about 13 kg/m$^3$.

## ----profile-edgeroi, echo=FALSE-----------------------------------------
knitr::kable(
  head(read.csv("extdata/profile_399_EDGEROI_ed079.csv", header = TRUE, stringsAsFactors = FALSE), 10), booktabs = TRUE,
  caption = 'Laboratory data for a profile 399 EDGEROI ed079 from Australia (Karssies 2011).'
)

## ------------------------------------------------------------------------
library(GSIF)
library(aqp)
library(sp)
library(plyr)
lon = 149.73; lat = -30.09; 
id = "399_EDGEROI_ed079"; TIMESTRR = "1987-01-05"
top = c(0, 10, 20, 55, 90) 
bottom = c(10, 20, 55, 90, 116)
ORC = c(8.2, 7.5, 6.1, 3.3, 1.6)
BLD = c(1340, 1367, 1382, 1433, 1465)
CRF = c(6, 6, 7, 8, 8)
#OCS = OCSKGM(ORC, BLD, CRF, HSIZE=bottom-top)
prof1 <- join(data.frame(id, top, bottom, ORC, BLD, CRF), 
               data.frame(id, lon, lat, TIMESTRR), type='inner')
depths(prof1) <- id ~ top + bottom
site(prof1) <- ~ lon + lat + TIMESTRR
coordinates(prof1) <- ~ lon + lat
proj4string(prof1) <- CRS("+proj=longlat +datum=WGS84")
ORC.s <- mpspline(prof1, var.name="ORC", d=t(c(0,30,100,200)), vhigh = 2200)
BLD.s <- mpspline(prof1, var.name="BLD", d=t(c(0,30,100,200)), vhigh = 2200)
CRF.s <- mpspline(prof1, var.name="CRF", d=t(c(0,30,100,200)), vhigh = 2200)

## ------------------------------------------------------------------------
OCSKGM(ORC.s$var.std$`0-30 cm`, 
       BLD.s$var.std$`0-30 cm`, 
       CRF.s$var.std$`0-30 cm`, HSIZE=30)

## ------------------------------------------------------------------------
OCSKGM(ORC.s$var.std$`30-100 cm`, 
       BLD.s$var.std$`30-100 cm`, 
       CRF.s$var.std$`30-100 cm`, HSIZE=70)

## Organic Carbon Stock for standard depths can be determined from legacy soil profile data either by fitting a spline function to organic carbon, bulk density values, or by aggregating data using simple conversion formulas. A standard mineral soil with 1–3% soil organic carbon for the 0–100 cm depth interval should have about 5–35 kg/m$^2$ or 50–350 tonnes/ha. An organic soil with >30% soil organic carbon may have as much as 60–90 kg/m$^2$ for the 0–100 cm depth interval.

## ----scheme-soc-prof1, echo=FALSE, fig.cap="Determination of soil organic carbon density and stock for standard depth intervals: example of a mineral soil profile from Australia.", out.width="80%"----
knitr::include_graphics("figures/fig_2_profiles_ocs_edgeroi.png")

## ----profile-can, echo=FALSE---------------------------------------------
knitr::kable(
  head(read.csv("extdata/profile_CAN_organic.csv", header = TRUE, stringsAsFactors = FALSE), 10), booktabs = TRUE,
  caption = 'Laboratory data for an organic soil profile from Canada  (Shaw, Bhatti, and Sabourin 2005).'
)

## ----scheme-soc-prof2, echo=FALSE, fig.cap="Determination of soil organic carbon density and stock for standard depth intervals: example of an organic soil profile from Canada.", out.width="80%"----
knitr::include_graphics("figures/fig_2_profiles_ocs_organic.png")

## ----scheme-profiles-ocs, echo=FALSE, fig.cap="Estimation of OCS values 0–30 cm using some typical soil profile data without fitting splines.", out.width="90%"----
knitr::include_graphics("figures/Fig_standard_soil_profiles_SOC_calc.png")

## ------------------------------------------------------------------------
dfs_tbl = readRDS("extdata/wosis_tbl.rds")
ind.tax = readRDS("extdata/ov_taxousda.rds")
library(ranger)
fm.BLD = as.formula(
  paste("BLD ~ ORCDRC + CLYPPT + SNDPPT + PHIHOX + DEPTH.f +", 
        paste(names(ind.tax), collapse="+")))
m.BLD_PTF <- ranger(fm.BLD, dfs_tbl, num.trees = 85, importance='impurity')
m.BLD_PTF

## ------------------------------------------------------------------------
ind.tax.new = ind.tax[which(ind.tax$TAXOUSDA84==1)[1],]
predict(m.BLD_PTF, cbind(data.frame(ORCDRC=11, 
                                    CLYPPT=22, 
                                    PHIHOX=6.5, 
                                    SNDPPT=35, 
                                    DEPTH.f=5), ind.tax.new))$predictions

## ------------------------------------------------------------------------
ind.tax.new = ind.tax[which(ind.tax$TAXOUSDA13==1)[1],]
predict(m.BLD_PTF, 
        cbind(data.frame(ORCDRC=320, CLYPPT=8, PHIHOX=5.5, 
                         SNDPPT=45, DEPTH.f=10), ind.tax.new))$predictions

## ------------------------------------------------------------------------
m.BLD_ls = loess(BLD ~ ORCDRC, dfs_tbl, span=1/18)
predict(m.BLD_ls, data.frame(ORCDRC=320))

## Soil Bulk density (BLD) is an important soil property that is required to estimate stocks of nutrients especially soil organic carbon. Measurements of BLD are often not available and need to be estimated using some PTF or similar. Most PTF's for BLD are based on correlating BLD with soil organic carbon, clay and sand content, pH, soil type and climate zone.

## ----plot-bld-soc, echo=FALSE, fig.cap="Correlation plot between soil organic carbon density and bulk density (fine earth), created using the global compilations of soil profile data (http://www.isric.org/content/wosis-data-sets). Black line indicates fitted loess polynomial surface (stats::loess). There is still quite some scatter around the fitted line: many combinations of BLD and ORC, that do not fall close to the correlation line, can still be observed.", out.width="60%"----
knitr::include_graphics("figures/rplot_bulk_dens_function_of_soc.png")

## ----soc-depth-plot, echo=FALSE, fig.cap="Globally fitted regression model for predicting soil organic carbon using depth only (log-log regression) and (a) individual soil profile from the ISRIC soil monolith collection. Image source: Hengl et al. (2014) doi: 10.1371/journal.pone.0105992.", out.width="90%"----
knitr::include_graphics("figures/journal_pone_0105992_g005.png")

## Soil Organic Carbon stock can be mapped by using at least three different approaches: (1) the 2D approach where estimation of OCS is done at the site level, (2) the 3D approach where soil organic carbon content, bulk density and coarse fragments are mapped separately, then used to derive OCS for standard depths at each grid cell, and (3) the 3D approach based on mapping Organic Carbon Density, then converting to stocks.

## ----ocs-three-approaches, echo=FALSE, fig.cap="Three main computational paths (2D and 3D) to producing maps of organic carbon stock.", out.width="90%"----
knitr::include_graphics("figures/fig_derivation_socs_scheme.png")

## ------------------------------------------------------------------------
load("extdata/COSha10.rda")
load("extdata/COSha30.rda")
str(COSha30)

## ------------------------------------------------------------------------
load("extdata/COSha30map.rda")
proj4string(COSha30map) = "+proj=utm +zone=18 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
str(COSha30map@data)

## ----libertad-soc, echo=FALSE, fig.cap="Example of a data set with OCS samples (for 2D prediction). Case study in Colombia available via the geospt package (https://cran.r-project.org/package=geospt).", out.width="65%"----
knitr::include_graphics("figures/fig_la_libertad_research_center_socs.jpg")

## ---- warning=FALSE------------------------------------------------------
covs30m = readRDS("extdata/covs30m.rds")
proj4string(covs30m) = proj4string(COSha30map)
names(covs30m)

## ------------------------------------------------------------------------
proj4string(COSha30map) = "+proj=utm +zone=18 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
coordinates(COSha30) = ~ x+y
proj4string(COSha30) = proj4string(COSha30map)
covs30mdist = GSIF::buffer.dist(COSha30["COSha30"], covs30m[1],
                                as.factor(1:nrow(COSha30)))

## ------------------------------------------------------------------------
covs30m@data = cbind(covs30m@data, covs30mdist@data)
sel.rm = c("GlobalSurfaceWater_occurrence", "GlobalSurfaceWater_extent",
           "Landsat_bare2010", "COSha30map_var1pred_")
rr = which(names(covs30m@data) %in% sel.rm)
fm.spc = as.formula(paste(" ~ ", paste(names(covs30m)[-rr], collapse = "+")))
proj4string(covs30m) = proj4string(COSha30)
covs30m.spc = GSIF::spc(covs30m, fm.spc)
ov.COSha30 = cbind(as.data.frame(COSha30), over(COSha30, covs30m.spc@predicted))

## ------------------------------------------------------------------------
library(caret)
library(ranger)
fm.COSha30 = as.formula(paste("COSha30 ~ ",
                              paste(names(covs30m.spc@predicted), collapse = "+")))
fm.COSha30
rf.tuneGrid <- expand.grid(.mtry = seq(2, 60, by=5),
                           .splitrule = "maxstat",
                           .min.node.size = c(10, 20))
gb.tuneGrid <- expand.grid(eta = c(0.3,0.4), 
                           nrounds = c(50,100), 
                           max_depth = 2:3, gamma = 0, 
                           colsample_bytree = 0.8, 
                           min_child_weight = 1, subsample=1)
fitControl <- trainControl(method="repeatedcv", number=4, repeats=1)
mFit1 <- train(fm.COSha30, data=ov.COSha30, method="ranger", 
               trControl=fitControl, importance='impurity', 
               tuneGrid=rf.tuneGrid)
mFit1
mFit2 <- train(fm.COSha30, data=ov.COSha30, method="xgbTree", 
               trControl=fitControl, tuneGrid=gb.tuneGrid)
mFit2

## ----plot-cosha30map-rf, echo=FALSE, fig.width=7, out.width="75%", fig.cap="Comparison of predictions generated using ordinary kriging (left) and machine learning with the help of 30 m resolution covariates and buffer distances (right)."----
COSha30.pr = covs30m["COSha30map_var1pred_"]
COSha30.pr@data[,"COSha30map_RF"] = predict(mFit1, covs30m.spc@predicted@data)
spplot(COSha30.pr, col.regions=plotKML::SAGA_pal[[1]], 
       sp.layout = list("sp.points", COSha30, pch = "+", col="black", cex=1.5))

## ------------------------------------------------------------------------
mean(COSha30.pr$COSha30map_RF, na.rm=TRUE); mean(COSha30$COSha30, na.rm=TRUE)
## 48 tonnes/ha vs 51 tonnes / ha

## ------------------------------------------------------------------------
sum(COSha30.pr$COSha30map_RF*30^2/1e4, na.rm=TRUE)

## ------------------------------------------------------------------------
library(GSIF)
data(edgeroi)
edgeroi.sp = edgeroi$sites
coordinates(edgeroi.sp) <- ~ LONGDA94 + LATGDA94
proj4string(edgeroi.sp) <- CRS("+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs")
edgeroi.sp <- spTransform(edgeroi.sp, CRS("+init=epsg:28355"))

## ------------------------------------------------------------------------
load("extdata/edgeroi.grids.rda")
gridded(edgeroi.grids) <- ~x+y
proj4string(edgeroi.grids) <- CRS("+init=epsg:28355")
names(edgeroi.grids)

## ------------------------------------------------------------------------
edgeroi.spc = spc(edgeroi.grids, ~DEMSRT5+TWISRT5+PMTGEO5+EV1MOD5+EV2MOD5+EV3MOD5)

## ----edgeroi-overview, echo=FALSE, fig.cap="Edgeroi data set: locations of soil profiles and Australian soil classification codes. For more details see Malone et al. (2009).", out.width="100%"----
knitr::include_graphics("figures/edgeroi_overview.jpeg")

## ---- eval=FALSE---------------------------------------------------------
## landgis.bld = list.files("/mnt/DATA/LandGIS/predicted250m",
##                      pattern=glob2rx("sol_bulkdens.fineearth_usda.4a1h_m_*.tif$"),
##                      full.names=TRUE)
## for(j in 1:length(landgis.bld)){
##   system(paste0('gdalwarp ', landgis.bld[j], ' extdata/edgeroi_',
##                 basename(landgis.bld[j]), ' -t_srs \"', proj4string(edgeroi.grids),
##                 '\" -tr 250 250 -co \"COMPRESS=DEFLATE\"',
##                 ' -te ', paste(as.vector(edgeroi.grids@bbox), collapse = " ")))
## }

## ------------------------------------------------------------------------
sg <- list.files("extdata", "edgeroi_sol_bulkdens.fineearth", full.names = TRUE)
ov <- as.data.frame(raster::extract(stack(sg), edgeroi.sp)*10)
ov.edgeroi.BLD = ov[,c(grep("b0..", names(ov),
                            fixed = TRUE), grep("b10..", names(ov), fixed = TRUE), 
                       grep("b30..", names(ov), 
                            fixed = TRUE), grep("b60..", names(ov), fixed = TRUE), 
                       grep("b100..", names(ov), 
                            fixed = TRUE), grep("b200..", names(ov), fixed = TRUE))]

## ------------------------------------------------------------------------
ov.edgeroi.BLDm  <- data.frame(BLD.f = as.vector(sapply(2:ncol(ov.edgeroi.BLD),
                            function(i){rowMeans(ov.edgeroi.BLD[,c(i-1,i)])})),
                    DEPTH.c = as.vector(sapply(1:5, function(i){rep(paste0("sd",i),
                        nrow(edgeroi$sites))})), SOURCEID = rep(edgeroi$sites$SOURCEID, 5))
str(ov.edgeroi.BLDm)

## ------------------------------------------------------------------------
edgeroi$horizons$DEPTH = edgeroi$horizons$UHDICM +
  (edgeroi$horizons$LHDICM - edgeroi$horizons$UHDICM)/2
edgeroi$horizons$DEPTH.c = cut(edgeroi$horizons$DEPTH, include.lowest = TRUE,
                              breaks = c(0,10,30,60,100,1000), labels = paste0("sd",1:5))
summary(edgeroi$horizons$DEPTH.c)
edgeroi$horizons$BLD.f = plyr::join(edgeroi$horizons[,c("SOURCEID","DEPTH.c")],
                                    ov.edgeroi.BLDm)$BLD.f

## ------------------------------------------------------------------------
edgeroi$horizons$OCD = edgeroi$horizons$ORCDRC/1000 * edgeroi$horizons$BLD.f
summary(edgeroi$horizons$OCD)

## ---- echo=FALSE---------------------------------------------------------
leg = c("#0000ff", "#0028d7", "#0050af", "#007986", "#00a15e", "#00ca35", "#00f20d", 
        "#1aff00", "#43ff00", "#6bff00", "#94ff00", "#bcff00", "#e5ff00", "#fff200", 
        "#ffca00", "#ffa100", "#ff7900", "#ff5000", "#ff2800", "#ff0000")
hor2xyd = function(x, U="UHDICM", L="LHDICM", treshold.T=15){
  x$DEPTH <- x[,U] + (x[,L] - x[,U])/2
  x$THICK <- x[,L] - x[,U]
  sel = x$THICK < treshold.T
  ## begin and end of the horizon:
  x1 = x[!sel,]; x1$DEPTH = x1[,L]
  x2 = x[!sel,]; x2$DEPTH = x1[,U]
  y = do.call(rbind, list(x, x1, x2))
  return(y)
}

## ------------------------------------------------------------------------
ov2 <- over(edgeroi.sp, edgeroi.spc@predicted)
ov2$SOURCEID = edgeroi.sp$SOURCEID
h2 = hor2xyd(edgeroi$horizons)
m2 <- plyr::join_all(dfs = list(edgeroi$sites, h2, ov2))

## ------------------------------------------------------------------------
fm.OCD = as.formula(paste0("OCD ~ DEPTH + ", paste(names(edgeroi.spc@predicted), 
                                                   collapse = "+")))
fm.OCD
m.OCD <- ranger(fm.OCD, m2[complete.cases(m2[,all.vars(fm.OCD)]),], 
                quantreg = TRUE, importance = "impurity")
m.OCD

## ------------------------------------------------------------------------
for(i in c(0,30)){
   edgeroi.spc@predicted$DEPTH = i
   OCD.rf <- predict(m.OCD, edgeroi.spc@predicted@data)
   nm1 = paste0("OCD.", i, "cm")
   edgeroi.grids@data[,nm1] = OCD.rf$predictions
   OCD.qrf <- predict(m.OCD, edgeroi.spc@predicted@data, 
                      type="quantiles", quantiles=c((1-.682)/2, 1-(1-.682)/2))
   nm2 = paste0("OCD.", i, "cm_se")
   edgeroi.grids@data[,nm2] = (OCD.qrf$predictions[,2] - OCD.qrf$predictions[,1])/2
}

## ----plot-edgeroi-ocd, echo=FALSE, fig.width=9, out.width="90%", fig.cap="Predicted organic carbon stock for 0–30 cm depth and error map for the Edgeroi data set. All values expressed in tons/ha."----
library(raster)
edgeroi.grids$OCS.30cm = rowMeans(edgeroi.grids@data[,paste0("OCD.", c(0,30), "cm")]) * 0.3 * 10
summary(edgeroi.grids$OCS.30cm)
edgeroi.grids$OCS.30cm.f = ifelse(edgeroi.grids$OCS.30cm>76, 76, ifelse(edgeroi.grids$OCS.30cm<28, 28, edgeroi.grids$OCS.30cm))
## plot OCS 0-30 cm and the error map:
par(mfrow=c(1,2), oma=c(0,0,0,1), mar=c(0,0,3.5,1.5))
plot(raster(edgeroi.grids["OCS.30cm.f"]), col=leg, main=paste0("Organic carbon stock 0", "\U2012", "30 cm (t/ha)"), axes=FALSE, box=FALSE, zlim=c(28,76))
points(edgeroi.sp, pch=21, bg="white", cex=.8)
plot(raster(edgeroi.grids["OCD.30cm_se"])*0.3*10, col=rev(bpy.colors()), main="Standard prediction error (t/ha)", axes=FALSE, box=FALSE)
points(edgeroi.sp, pch=21, bg="white", cex=.8)

## ------------------------------------------------------------------------
library(rgdal)
edgeroi.grids$LandUse = readGDAL("extdata/edgeroi_LandUse.sdat")$band1
lu.leg = read.csv("extdata/LandUse.csv")
edgeroi.grids$LandUseClass = paste(join(data.frame(LandUse=edgeroi.grids$LandUse), 
                                        lu.leg, match="first")$LU_NSWDeta)
OCS_agg.lu <- plyr::ddply(edgeroi.grids@data, .(LandUseClass), summarize,
                          Total_OCS_kt=round(sum(OCS.30cm*250^2/1e4, na.rm=TRUE)/1e3),
                          Area_km2=round(sum(!is.na(OCS.30cm))*250^2/1e6))
OCS_agg.lu$LandUseClass.f = strtrim(OCS_agg.lu$LandUseClass, 34)
OCS_agg.lu$OCH_t_ha_M = round(OCS_agg.lu$Total_OCS_kt*1000/(OCS_agg.lu$Area_km2*100))
OCS_agg.lu[OCS_agg.lu$Area_km2>5,c("LandUseClass.f","Total_OCS_kt",
                                   "Area_km2","OCH_t_ha_M")]

## ------------------------------------------------------------------------
OCD_stN <- readRDS("extdata/usa48.OCD_spacetime_matrix.rds")
dim(OCD_stN)

## ----thist-usa48, fig.width=5.5, out.width="85%", fig.cap="Distribution of soil observations based on sampling year."----
hist(OCD_stN$YEAR, xlab="Year", main="", col="darkgrey", cex.axis = .7, cex.main = .7, cex.lab = .7)

## ---- eval=FALSE---------------------------------------------------------
## pr.lst <- names(OCD_stN)[-which(names(OCD_stN) %in% c("SOURCEID", "DEPTH.f", "OCDENS",
##                                                       "YEAR", "YEAR_c", "LONWGS84",
##                                                       "LATWGS84"))]
## fm0.st <- as.formula(paste('OCDENS ~ DEPTH.f + ', paste(pr.lst, collapse="+")))
## sel0.m = complete.cases(OCD_stN[,all.vars(fm0.st)])
## ## takes >2 mins
## rf0.OCD_st <- ranger(fm0.st, data=OCD_stN[sel0.m,all.vars(fm0.st)],
##                      importance="impurity", write.forest=TRUE, num.trees=120)

## ---- eval=FALSE---------------------------------------------------------
## xl <- as.list(ranger::importance(rf0.OCD_st))
## print(t(data.frame(xl[order(unlist(xl), decreasing=TRUE)[1:10]])))

## ----usa48-ocd-2014, echo=FALSE, fig.cap="Predicted OCD (in kg/cubic-m) at 10 cm depth for the year 2014. Blue colors indicate low values, red high values.", out.width="90%"----
knitr::include_graphics("figures/usa48_ocd_10cm_year2014.png")

## ----usa48-ocd-1925, echo=FALSE, fig.cap="Predicted OCD (in kg/cubic-m) at 10 cm depth for the year 1925.", out.width="90%"----
knitr::include_graphics("figures/usa48_ocd_10cm_year1925.png")

## ---- eval=FALSE---------------------------------------------------------
## library(greenbrown)
## library(raster)
## setwd()
## tif.lst <- list.files("extdata/USA48", pattern="_10km.tif", full.names = TRUE)
## g10km <- as(readGDAL(tif.lst[1]), "SpatialPixelsDataFrame")
## for(i in 2:length(tif.lst)){ g10km@data[,i] = readGDAL(tif.lst[i],
##                                                        silent=TRUE)$band1[g10km@grid.index] }
## names(g10km) = basename(tif.lst)
## g10km = as.data.frame(g10km)
## gridded(g10km) = ~x+y
## proj4string(g10km) = "+proj=longlat +datum=WGS84"

## ---- eval=FALSE---------------------------------------------------------
## library(maps)
## library(maptools)
## states <- map('state', plot=FALSE, fill=TRUE)
## states = SpatialPolygonsDataFrame(map2SpatialPolygons(states,
##                                                       IDs=1:length(states$names)),
##                                   data.frame(names=states$names))
## proj4string(states) = "+proj=longlat +datum=WGS84"
## ov.g10km = over(y=states, x=g10km)
## txg10km = g10km[which(ov.g10km$names=="texas"),]
## txg10km = as.data.frame(txg10km)
## gridded(txg10km) = ~x+y
## proj4string(txg10km) = "+proj=longlat +datum=WGS84"
## spplot(log1p(stack(txg10km)), col.regions=SAGA_pal[[1]])
## g10km.b = raster::brick(txg10km)

## ----time-series-texas, echo=FALSE, fig.cap="Time-series of predictions of organic carbon density for Texas.", out.width="100%"----
knitr::include_graphics("figures/rplot_timeseries_ocd_maps_texas.png")

## ---- eval=FALSE---------------------------------------------------------
## trendmap <- TrendRaster(g10km.b, start=c(1935, 1), freq=1, breaks=1)
## ## can be computationally intensive
## plot(trendmap[["SlopeSEG1"]],
##      col=rev(SAGA_pal[["SG_COLORS_GREEN_GREY_RED"]]),
##      zlim=c(-1.5,1.5), main="Slope SEG1")

## ----ocd-slope-texas, echo=FALSE, fig.cap="Predicted slope of change of soil organic carbon density for Texas for the period 1935–2014. Negative values indicate loss of soil organic carbon.", out.width="80%"----
knitr::include_graphics("figures/rplot_splope_ocd_change.png")

