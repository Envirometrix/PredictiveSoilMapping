## ------------------------------------------------------------------------
library(plotKML)
library(sp)
library(randomForest)
library(nnet)
library(e1071)
library(GSIF)
library(plyr)
library(raster)
library(caret)
library(Cubist)
library(GSIF)
library(xgboost)
library(viridis)

## ---- include=FALSE------------------------------------------------------
h2o::h2o.no_progress()

## ------------------------------------------------------------------------
library(plotKML)
data(eberg)
data(eberg_grid)
coordinates(eberg) <- ~X+Y
proj4string(eberg) <- CRS("+init=epsg:31467")
gridded(eberg_grid) <- ~x+y
proj4string(eberg_grid) <- CRS("+init=epsg:31467")

## ------------------------------------------------------------------------
eberg_spc <- spc(eberg_grid, ~ PRMGEO6+DEMSRT6+TWISRT6+TIRAST6)
eberg_grid@data <- cbind(eberg_grid@data, eberg_spc@predicted@data)

## ------------------------------------------------------------------------
ov <- over(eberg, eberg_grid)
m <- cbind(ov, eberg@data)
dim(m)

## ------------------------------------------------------------------------
xg <- summary(m$TAXGRSC, maxsum=(1+length(levels(m$TAXGRSC))))
str(xg)
selg.levs <- attr(xg, "names")[xg > 5]
attr(xg, "names")[xg <= 5]

## ------------------------------------------------------------------------
m$soiltype <- m$TAXGRSC
m$soiltype[which(!m$TAXGRSC %in% selg.levs)] <- NA
m$soiltype <- droplevels(m$soiltype)
str(summary(m$soiltype, maxsum=length(levels(m$soiltype))))

## ------------------------------------------------------------------------
m <- m[complete.cases(m[,1:(ncol(eberg_grid)+2)]),]
m$soiltype <- as.factor(m$soiltype)
summary(m$soiltype)

## ------------------------------------------------------------------------
## subset to speed-up:
s <- sample.int(nrow(m), 500)
TAXGRSC.rf <- randomForest(x=m[-s,paste0("PC",1:10)], y=m$soiltype[-s],
                           xtest=m[s,paste0("PC",1:10)], ytest=m$soiltype[s])
## accuracy:
TAXGRSC.rf$test$confusion[,"class.error"]

## ------------------------------------------------------------------------
TAXGRSC.rf <- randomForest(x=m[,paste0("PC",1:10)], y=m$soiltype)
fm <- as.formula(paste("soiltype~", paste(paste0("PC",1:10), collapse="+")))
TAXGRSC.mn <- nnet::multinom(fm, m)
TAXGRSC.svm <- e1071::svm(fm, m, probability=TRUE, cross=5)
TAXGRSC.svm$tot.accuracy

## ------------------------------------------------------------------------
probs1 <- predict(TAXGRSC.mn, eberg_grid@data, type="probs", na.action = na.pass) 
probs2 <- predict(TAXGRSC.rf, eberg_grid@data, type="prob", na.action = na.pass)
probs3 <- attr(predict(TAXGRSC.svm, eberg_grid@data, 
                       probability=TRUE, na.action = na.pass), "probabilities")

## ------------------------------------------------------------------------
leg <- levels(m$soiltype)
lt <- list(probs1[,leg], probs2[,leg], probs3[,leg])
probs <- Reduce("+", lt) / length(lt)
## copy and make new raster object:
eberg_soiltype <- eberg_grid
eberg_soiltype@data <- data.frame(probs)

## ------------------------------------------------------------------------
ch <- rowSums(eberg_soiltype@data)
summary(ch)

## ----plot-eberg-soiltype, echo=FALSE, fig.width=9, fig.cap="Predicted soil types for the Ebergotzen case study."----
plot(raster::stack(eberg_soiltype), col=SAGA_pal[[10]], zlim=c(0,1))

## ------------------------------------------------------------------------
eberg_soiltype$cl <- as.factor(apply(eberg_soiltype@data,1,which.max)) 
levels(eberg_soiltype$cl) = attr(probs, "dimnames")[[2]][as.integer(levels(eberg_soiltype$cl))]
summary(eberg_soiltype$cl)

## ---- message=FALSE------------------------------------------------------
library(h2o)
localH2O = h2o.init(startH2O=TRUE)

## ---- message=FALSE------------------------------------------------------
eberg.hex <- as.h2o(m, destination_frame = "eberg.hex")
eberg.grid <- as.h2o(eberg_grid@data, destination_frame = "eberg.grid")

## ------------------------------------------------------------------------
RF.m <- h2o.randomForest(y = which(names(m)=="SNDMHT_A"), 
                        x = which(names(m) %in% paste0("PC",1:10)), 
                        training_frame = eberg.hex, ntree = 50)
RF.m

## ------------------------------------------------------------------------
library(scales)
library(lattice)
SDN.pred <- as.data.frame(h2o.predict(RF.m, eberg.hex, na.action=na.pass))$predict
plt1 <- xyplot(m$SNDMHT_A ~ SDN.pred, asp=1, 
               par.settings=list(
                 plot.symbol = list(col=scales::alpha("black", 0.6), 
                 fill=scales::alpha("red", 0.6), pch=21, cex=0.8)),
                 ylab="measured", xlab="predicted (machine learning)")

## ----obs-pred-snd, echo=FALSE, fig.cap="Measured vs predicted sand content based on the Random Forest model.", out.width="55%"----
knitr::include_graphics("figures/Measured_vs_predicted_SAND_plot.png")

## ------------------------------------------------------------------------
eberg_grid$RFx <- as.data.frame(h2o.predict(RF.m, eberg.grid, na.action=na.pass))$predict

## ----map-snd, echo=FALSE, fig.width=8, fig.cap="Predicted sand content based on random forest."----
plot(raster(eberg_grid["RFx"]), col=rev(viridis(10)), zlim=c(10,90))
points(eberg, pch=21, cex=.7)

## ------------------------------------------------------------------------
DL.m <- h2o.deeplearning(y = which(names(m)=="SNDMHT_A"), 
                         x = which(names(m) %in% paste0("PC",1:10)), 
                         training_frame = eberg.hex)
DL.m

## ------------------------------------------------------------------------
## predictions:
eberg_grid$DLx <- as.data.frame(h2o.predict(DL.m, eberg.grid, na.action=na.pass))$predict

## ----map-snd-dl, echo=FALSE, fig.width=8, fig.cap="Predicted sand content based on deep learning."----
plot(raster(eberg_grid["DLx"]), col=rev(viridis(10)), zlim=c(10,90))
points(eberg, pch=21, cex=.7)

## ------------------------------------------------------------------------
rf.R2 <- RF.m@model$training_metrics@metrics$r2
dl.R2 <- DL.m@model$training_metrics@metrics$r2
eberg_grid$SNDMHT_A <- rowSums(cbind(eberg_grid$RFx*rf.R2, 
                         eberg_grid$DLx*dl.R2), na.rm=TRUE)/(rf.R2+dl.R2)

## ----map-snd-ensemble, echo=FALSE, fig.width=8, out.width="80%", fig.cap="Predicted sand content based on ensemble predictions."----
plot(raster(eberg_grid["SNDMHT_A"]), col=rev(viridis(10)), zlim=c(10,90))
points(eberg, pch=21, cex=.7)

## ------------------------------------------------------------------------
data(edgeroi)
edgeroi.sp <- edgeroi$sites
coordinates(edgeroi.sp) <- ~ LONGDA94 + LATGDA94
proj4string(edgeroi.sp) <- CRS("+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs")
edgeroi.sp <- spTransform(edgeroi.sp, CRS("+init=epsg:28355"))
load("extdata/edgeroi.grids.rda")
gridded(edgeroi.grids) <- ~x+y
proj4string(edgeroi.grids) <- CRS("+init=epsg:28355")

## ------------------------------------------------------------------------
ov2 <- over(edgeroi.sp, edgeroi.grids)
ov2$SOURCEID <- edgeroi.sp$SOURCEID
str(ov2)

## ------------------------------------------------------------------------
## Convert soil horizon data to x,y,d regression matrix for 3D modeling:
hor2xyd <- function(x, U="UHDICM", L="LHDICM", treshold.T=15){
  x$DEPTH <- x[,U] + (x[,L] - x[,U])/2
  x$THICK <- x[,L] - x[,U]
  sel <- x$THICK < treshold.T
  ## begin and end of the horizon:
  x1 <- x[!sel,]; x1$DEPTH = x1[,L]
  x2 <- x[!sel,]; x2$DEPTH = x1[,U]
  y <- do.call(rbind, list(x, x1, x2))
  return(y)
}

## ----hor-3d-scheme, echo=FALSE, fig.cap="Training points assigned to a soil profile with 3 horizons. Using the function from above, we assign a total of 7 training points i.e. about 2 times more training points than there are horizons.", out.width="75%"----
knitr::include_graphics("figures/horizon_depths_for_3d_modeling_scheme.png")

## ------------------------------------------------------------------------
h2 <- hor2xyd(edgeroi$horizons)
## regression matrix:
m2 <- plyr::join_all(dfs = list(edgeroi$sites, h2, ov2))
## spatial prediction model:
formulaStringP2 <- ORCDRC ~ DEMSRT5+TWISRT5+PMTGEO5+
                            EV1MOD5+EV2MOD5+EV3MOD5+DEPTH
mP2 <- m2[complete.cases(m2[,all.vars(formulaStringP2)]),]

## ------------------------------------------------------------------------
library(caret)
ctrl <- trainControl(method="repeatedcv", number=5, repeats=1)
sel <- sample.int(nrow(mP2), 500)
tr.ORCDRC.rf <- train(formulaStringP2, data=mP2[sel,], 
                      method = "rf", trControl = ctrl, tuneLength = 3)
tr.ORCDRC.rf

## ------------------------------------------------------------------------
ORCDRC.rf <- train(formulaStringP2, data=mP2, 
                   method = "rf", tuneGrid=data.frame(mtry=7),
                   trControl=trainControl(method="none"))
w1 <- 100*max(tr.ORCDRC.rf$results$Rsquared)

## ----varimp-plot-edgeroi, echo=FALSE, fig.cap="Variable importance plot for predicting soil organic carbon content (ORC) in 3D.", out.width="70%"----
varImpPlot(ORCDRC.rf$finalModel, cex.axis = .7, cex.main = .7, cex.lab = .7)

## ------------------------------------------------------------------------
tr.ORCDRC.cb <- train(formulaStringP2, data=mP2[sel,], 
                      method = "cubist", trControl = ctrl, tuneLength = 3)
ORCDRC.cb <- train(formulaStringP2, data=mP2, 
                   method = "cubist", 
                   tuneGrid=data.frame(committees = 1, neighbors = 0),
                   trControl=trainControl(method="none"))
w2 <- 100*max(tr.ORCDRC.cb$results$Rsquared)
## "XGBoost" package:
ORCDRC.gb <- train(formulaStringP2, data=mP2, method = "xgbTree", trControl=ctrl)
w3 <- 100*max(ORCDRC.gb$results$Rsquared)
c(w1, w2, w3)

## ------------------------------------------------------------------------
edgeroi.grids$DEPTH <- 2.5
edgeroi.grids$Random_forest <- predict(ORCDRC.rf, edgeroi.grids@data, 
                                       na.action = na.pass) 
edgeroi.grids$Cubist <- predict(ORCDRC.cb, edgeroi.grids@data, na.action = na.pass)
edgeroi.grids$XGBoost <- predict(ORCDRC.gb, edgeroi.grids@data, na.action = na.pass)
edgeroi.grids$ORCDRC_5cm <- (edgeroi.grids$Random_forest*w1 + 
                               edgeroi.grids$Cubist*w2 + 
                               edgeroi.grids$XGBoost*w3)/(w1+w2+w3)

## ----maps-soc-edgeroi, echo=FALSE, fig.width=7, out.width="80%", fig.cap="Comparison of three MLA's and final ensemble prediction (ORCDRC 5cm) of soil organic carbon content for 2.5 cm depth."----
plot(stack(edgeroi.grids[c("Random_forest","Cubist","XGBoost","ORCDRC_5cm")]), col=rev(viridis(10)), zlim=c(5,65))

## ------------------------------------------------------------------------
source_https <- function(url, ...) {
  require(RCurl)
  if(!file.exists(paste0("R/", basename(url)))){
    cat(getURL(url, followlocation = TRUE,
               cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl")), 
        file = paste0("R/", basename(url)))
  }
  source(paste0("R/", basename(url)))
}
wdir = "https://raw.githubusercontent.com/ISRICWorldSoil/SoilGrids250m/"
source_https(paste0(wdir, "master/grids/cv/cv_functions.R"))

## ------------------------------------------------------------------------
mP2$SOURCEID = paste(mP2$SOURCEID)
test.ORC <- cv_numeric(formulaStringP2, rmatrix=mP2, 
                       nfold=5, idcol="SOURCEID", Log=TRUE)
str(test.ORC)

## ------------------------------------------------------------------------
plt0 <- xyplot(test.ORC[[1]]$Observed ~ test.ORC[[1]]$Predicted, asp=1, 
            par.settings = list(plot.symbol = list(col=scales::alpha("black", 0.6), fill=scales::alpha("red", 0.6), pch=21, cex=0.6)), 
            scales = list(x=list(log=TRUE, equispaced.log=FALSE), y=list(log=TRUE, equispaced.log=FALSE)),
            ylab="measured", xlab="predicted (machine learning)")

## ----plot-measured-predicted, echo=FALSE, fig.cap="Predicted vs observed plot for soil organic carbon ML-based model (Edgeroi data set).", out.width="55%"----
knitr::include_graphics("figures/Predicted_vs_observed_plot_for_SOC_edgeroi.png")

## ---- echo=FALSE---------------------------------------------------------
## download from: http://h2o-release.s3.amazonaws.com/h2o/latest_stable.html
library(h2o)
#devtools::install_github("h2oai/h2o-3/h2o-r/ensemble/h2oEnsemble-package")
library(h2oEnsemble)

## ---- message=FALSE------------------------------------------------------
k.f = dismo::kfold(mP2, k=4)
summary(as.factor(k.f))
## split data into training and validation:
edgeroi_v.hex = as.h2o(mP2[k.f==1,], destination_frame = "eberg_v.hex")
edgeroi_t.hex = as.h2o(mP2[!k.f==1,], destination_frame = "eberg_t.hex")
learner <- c("h2o.randomForest.wrapper", "h2o.gbm.wrapper")
fit <- h2o.ensemble(x = which(names(m2) %in% all.vars(formulaStringP2)[-1]), 
                    y = which(names(m2)=="ORCDRC"), 
                    training_frame = edgeroi_t.hex, learner = learner, 
                    cvControl = list(V = 5))
perf <- h2o.ensemble_performance(fit, newdata = edgeroi_v.hex)
perf

## ------------------------------------------------------------------------
data(cookfarm)
cookfarm.hor <- cookfarm$profiles
str(cookfarm.hor)
cookfarm.hor$depth <- cookfarm.hor$UHDICM +
  (cookfarm.hor$LHDICM - cookfarm.hor$UHDICM)/2
sel.id <- !duplicated(cookfarm.hor$SOURCEID)
cookfarm.xy <- cookfarm.hor[sel.id,c("SOURCEID","Easting","Northing")]
str(cookfarm.xy)
coordinates(cookfarm.xy) <- ~ Easting + Northing
grid10m <- cookfarm$grids
coordinates(grid10m) <- ~ x + y
gridded(grid10m) = TRUE
ov.cf <- over(cookfarm.xy, grid10m)
rm.cookfarm <- plyr::join(cookfarm.hor, cbind(cookfarm.xy@data, ov.cf))

## ------------------------------------------------------------------------
fm.PHI <- PHIHOX~DEM+TWI+NDRE.M+Cook_fall_ECa+Cook_spr_ECa+depth
rc <- complete.cases(rm.cookfarm[,all.vars(fm.PHI)])
mP3 <- rm.cookfarm[rc,all.vars(fm.PHI)]
str(mP3)

## ---- message=FALSE------------------------------------------------------
k.f3 <- dismo::kfold(mP3, k=4)
## split data into training and validation:
cookfarm_v.hex <- as.h2o(mP3[k.f3==1,], destination_frame = "cookfarm_v.hex")
cookfarm_t.hex <- as.h2o(mP3[!k.f3==1,], destination_frame = "cookfarm_t.hex")
learner3 = c("h2o.glm.wrapper", "h2o.randomForest.wrapper",
            "h2o.gbm.wrapper", "h2o.deeplearning.wrapper")
fit3 <- h2o.ensemble(x = which(names(mP3) %in% all.vars(fm.PHI)[-1]), 
                    y = which(names(mP3)=="PHIHOX"), 
                    training_frame = cookfarm_t.hex, learner = learner3, 
                    cvControl = list(V = 5))
perf3 <- h2o.ensemble_performance(fit3, newdata = cookfarm_v.hex)
perf3

## ---- message=FALSE------------------------------------------------------
h2o.shutdown()

## ------------------------------------------------------------------------
library(SuperLearner)
# List available models:
listWrappers()

## ------------------------------------------------------------------------
## detach snowfall package otherwise possible conflicts
#detach("package:snowfall", unload=TRUE)
library(parallel)
sl.l = c("SL.mean", "SL.xgboost", "SL.ksvm", "SL.glmnet", "SL.ranger")
cl <- parallel::makeCluster(detectCores())
x <- parallel::clusterEvalQ(cl, library(SuperLearner))
sl <- snowSuperLearner(Y = mP3$PHIHOX, 
                       X = mP3[,all.vars(fm.PHI)[-1]],
                       cluster = cl, 
                       SL.library = sl.l)
sl

## ------------------------------------------------------------------------
sl.l2 = c("SL.xgboost", "SL.ranger", "SL.ksvm")
sl2 <- snowSuperLearner(Y = mP3$PHIHOX, 
                       X = mP3[,all.vars(fm.PHI)[-1]],
                       cluster = cl, 
                       SL.library = sl.l2)
sl2

## ------------------------------------------------------------------------
str(rm.cookfarm$SOURCEID)
cv_sl <- CV.SuperLearner(Y = mP3$PHIHOX, 
                       X = mP3[,all.vars(fm.PHI)[-1]],
                       parallel = cl, 
                       SL.library = sl.l2, 
                       V=5, id=rm.cookfarm$SOURCEID[rc], 
                       verbose=TRUE)
summary(cv_sl)

## ------------------------------------------------------------------------
sl2 <- snowSuperLearner(Y = mP3$PHIHOX, 
                       X = mP3[,all.vars(fm.PHI)[-1]],
                       cluster = cl, 
                       SL.library = sl.l2,
                       id=rm.cookfarm$SOURCEID[rc],
                       cvControl=list(V=5))
sl2
new.data <- grid10m@data
pred.PHI <- list(NULL)
depths = c(10,30,50,70,90)
for(j in 1:length(depths)){
  new.data$depth = depths[j]
  pred.PHI[[j]] <- predict(sl2, new.data[,sl2$varNames])
}
str(pred.PHI[[1]])

## ----ph-cookfarm, echo=TRUE, fig.width=8, fig.cap="Predicted soil pH using 3D ensemble model."----
for(j in 1:length(depths)){
  grid10m@data[,paste0("PHI.", depths[j],"cm")] <- pred.PHI[[j]]$pred[,1]
}
spplot(grid10m, paste0("PHI.", depths,"cm"), 
       col.regions=R_pal[["pH_pal"]], as.table=TRUE)

## ----ph-cookfarm-var, echo=TRUE, fig.width=7, out.width="75%", fig.cap="Example of variance of prediction models for soil pH."----
library(matrixStats)
grid10m$PHI.10cm.sd <- rowSds(pred.PHI[[1]]$library.predict, na.rm=TRUE)
pts = list("sp.points", cookfarm.xy, pch="+", col="black", cex=1.4)
spplot(grid10m, "PHI.10cm.sd", sp.layout = list(pts), col.regions=rev(bpy.colors()))

## ------------------------------------------------------------------------
stopCluster(cl)

## ----distances-examples, echo=FALSE, fig.cap="Examples of distance maps to some location in space (yellow dot) based on different derivation algorithms: (a) simple Euclidean distances, (b) complex speed-based distances based on the gdistance package and Digital Elevation Model (DEM), and (c) upslope area derived based on the DEM in SAGA GIS. Image source: Hengl et al. (2018) doi: 10.7717/peerj.5518.", out.width="100%"----
knitr::include_graphics("figures/Fig_distances_examples.png")

## ---- eval=FALSE, echo=TRUE----------------------------------------------
## if(!require(ranger)){ devtools::install_github("imbs-hl/ranger") }

## ---- echo=TRUE----------------------------------------------------------
library(GSIF)
library(rgdal)
library(raster)
library(geoR)
library(ranger)

## ---- echo=FALSE, warning=FALSE------------------------------------------
library(gstat)
library(plyr)
library(plotKML)
library(scales)
library(parallel)
library(lattice)
library(gridExtra)

## ----meuse---------------------------------------------------------------
demo(meuse, echo=FALSE)

## ----bufferdist----------------------------------------------------------
grid.dist0 <- GSIF::buffer.dist(meuse["zinc"], meuse.grid[1], as.factor(1:nrow(meuse)))

## ------------------------------------------------------------------------
dn0 <- paste(names(grid.dist0), collapse="+")
fm0 <- as.formula(paste("zinc ~ ", dn0))
fm0

## ------------------------------------------------------------------------
ov.zinc <- over(meuse["zinc"], grid.dist0)
rm.zinc <- cbind(meuse@data["zinc"], ov.zinc)

## ------------------------------------------------------------------------
m.zinc <- ranger(fm0, rm.zinc, quantreg=TRUE, num.trees=150, seed=1)
m.zinc

## ------------------------------------------------------------------------
q <- c((1-.682)/2, 0.5, 1-(1-.682)/2)
zinc.rfd <- predict(m.zinc, grid.dist0@data, 
                    type="quantiles", quantiles=q)$predictions
str(zinc.rfd)

## ------------------------------------------------------------------------
meuse.grid$zinc_rfd = zinc.rfd[,2]
meuse.grid$zinc_rfd_range = (zinc.rfd[,3]-zinc.rfd[,1])/2

## ------------------------------------------------------------------------
zinc.geo <- as.geodata(meuse["zinc"])
ini.v <- c(var(log1p(zinc.geo$data)),500)
zinc.vgm <- likfit(zinc.geo, lambda=0, ini=ini.v, cov.model="exponential")
zinc.vgm

## ------------------------------------------------------------------------
locs <- meuse.grid@coords
zinc.ok <- krige.conv(zinc.geo, locations=locs, krige=krige.control(obj.model=zinc.vgm))
meuse.grid$zinc_ok <- zinc.ok$predict
meuse.grid$zinc_ok_range <- sqrt(zinc.ok$krige.var)

## ----comparison-OK-RF-zinc-meuse, echo=FALSE, dpi = 300, fig.cap="Comparison of predictions based on ordinary kriging as implemented in the geoR package (left) and random forest (right) for Zinc concentrations, Meuse data set: (first row) predicted concentrations in log-scale and (second row) standard deviation of the prediction errors for OK and RF methods. Image source: Hengl et al. (2018) doi: 10.7717/peerj.5518.", out.width="100%"----
knitr::include_graphics("figures/Fig_comparison_OK_RF_zinc_meuse.png")

## ------------------------------------------------------------------------
f1 = "extdata/Meuse_GlobalSurfaceWater_occurrence.tif"
f2 = "extdata/ahn.asc"
meuse.grid$SW_occurrence <- readGDAL(f1)$band1[meuse.grid@grid.index]
meuse.grid$AHN = readGDAL(f2)$band1[meuse.grid@grid.index]

## ------------------------------------------------------------------------
grids.spc <- GSIF::spc(meuse.grid, as.formula("~ SW_occurrence + AHN + ffreq + dist"))

## ------------------------------------------------------------------------
nms <- paste(names(grids.spc@predicted), collapse = "+")
fm1 <- as.formula(paste("zinc ~ ", dn0, " + ", nms))
fm1
ov.zinc1 <- over(meuse["zinc"], grids.spc@predicted)
rm.zinc1 <- do.call(cbind, list(meuse@data["zinc"], ov.zinc, ov.zinc1))

## ------------------------------------------------------------------------
m1.zinc <- ranger(fm1, rm.zinc1, importance="impurity", 
                  quantreg=TRUE, num.trees=150, seed=1)
m1.zinc

## ----rf-variableImportance, fig.width=5, out.width="80%", fig.cap="Variable importance plot for mapping zinc content based on the Meuse data set."----
xl <- as.list(ranger::importance(m1.zinc))
par(mfrow=c(1,1),oma=c(0.7,2,0,1), mar=c(4,3.5,1,0))
plot(vv <- t(data.frame(xl[order(unlist(xl), decreasing=TRUE)[10:1]])), 1:10, 
     type = "n", ylab = "", yaxt = "n", xlab = "Variable Importance (Node Impurity)",
     cex.axis = .7, cex.main = .7, cex.lab = .7)
abline(h = 1:10, lty = "dotted", col = "grey60")
points(vv, 1:10)
axis(2, 1:10, labels = dimnames(vv)[[1]], las = 2)

## ------------------------------------------------------------------------
zinc.geo$covariate = ov.zinc1
sic.t = ~ PC1 + PC2 + PC3 + PC4 + PC5
zinc1.vgm <- likfit(zinc.geo, trend = sic.t, lambda=0,
                    ini=ini.v, cov.model="exponential")
zinc1.vgm

## ------------------------------------------------------------------------
KC = krige.control(trend.d = sic.t, 
                   trend.l = ~ grids.spc@predicted$PC1 + 
                     grids.spc@predicted$PC2 + grids.spc@predicted$PC3 + 
                     grids.spc@predicted$PC4 + grids.spc@predicted$PC5, 
                   obj.model = zinc1.vgm)
zinc.uk <- krige.conv(zinc.geo, locations=locs, krige=KC)
meuse.grid$zinc_UK = zinc.uk$predict

## ----RF-covs-bufferdist-zinc-meuse, echo=FALSE, dpi = 300, fig.cap="Comparison of predictions (median values) produced using random forest and covariates only (left), and random forest with combined covariates and buffer distances (right).", out.width="80%"----
knitr::include_graphics("figures/Fig_RF_covs_bufferdist_zinc_meuse.png")

## ------------------------------------------------------------------------
meuse@data = cbind(meuse@data, data.frame(model.matrix(~soil-1, meuse@data)))
summary(as.factor(meuse$soil1))

## ------------------------------------------------------------------------
fm.s1 <- as.formula(paste("soil1 ~ ", paste(names(grid.dist0), collapse="+"), 
                         " + SW_occurrence + dist"))
rm.s1 <- do.call(cbind, list(meuse@data["soil1"], 
                             over(meuse["soil1"], meuse.grid), 
                             over(meuse["soil1"], grid.dist0)))
m1.s1 <- ranger(fm.s1, rm.s1, mtry=22, num.trees=150, seed=1, quantreg=TRUE)
m1.s1

## ------------------------------------------------------------------------
fm.s1c <- as.formula(paste("soil1c ~ ", 
                           paste(names(grid.dist0), collapse="+"), 
                           " + SW_occurrence + dist"))
rm.s1$soil1c = as.factor(rm.s1$soil1)
m2.s1 <- ranger(fm.s1c, rm.s1, mtry=22, num.trees=150, seed=1, 
                probability=TRUE, keep.inbag=TRUE)
m2.s1

## ------------------------------------------------------------------------
pred.regr <- predict(m1.s1, cbind(meuse.grid@data, grid.dist0@data), type="response")
pred.clas <- predict(m2.s1, cbind(meuse.grid@data, grid.dist0@data), type="se")

## ----comparison-uncertainty-Binomial, echo=FALSE, dpi=300, fig.cap="Comparison of predictions for soil class “1” produced using (left) regression and prediction of the median value, (middle) regression and prediction of response value, and (right) classification with probabilities.", out.width="90%"----
knitr::include_graphics("figures/Fig_comparison_uncertainty_Binomial_variables_meuse.png")

## ------------------------------------------------------------------------
fm.s = as.formula(paste("soil ~ ", paste(names(grid.dist0), collapse="+"), 
                        " + SW_occurrence + dist"))
fm.s

## ------------------------------------------------------------------------
rm.s <- do.call(cbind, list(meuse@data["soil"], 
                            over(meuse["soil"], meuse.grid), 
                            over(meuse["soil"], grid.dist0)))
m.s <- ranger(fm.s, rm.s, mtry=22, num.trees=150, seed=1, 
              probability=TRUE, keep.inbag=TRUE)
m.s

## ------------------------------------------------------------------------
m.s0 <- ranger(fm.s, rm.s, mtry=22, num.trees=150, seed=1)
m.s0

## ------------------------------------------------------------------------
pred.soil_rfc = predict(m.s, cbind(meuse.grid@data, grid.dist0@data), type="se")
pred.grids = meuse.grid["soil"]
pred.grids@data = do.call(cbind, list(pred.grids@data, 
                                      data.frame(pred.soil_rfc$predictions),
                                      data.frame(pred.soil_rfc$se)))
names(pred.grids) = c("soil", paste0("pred_soil", 1:3), paste0("se_soil", 1:3))
str(pred.grids@data)

## ----comparison-uncertainty-Factor, echo=FALSE, dpi=300, fig.cap="Predictions of soil types for the meuse data set based on the RFsp: (above) probability for three soil classes, and (below) derived standard errors per class.", out.width="90%"----
knitr::include_graphics("figures/Fig_comparison_uncertainty_Factor_variables_meuse.png")

