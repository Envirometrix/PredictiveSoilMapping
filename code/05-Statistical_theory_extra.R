## Chapter: Spatial prediction of soil variables: concepts and methods

sessionInfo()
library(sp)
library(GSIF)
library(plotKML)
library(raster)
data(SAGA_pal)

# ------------------------------------------------------------
# Soil-depth functions and splines:
# ------------------------------------------------------------

library(GSIF)
library(aqp)
library(plyr)
library(sp)

## sample profile from Nigeria:
lon = 3.90; lat = 7.50; id = "ISRIC:NG0017"; FAO1988 = "LXp" 
top = c(0, 18, 36, 65, 87, 127) 
bottom = c(18, 36, 65, 87, 127, 181)
ORCDRC = c(18.4, 4.4, 3.6, 3.6, 3.2, 1.2)
munsell = c("7.5YR3/2", "7.5YR4/4", "2.5YR5/6", "5YR5/8", "5YR5/4", "10YR7/3")
## prepare a SoilProfileCollection:
prof1 <- join(data.frame(id, top, bottom, ORCDRC, munsell), 
         data.frame(id, lon, lat, FAO1988), type='inner') 
prof1$mdepth <- prof1$top+(prof1$bottom-prof1$top)/2
## fit a decay function:
d.lm <- glm(ORCDRC ~ log(mdepth), data=prof1, family=gaussian(log))
options(list(scipen=3, digits=2))
d.lm$fitted.values

## fit equal-area splines:
prof1.spc <- prof1
depths(prof1.spc) <- id ~ top + bottom
site(prof1.spc) <- ~ lon + lat + FAO1988 
coordinates(prof1.spc) <- ~ lon + lat
proj4string(prof1.spc) <- CRS("+proj=longlat +datum=WGS84")
## fit a spline:
ORCDRC.s <- mpspline(prof1.spc, var.name="ORCDRC")

# Measured and fitted horizons next to each other
## Fig_soil_depth_examples.pdf
par(mfrow=c(1,2))
plot(x=rbind(prof1$ORCDRC,prof1$ORCDRC), y=rbind(prof1$top, prof1$bottom), type="s", ylim=c(200,-10), xlab='', ylab='depth (cm)', xlim=c(0,22), col=grey(.2))  # main='Organic carbon (promilles)'
axis(at=rbind(prof1$ORCDRC,prof1$ORCDRC), labels=rbind(prof1$ORCDRC,prof1$ORCDRC), side=3)
mtext("Log-log model", side=3, line=3, cex.lab=1.5)
xl <- data.frame(cbind(rep(0, length(prof1$ORCDRC)), prof1$ORCDRC), cbind(prof1$top, prof1$top))
xl[length(xl[,1])+1,] <- c(0, prof1$ORCDRC[length(prof1$ORCDRC)], prof1$bottom[length(prof1$ORCDRC)], prof1$bottom[length(prof1$ORCDRC)])
for(i in 1:length(xl[,1])){
 lines(y=xl[i,3:4], x=xl[i,1:2], lty=5)
}
## fitted model:
xlc <- data.frame(mdepth=seq(xl[1,3], xl[length(xl[,1]),3], by=5))
lines(x=predict(d.lm, xlc, type="response"), y=xlc$mdepth, lty=6, lwd=2.5)

## second plot with spline fitted values:
plot(x=rbind(prof1$ORCDRC, prof1$ORCDRC), y=rbind(prof1$top, prof1$bottom), type="s", ylim=c(200,-10), xlab='', ylab='depth (cm)', xlim=c(0,22), col=grey(.2))
axis(at=rbind(prof1$ORCDRC, prof1$ORCDRC), labels=rbind(prof1$ORCDRC, prof1$ORCDRC), side=3)
mtext("Equal-area spline", side=3, line=3, cex.lab=1.5)
for(i in 1:length(xl[,1])){
  lines(y=xl[i,3:4], x=xl[i,1:2], lty=5)
}
lines(x=ORCDRC.s[["var.1cm"]][,1], y=1:200, lty=5, lwd=2.5)

# ------------------------------------------------------------
# Knowledge-driven mapping demo:
# ------------------------------------------------------------

data(volcano)
x=seq(from=2667405, length.out=61, by=10)
y=seq(from=6478705, length.out=87, by=10)
volcano.r <- expand.grid(x=x, y=y, KEEP.OUT.ATTRS=FALSE)
volcano.r$z <- as.vector(t(volcano)[61:1,])
coordinates(volcano.r) <- ~x+y
gridded(volcano.r) <- TRUE
fullgrid(volcano.r) <- TRUE
# spplot(volcano.r)
writeGDAL(volcano.r, "volcano.sdat", "SAGA")
# TWI:
rsaga.geoprocessor(lib="ta_hydrology", module=15, param=list(DEM="volcano.sgrd", C="catharea.sgrd", GN="catchslope.sgrd", CS="modcatharea.sgrd", SB="TWI.sgrd", T=10))
# valley depth:
rsaga.geoprocessor(lib="ta_morphometry", module=14, param=list(DEM="volcano.sgrd", HO="tmp.sgrd", HU="VDEPTH.sgrd", NH="tmp.sgrd", SH="tmp.sgrd", MS="tmp.sgrd", W=12, T=120, E=4))
volcano.r$TWI <- readGDAL("TWI.sdat")$band1
volcano.r$VDEPTH <- readGDAL("VDEPTH.sdat")$band1
str(volcano.r)
# volcano <- data.frame(volcano.r)

# transect:
t1 <- Line(matrix(c(2667705,2667545,6478875,6479544), ncol=2))
transects <- SpatialLines(list(Lines(list(t1), ID="t")), CRS(NA))
pts <- spsample(transects, n=80, type="regular")
pts.ov <- overlay(volcano.r, pts)
# writeOGR(pts.ov, "pts_ov.shp", ".", "ESRI Shapefile")

# plot perspective view on the study area:
z.val <- 3*as.matrix(volcano.r["z"])[,87:1]
par(mar=c(.5,.5,.5,.5))
z.3d <- persp(x, y, z=z.val, theta=-90, phi=50,  scale=FALSE, ltheta=-165, shade=0.65, box=FALSE)
lines(trans3d(pts.ov@coords[,1], y=pts.ov@coords[,2], 3*pts.ov$z, z.3d), lwd=3)

# Principal components: 
pc.dem <- prcomp(~z+TWI+VDEPTH, scale=TRUE, volcano.r@data)
biplot(pc.dem, arrow.len=0.1, xlabs=rep(".", length(pc.dem$x[,1])), main="PCA biplot")
# LSPs are relatively uncorrelated;
# Determine number of clusters
demdata <- as.data.frame(pc.dem$x)
wss <- (nrow(demdata)-1)*sum(apply(demdata,2,var))
for (i in 2:20) {wss[i] <- sum(kmeans(demdata, centers=i)$withinss)}
plot(1:20, wss, type="b", xlab="Number of Clusters", ylab="Within groups sum of squares")
# does not converge :(

kmeans.dem <- kmeans(demdata, 6)
volcano.r$kmeans.dem <- kmeans.dem$cluster
volcano.r$landform <- as.factor(kmeans.dem$cluster)
summary(volcano.r$landform)
# update the overlay:
pts.ov <- overlay(volcano.r, pts)
# spplot(volcano.r["landform"], col.regions=rainbow(6))

# plot bondaries:
landform.poly <- rasterToPolygons(landform.r, fun=function(x){x==6}, digits=0)
writePolyShape(landform.poly, "landform_poly.shp")
landform.3d <- persp(x, y, z=z.val, theta=-90, phi=50,  scale=FALSE, ltheta=-165, shade=0.65, box=FALSE)
lines(trans3d(pts.ov@coords[,1], y=pts.ov@coords[,2], 3*pts.ov$z, z.3d), lwd=3)

## Fig_catena_Maungawhau_A.pdf
# cross-section with landform classes:
plot(rev(pts.ov$z), type="l", main="", ylab="", xlab="", lwd=2, axes=FALSE)
text(locator(6), paste(c("hill top (soil A)", "depression (soil B)", "slope (soil C)", "shoulder (soil D)", "slope (soil C)", "footslope (soil E)")))
lines(data.frame(x=rep(25, 2), y=c(95,175)))
new.point <- pts.ov[80-24,]
text(locator(1), paste(c("prediction point")), cex=1.2)

## Fig_catena_Maungawhau_B.pdf
# plot cross-section for three covariates:
par(mfrow=c(3,1))
par(mar=c(5,5,2.5,.5))
plot(rev(pts.ov$z), type="l", main="", ylab="Elevation", xlab="", cex=1.2)
plot(rev(pts.ov$TWI), type="l", main="", ylab="TWI", xlab="", lty=4, cex=2)
plot(rev(pts.ov$VDEPTH), type="l", main="", ylab="Valley depth", xlab="", lty=4, cex=2)


# ------------------------------------------------------------
# Regression-kriging demo:
# ------------------------------------------------------------

library(gstat)
demo(meuse, echo=FALSE)
ls()
meuse.ov <- over(meuse, meuse.grid)
meuse.ov <- cbind(as.data.frame(meuse), meuse.ov)
head(meuse.ov[,c("x","y","dist","soil","om")])
m <- lm(log1p(om)~dist+soil, meuse.ov)
m
meuse.s <- meuse[-m$na.action,]
meuse.s$om.res <- resid(m)
vr.fit <- fit.variogram(variogram(om.res~1, meuse.s), vgm(1, "Exp", 300, 1))
vr.fit
vr.fit <- fit.variogram(variogram(log1p(om)~dist+soil, meuse.s), vgm(1, "Exp", 300, 1))
vr.fit
om.rk <- krige(log1p(om)~dist+soil, meuse.s, meuse.grid, vr.fit)
om.rk.cv <- krige.cv(log1p(om)~dist+soil, meuse.s, vr.fit)
hist(abs(om.rk.cv$zscore), main="Z-scores histogram", xlab="z-score value", col="grey", breaks=25)
library(nlme)
m.gls <- gls(log1p(om)~dist+soil, meuse.s, correlation=corExp(nugget=TRUE))
m.gls

omm <- fit.gstatModel(meuse, log1p(om)~dist+soil, meuse.grid)
summary(omm@regModel)
omm2 <- fit.gstatModel(meuse, om~dist+soil, meuse.grid, family=gaussian(link=log))
summary(omm2@regModel)
omm3 <- fit.gstatModel(meuse, log1p(om)~dist+soil, meuse.grid, method="rpart")
library(randomForest)
omm4 <- fit.gstatModel(meuse, log1p(om)~dist+soil, meuse.grid, method="quantregForest")
om.rk <- predict(omm, meuse.grid)
meuse.grid$om.rk <- expm1(om.rk@predicted$om + om.rk@predicted$var1.var/2)
om.rk2 <- predict(omm2, meuse.grid)
meuse.grid$om.rk2 <- om.rk2@predicted$om
om.rk3 <- predict(omm3, meuse.grid)
meuse.grid$om.rk3 <- expm1(om.rk3@predicted$om + om.rk3@predicted$var1.var/2)
om.rk4 <- predict(omm4, meuse.grid)
meuse.grid$om.rk4 <- expm1(om.rk4@predicted$om + om.rk4@predicted$var1.var/2)
#spplot(meuse.grid[c("om.rk","om.rk2")], col.regions=SAGA_pal[[1]], sp.layout=list("sp.points", meuse, pch="+", col="black", cex=1.2), names.attr=c("RK with log-trasformed values", "GLM-K with log-link function"))
r = range(unlist(meuse.grid@data[,c("om.rk","om.rk2","om.rk3","om.rk4")], use.names=FALSE))
rx <- rev(as.character(round(expm1(log1p(seq(r[1], r[2], length.out=5)))), 0))
tvar1 <- 1-var(om.rk@validation$residual, na.rm=T)/var(om.rk@validation$observed, na.rm=T)
tvar2 <- 1-var(log1p(om.rk2@validation$var1.pred)-log1p(om.rk2@validation$observed), na.rm=T)/var(log1p(om.rk2@validation$observed), na.rm=T)
tvar3 <- 1-var(om.rk3@validation$residual, na.rm=T)/var(om.rk3@validation$observed, na.rm=T)
tvar4 <- 1-var(om.rk4@validation$residual, na.rm=T)/var(om.rk4@validation$observed, na.rm=T)
##pal = grey(c(rev(seq(0,0.97,1/20))))
pal = SAGA_pal[[1]]

par(mfrow=c(2,2), mar=c(0,0,3,0), oma=c(0,0,0,0))
image(log1p(raster(meuse.grid["om.rk"])), col=pal, asp=1, zlim=log1p(r), main=paste("RK with log-trasformed values (", signif(tvar1*100, 2), "%)", sep=""), axes=FALSE, xlab="", ylab="", cex.main=.9)
points(meuse, pch="+", cex=.9)
legend("topleft", legend=rx, fill=rev(pal[c(1,5,10,15,20)]), horiz=FALSE, y.intersp=1.5, bty="n")
image(log1p(raster(meuse.grid["om.rk2"])), col=pal, asp=1, zlim=log1p(r), main=paste("GLM-kriging (", signif(tvar2*100, 2), "%)", sep=""), axes=FALSE, xlab="", ylab="", cex.main=.9)
points(meuse, pch="+", cex=.9)
legend("topleft", legend=rx, fill=rev(pal[c(1,5,10,15,20)]), horiz=FALSE, y.intersp=1.5, bty="n")
image(log1p(raster(meuse.grid["om.rk3"])), col=pal, asp=1, zlim=log1p(r), main=paste("rpart-kriging (", signif(tvar3*100, 2), "%)", sep=""), axes=FALSE, xlab="", ylab="", cex.main=.9)
points(meuse, pch="+", cex=.9)
legend("topleft", legend=rx, fill=rev(pal[c(1,5,10,15,20)]), horiz=FALSE, y.intersp=1.5, bty="n")
image(log1p(raster(meuse.grid["om.rk4"])), col=pal, asp=1, zlim=log1p(r), main=paste("randomForest-kriging (", signif(tvar4*100, 2), "%)", sep=""), axes=FALSE, xlab="", ylab="", cex.main=.9)
points(meuse, pch="+", cex=.9)
legend("topleft", legend=rx, fill=rev(pal[c(1,5,10,15,20)]), horiz=FALSE, y.intersp=1.5, bty="n")
## which model is better?
t1 <- test.gstatModel(meuse, log1p(om)~dist+soil, meuse.grid, Ns=155)
t2 <- test.gstatModel(meuse, om~dist+soil, meuse.grid, family=gaussian(link=log), Ns=155)
t1$performance ## this is in transformed space
t2$performance

## test model using different sampling intensities:
omm <- fit.gstatModel(meuse, log1p(om)~soil-1, meuse.grid)
summary(omm@regModel)
aggregate(log1p(om) ~ soil, meuse, mean) 
str(omm, max.level=2)
om.rk1 <- predict(omm, meuse.grid)
t1 <- test.gstatModel(meuse, log1p(om)~soil-1, meuse.grid, Ns=c(100, 155))

# ------------------------------------------------------------
# Point vs block support:
# ------------------------------------------------------------

omm <- fit.gstatModel(meuse, log1p(om)~dist+soil, meuse.grid)
om.rk.p <- predict(omm, meuse.grid, block=c(0,0))
om.rksim.p <- predict(omm, meuse.grid, nsim=20, block=c(0,0))
om.rk.b <- predict(omm, meuse.grid, block=c(40,40), nfold=0)
om.rksim.b <- predict(omm, meuse.grid, nsim=2, block=c(40,40))
om.rk.p

om.rksim.p <- predict(omm, meuse.grid, block=c(0,0), nsim=20)
log1p(meuse@data[1,"om"])
extract(raster(om.rk.p@predicted), meuse[1,])
extract(om.rksim.p@realizations, meuse[1,])
mean(extract(om.rksim.p@realizations, meuse[1,]))
## histograms:
library(StatDA)
x <- log1p(meuse.s$om)
xpred <- om.rk.p@predicted$om
xsim <- om.rksim.p@realizations@data@values[,1]
xsim <- xsim[!is.na(xsim)]
par(mfrow=c(1,3))
edaplot(x, H.freq=FALSE, box=TRUE, S.pch=3, S.cex=0.5, D.lwd=1.5, P.ylab="Density", P.log=FALSE, P.logfine=c(5,10), P.xlim =c(0.01, 3.5), P.main="", P.xlab="Sampled", B.pch=3, B.cex=0.5, H.breaks=seq(0,3.5,by=.25)) 
edaplot(xpred, H.freq=FALSE, box=TRUE, S.pch=3, S.cex=0.5, D.lwd=1.5, P.ylab="Density", P.log=FALSE, P.logfine=c(5,10), P.xlim =c(0.01, 3.5), P.main="", P.xlab="Predicted", B.pch=3, B.cex=0.5, H.breaks=seq(0,3.5,by=.25))
edaplot(xsim, H.freq=FALSE, box=TRUE, S.pch=3, S.cex=0.5, D.lwd=1.5, P.ylab="Density", P.log=FALSE, P.logfine=c(5,10), P.xlim =c(0.01, 3.5), P.main="", P.xlab="Simulated", B.pch=3, B.cex=0.5, H.breaks=seq(0,3.5,by=.25))

### Fig_meuse_block_predictions.pdf
at.om <- seq(2,max(c(om.rk$om.sim1,om.rk$om.sim2), na.rm=TRUE),by=0.25)
black.col <- at.om[which(at.om>14)]
om.point.plt <- spplot(om.rk[c("om.pred", "om.sim1", "om.sim2")], col.regions=grey(c(rev(seq(0,0.97,1/length(at.om[-black.col]))), rep(0,length(black.col)))), at=at.om, sp.layout=list("sp.points", pch="+", col="black", meuse))
om.block.plt <- spplot(om.brk[c("om.pred", "om.sim1", "om.sim2")], col.regions=grey(c(rev(seq(0,0.97,1/length(at.om[-black.col]))), rep(0,length(black.col)))), at=at.om, sp.layout=list("sp.points", pch="+", col="black", meuse))
print(om.point.plt, split=c(1,1,1,2), more=T)
print(om.block.plt, split=c(1,2,1,2), more=F)

grid.list <- list(om.rk, om.brk)
# sample variograms based on the simulations:
rnd.pnt <- spsample(grid.list[[1]]["om.sim1"], 1000, type="random")
zL.pnt <- overlay(grid.list[[1]]["om.sim1"], rnd.pnt)
zG.pnt <- overlay(grid.list[[2]]["om.sim1"], rnd.pnt)
var_point <- variogram(om.sim1 ~ 1, zL.pnt)
var_block <- variogram(om.sim1 ~ 1, zG.pnt)
vgm_point <- fit.variogram(var_point, vgm(nugget=0, model="Exp", range=sqrt(areaSpatialGrid(grid.list[[1]]))/3, psill=var(zL.pnt@data[,1])))
vgm_block <- fit.variogram(var_block, vgm(nugget=0, model="Exp", range=sqrt(areaSpatialGrid(grid.list[[j]]))/3, psill=var(zG.pnt@data[,1])))

### Fig_meuse_block_support_plots.pdf
par(mfrow=c(1,2))
par(mar=c(4.5,4.5,3.5,2.5))
# two correlation plots:
plot(om.brk$om.pred, om.rk$om.pred, xlab="Point support", ylab="Block support", pch=20, col="black", xlim=c(0,14), ylim=c(0,14), asp=1, main="Predictions")
lines(x=seq(0,14, by=1), y=seq(0,14, by=1), lwd=2, lty=3)
plot(om.brk$var1.var, om.rk$var1.var, xlab="Point support", ylab="Block support", pch=20, col="black", xlim=c(0,0.13), ylim=c(0,0.13), asp=1, main="Kriging variance (log-scale)")
lines(x=seq(0,0.13, by=0.01), y=seq(0,0.13, by=0.01), lwd=2, lty=3)
# variogram plots:
vgm.plt <- plot(var_point, vgm_point, main="Variogram (point support)", col="black") 
bvgm.plt <- plot(var_block, vgm_block, main="Variogram (block support)", col="black")
bvgm.plt$x.limits <- vgm.plt$x.limits
bvgm.plt$y.limits <- vgm.plt$y.limits
print(bvgm.plt, split=c(1,1,2,1), more=TRUE)
print(vgm.plt, split=c(2,1,2,1), more=FALSE)

# color palette
at.om <- seq(2,max(c(om.rk$om.sim1,om.rk$om.sim2), na.rm=TRUE),by=0.25)
black.col <- at.om[which(at.om>14)]
om.point.plt <- spplot(om.rk[c("om.pred", "om.sim1", "om.sim2")], col.regions=grey(c(rev(seq(0,0.97,1/length(at.om[-black.col]))), rep(0,length(black.col)))), at=at.om, sp.layout=list("sp.points", pch="+", col="black", meuse))
om.block.plt <- spplot(om.brk[c("om.pred", "om.sim1", "om.sim2")], col.regions=grey(c(rev(seq(0,0.97,1/length(at.om[-black.col]))), rep(0,length(black.col)))), at=at.om, sp.layout=list("sp.points", pch="+", col="black", meuse))
print(om.point.plt, split=c(1,1,1,2), more=T)
print(om.block.plt, split=c(1,2,1,2), more=F)

# ------------------------------------------------------------
# Best combined predictions
# ------------------------------------------------------------

library(gstat)
demo(meuse, echo=FALSE)
meuse.ov <- over(meuse, meuse.grid)
meuse.ov <- cbind(meuse.ov, meuse@data)
## compare with GLM only:
omm1 <- glm(om~dist+soil, meuse.ov, family=gaussian(link=log))
om.glm <- predict.glm(omm1, meuse.grid, type="response", se.fit=TRUE)
meuse.grid$om.glm <- om.glm$fit
vr.fit <- fit.variogram(variogram(log1p(om)~1, meuse[-omm1$na.action,]), vgm(0, "Exp", 300, .2))
vr.fit
om.ok <- krige(log1p(om)~1, meuse[-omm1$na.action,], meuse.grid, vr.fit)
meuse.grid$om.ok <- expm1(om.ok$var1.pred + om.ok$var1.var/2)

cv.omm1 <- boot::cv.glm(meuse[-omm1$na.action,], omm1, K=5)
cv.omm1$delta
meuse.grid$om.glmvar <- (om.glm[["se.fit"]]^2+om.glm[["residual.scale"]]^2)
meuse.grid$om.glmsvar <- meuse.grid$om.glmvar/var(meuse$om, na.rm=TRUE)
meuse.grid$om.glmnvar <- cv.omm1$delta[2] / mean(meuse.grid$om.glmvar) * meuse.grid$om.glmsvar
summary(meuse.grid$om.glmnvar)

cv.ok <- krige.cv(log1p(om)~1, meuse[-omm1$na.action,], nfold=5, vr.fit)
meuse.grid$om.oksvar <- om.ok$var1.var/var(log1p(meuse$om), na.rm=TRUE)
meuse.grid$om.oknvar <- mean(cv.ok$residual^2, na.rm=TRUE) / mean(om.ok$var1.var)  * meuse.grid$om.oksvar
summary(meuse.grid$om.oknvar)

meuse.grid$om.BCSP <- ((meuse.grid$om.ok)/meuse.grid$om.oknvar + (meuse.grid$om.glm)/meuse.grid$om.glmnvar)/rowSums(1/meuse.grid@data[,c("om.oknvar","om.glmnvar")])
## Fig_combined_predictions_Meuse.png
r0 = range(unlist(meuse.grid@data[,c("om.ok","om.BCSP","om.glm")], use.names=FALSE))
v0 = range(unlist(meuse.grid@data[,c("om.glmnvar","om.oknvar")], use.names=FALSE))
r0x <- rev(as.character(round(expm1(log1p(seq(r0[1], r0[2], length.out=5)))), 0))
v0x <- rev(as.character(round(seq(v0[1], v0[2], length.out=5), 3)))
par(mfrow=c(2,3), mar=c(0.5,0,3,0), oma=c(0,0,0,0))
image(log1p(raster(meuse.grid["om.ok"])), col=pal, asp=1, zlim=log1p(r), main="Ordinary kriging", axes=FALSE, xlab="", ylab="") # 
points(meuse, pch="+", cex=.9)
legend("topleft", legend=rx, fill=rev(pal[c(1,5,10,15,20)]), horiz=FALSE, y.intersp=1.5, bty="n")
image(log1p(raster(meuse.grid["om.BCSP"])), col=pal, asp=1, zlim=log1p(r), main="Combined predictions", axes=FALSE, xlab="", ylab="")
points(meuse, pch="+", cex=.9)
legend("topleft", legend=rx, fill=rev(pal[c(1,5,10,15,20)]), horiz=FALSE, y.intersp=1.5, bty="n")
image(log1p(raster(meuse.grid["om.glm"])), col=pal, asp=1, zlim=log1p(r), main="GLM", axes=FALSE, xlab="", ylab="")
points(meuse, pch="+", cex=.9)
legend("topleft", legend=rx, fill=rev(pal[c(1,5,10,15,20)]), horiz=FALSE, y.intersp=1.5, bty="n")
image(raster(meuse.grid["om.oknvar"]), col=pal, asp=1, zlim=v0, main="OK variance (normalized)", axes=FALSE, xlab="", ylab="")
points(meuse, pch="+", cex=.9)
legend("topleft", legend=v0x, fill=rev(pal[c(1,5,10,15,20)]), horiz=FALSE, y.intersp=1.5, bty="n")
image(raster(meuse.grid["om.glmnvar"]), col=pal, asp=1, zlim=c(-10,0), main="", axes=FALSE, xlab="", ylab="")
image(raster(meuse.grid["om.glmnvar"]), col=pal, asp=1, zlim=v0, main="GLM variance (normalized)", axes=FALSE, xlab="", ylab="")
points(meuse, pch="+", cex=.9)
legend("topleft", legend=v0x, fill=rev(pal[c(1,5,10,15,20)]), horiz=FALSE, y.intersp=1.5, bty="n")

# ------------------------------------------------------------
# Cross-validation plot
# ------------------------------------------------------------

vr.fit <- fit.variogram(variogram(log1p(om)~dist+soil, meuse.s), vgm(1, "Exp", 300, 1))
test_cv <- function(n, nfolds){
   cv.ok.lst <- expand.grid(Repetitions = 1:n, Folds = 1:nfolds, KEEP.OUT.ATTRS=FALSE)
   cv.ok.lst$Tvar = NA; cv.ok.lst$Method = "IDW"
   for(i in 1:n){
     cv <- krige.cv(om~1, meuse.s, nfold=nfolds)
     for(f in 1:nfolds){
      sel = cv$fold == f
      sel.r = which(cv.ok.lst$Repetitions == i & cv.ok.lst$Folds == f)
      cv.ok.lst[sel.r,"Tvar"] <- 1-var(cv$residual[sel], na.rm=T)/var(cv$observed, na.rm=T)
     }
   }
   cv.rk.lst <- expand.grid(Repetitions = 1:n, Folds = 1:nfolds, KEEP.OUT.ATTRS=FALSE)
   cv.rk.lst$Tvar = NA; cv.rk.lst$Method = "RK"
   for(i in 1:n){
     cv <- krige.cv(log1p(om)~dist+soil, meuse.s, model=vr.fit, nfold=nfolds)
     for(f in 1:nfolds){
      sel = cv$fold == f
      sel.r = which(cv.rk.lst$Repetitions == i & cv.rk.lst$Folds == f)
      cv.rk.lst[sel.r,"Tvar"] <- 1-var(cv$residual[sel], na.rm=T)/var(cv$observed, na.rm=T)
     }
   }
   cv.lst <- rbind(cv.ok.lst, cv.rk.lst)
   return(cv.lst)
}
## run 100 cross-validations...
x <- test_cv(20, 5)
## average:
average_cv <- function(x, n, Size){
  x.a.lst <- NULL
  for(k in 1:n){
    x.a <- expand.grid(Size = Size, Method = c("IDW","RK"), KEEP.OUT.ATTRS=FALSE)
    x.a$Tvar = NA
    for(j in 1:nrow(x.a)){
      sel.m = x$Method==x.a$Method[j]
      rnd = dismo::kfold(x[sel.m,], k=floor(100/x.a$Size[j]))
      sel <- rnd==1 
      x.a[j,"Tvar"] <- mean(x[sel.m,]$Tvar[sel])
      x.a.lst[[k]] <- x.a
      x.a.lst[[k]]$Realization <- k
    }
  }
  do.call(rbind, x.a.lst)
}
x_a <- average_cv(x, 2, c(1,2,3,4,5,8,14,20,50))
## plot differences between the two methods:
par(mfrow=c(1,2))
par(mar=c(5,3,.5,.5))
boxplot(Tvar~Method, x, ylim=c(0,1), col=c("grey","grey"))
plot(x_a$Size[x_a$Method=="IDW"&x_a$Realization==1], x_a$Tvar[x_a$Method=="IDW"&x_a$Realization==1], type="l", ylim=c(0,1), lty=2, xlab="Number of repetitions", log = "x")
lines(x_a$Size[x_a$Method=="RK"&x_a$Realization==1], x_a$Tvar[x_a$Method=="RK"&x_a$Realization==1], lwd=2)
lines(x_a$Size[x_a$Method=="IDW"&x_a$Realization==2], x_a$Tvar[x_a$Method=="IDW"&x_a$Realization==2], lty=2)
lines(x_a$Size[x_a$Method=="RK"&x_a$Realization==2], x_a$Tvar[x_a$Method=="RK"&x_a$Realization==2], lwd=2)
legend("topright", inset=.05, c("IDW","RK"), lty=c(2,1), lwd=c(1,2))

# ------------------------------------------------------------
# Geostatistical simulations transect
# ------------------------------------------------------------

# Cross section with 20 sims:
t3 <- Line(matrix(c(178500,180440,330348,330348), ncol=2))
transects <- SpatialLines(list(Lines(list(t3), ID="t")), CRS(NA))
pts <- spsample(transects, n=round((180440-178500)/40,0), type="regular")
pts.ov <- overlay(sims20t, pts)

N.sim=20
### Fig_20_sims_cross_section.pdf
# plot sims with mean value and 95% confidence limits (19/20):
par(mar=c(5,5,.5,.5))
plot(pts.ov@coords[,1], pts.ov@data[[1]], type="l", xlab="X", ylab="OM (%)", col="grey", ylim=c(0,21))
for(i in 2:N.sim){
lines(pts.ov@coords[,1], pts.ov@data[[i]], col="grey")
}
lines(pts.ov@coords[,1], pts.ov@data[["msim"]], lwd=3)
lines(pts.ov@coords[,1], pts.ov@data[["upper"]], lwd=2, lty=2)
lines(pts.ov@coords[,1], pts.ov@data[["lower"]], lwd=2, lty=2)
pdf("Fig_20_sims_cross_section.pdf", width=10cm, height=3.2cm)
print(lines.plt)
dev.off()

# Probability density function (examples)
x <- rnorm(300, mean=10, sd=1.5)
y <- c(7+rlnorm(100, sdlog=0.5), runif(50, min=6, max=14), rnorm(100, mean=12, sd=1)) 
### Fig_example_hist_PDFs
par(mfrow=c(1,2))
par(mar=c(4.5,4.5,.5,.5))
hist(x, breaks=25, col="grey", xlim=c(5,15), freq=FALSE, main="")
curve(dnorm(x, mean=10, sd=1.5), lty=2, lwd=2, add=TRUE)
hist(y, breaks=25, col="grey", xlim=c(5,15), freq=FALSE, main="")

# ------------------------------------------------------------
# Automated mapping:
# ------------------------------------------------------------

library(intamap)
demo(meuse, echo=FALSE)
meuse$value <- log1p(meuse$om)
output <- interpolate(observations=meuse[!is.na(meuse$value),], predictionLocations=meuse.grid)
