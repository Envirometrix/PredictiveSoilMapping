## The *universal model of soil variation* assumes that there are three

## ----scheme-2D-3D-maps, echo=FALSE, fig.cap="Number of variogram parameters assuming an exponential model, minimum number of samples and corresponding increase in number of prediction locations for 2D, 3D, 2D+T and 3D+T models of soil variation. Here “altitude” refers to vertical distance from the land surface, which is in case of soil mapping often expressed as negative vertical distance from the land surface.", out.width="60%"----
knitr::include_graphics("figures/Fig_2D_3DT_maps.png")

## ------------------------------------------------------------------------
lon = 3.90; lat = 7.50; id = "ISRIC:NG0017"; FAO1988 = "LXp" 
top = c(0, 18, 36, 65, 87, 127) 
bottom = c(18, 36, 65, 87, 127, 181)
ORCDRC = c(18.4, 4.4, 3.6, 3.6, 3.2, 1.2)
munsell = c("7.5YR3/2", "7.5YR4/4", "2.5YR5/6", "5YR5/8", "5YR5/4", "10YR7/3")
## prepare a SoilProfileCollection:
prof1 <- plyr::join(data.frame(id, top, bottom, ORCDRC, munsell), 
         data.frame(id, lon, lat, FAO1988), type='inner') 
prof1$mdepth <- prof1$top+(prof1$bottom-prof1$top)/2

## ------------------------------------------------------------------------
d.lm <- glm(ORCDRC ~ log(mdepth), data=prof1, family=gaussian(log))
options(list(scipen=3, digits=2))
d.lm$fitted.values

## Before fitting a 2D spatial prediction model to soil profile data, it is

## ----soil-depth-examples, echo=FALSE, fig.cap="Vertical variation in soil carbon modelled using a logarithmic function (left) and a mass-preserving spline (right) with abrupt changes by horizon ilustrated with solid lines.", out.width="100%"----
knitr::include_graphics("figures/Fig_soil_depth_examples.png")

## ------------------------------------------------------------------------
library(aqp)
library(rgdal)
library(GSIF)
prof1.spc <- prof1
depths(prof1.spc) <- id ~ top + bottom
site(prof1.spc) <- ~ lon + lat + FAO1988 
coordinates(prof1.spc) <- ~ lon + lat
proj4string(prof1.spc) <- CRS("+proj=longlat +datum=WGS84")
## fit a spline:
ORCDRC.s <- mpspline(prof1.spc, var.name="ORCDRC", show.progress=FALSE)
ORCDRC.s$var.std

## Soil property-depth relationships are commonly modelled using various

## Soil variables can refer to a specific depth interval or to the whole

## ----general-sp-process, echo=FALSE, fig.cap="From data to knowledge and back: the general spatial prediction scheme applicable to many environmental sciences.", out.width="85%"----
knitr::include_graphics("figures/Fig_general_SP_process.png")

## ----eberg-sampling-locs, echo=FALSE, fig.cap="Occurrence probabilities derived for the actual sampling locations (left), and for a purely random sample design with exactly the same number of points (right). Probabilities derived using the `spsample.prob` function from the GSIF package. The shaded area on the left indicates which areas (in the environmental space) have been systematically represented, while the white colour indicates areas which have been systematically omitted (and which is not by chance).", out.width="100%"----
knitr::include_graphics("figures/Fig_eberg_sampling_locs.png")

## ----cross-section-catena, echo=FALSE, fig.cap="Landform positions and location of a prediction point for the Maungawhau data set.", out.width="100%"----
knitr::include_graphics("figures/Fig_cross_section_catena.png")

## ----catena-maungawhau-3d, echo=FALSE, fig.cap="A cross-section for the Maungawhau volcano dataset commonly used in R to illustrate DEM and image analysis techniques.", out.width="80%"----
knitr::include_graphics("figures/Fig_catena_Maungawhau_A.jpg")

## ----catena-maungawhau, echo=FALSE, fig.cap="Associated values of DEM-based covariates: TWI — Topographic Wetness Index and Valley depth for the cross-section from the previous figure.", out.width="100%"----
knitr::include_graphics("figures/Fig_catena_Maungawhau_B.png")

## Model-based geostatistics is based on using an explicitly declared

## Spatial prediction under the linear Gaussian model with a trend boils

## ------------------------------------------------------------------------
library(gstat)
demo(meuse, echo=FALSE)

## ------------------------------------------------------------------------
meuse.ov <- over(meuse, meuse.grid)
meuse.ov <- cbind(as.data.frame(meuse), meuse.ov)
head(meuse.ov[,c("x","y","dist","soil","om")])

## ------------------------------------------------------------------------
m <- lm(log1p(om)~dist+soil, meuse.ov)
summary(m)

## ------------------------------------------------------------------------
meuse.s <- meuse[-m$na.action,]
meuse.s$om.res <- resid(m)
vr.fit <- fit.variogram(variogram(om.res~1, meuse.s), vgm(1, "Exp", 300, 1))
vr.fit

## ------------------------------------------------------------------------
v.s <- variogram(log1p(om)~dist+soil, meuse.s)
vr.fit <- fit.variogram(v.s, vgm(1, "Exp", 300, 1))
vr.fit

## ------------------------------------------------------------------------
om.rk <- krige(log1p(om)~dist+soil, meuse.s, meuse.grid, vr.fit)

## ------------------------------------------------------------------------
library(nlme)
m.gls <- gls(log1p(om)~dist+soil, meuse.s, correlation=corExp(nugget=TRUE))
m.gls

## ------------------------------------------------------------------------
omm <- fit.gstatModel(meuse, log1p(om)~dist+soil, meuse.grid)
str(omm, max.level = 2)

## ------------------------------------------------------------------------
om.rk <- predict(omm, meuse.grid)
om.rk
## back-transformation:
meuse.grid$om.rk <- expm1(om.rk@predicted$om + om.rk@predicted$var1.var/2)

## ----meuse-om-rk-glm, echo=FALSE, fig.cap="Predictions of organic carbon in percent (top soil) for the Meuse data set derived using regression-kriging with transformed values, GLM-kriging, regression tress (rpart) and random forest models combined with kriging. The percentages in brackets indicates amount of variation explained by the models.", out.width="85%"----
knitr::include_graphics("figures/Fig_meuse_om_RK_vs_GLMK.png")

## ------------------------------------------------------------------------
omm2 <- fit.gstatModel(meuse, om~dist+soil, meuse.grid, family=gaussian(link=log))
summary(omm2@regModel)
om.rk2 <- predict(omm2, meuse.grid)

## ------------------------------------------------------------------------
omm3 <- fit.gstatModel(meuse, log1p(om)~dist+soil, meuse.grid, method="rpart")

## ------------------------------------------------------------------------
omm4 <- fit.gstatModel(meuse, om~dist+soil, meuse.grid, method="quantregForest")

## ----rk-vs-rf-meuse, echo=FALSE, fig.cap="Predictions of the organic carbon (log-transformed values) using random forest vs linear regression-kriging. The random forest-kriging variance has been derived using the quantregForest package.", out.width="90%"----
knitr::include_graphics("figures/Fig_RK_vs_randomForestK_Meuse.png")

## ------------------------------------------------------------------------
omm <- fit.gstatModel(meuse, log1p(om)~soil-1, meuse.grid)
summary(omm@regModel)

## ------------------------------------------------------------------------
aggregate(log1p(om) ~ soil, meuse, mean) 

## ----confidence-limits-block, echo=FALSE, fig.cap="Scheme with predictions on point (above) and block support (below). In the case of various versions of kriging, both point and block predictions smooth the original measurements proportionally to the nugget variation. After Goovaerts (1997).", out.width="100%"----
knitr::include_graphics("figures/Fig_confidence_limits.png")

## The spatial support is the integration volume or size of the blocks

## ------------------------------------------------------------------------
omm <- fit.gstatModel(meuse, log1p(om)~dist+soil, meuse.grid)
om.rk.p <- predict(omm, meuse.grid, block=c(0,0))
om.rksim.p <- predict(omm, meuse.grid, nsim=20, block=c(0,0))

## ------------------------------------------------------------------------
om.rk.b <- predict(omm, meuse.grid, block=c(40,40), nfold=0)
om.rksim.b <- predict(omm, meuse.grid, nsim=2, block=c(40,40), debug.level=0)
## computationally intensive

## ------------------------------------------------------------------------
om.rk.p

## ----meuse-block-predictions, echo=FALSE, fig.cap="Predictions and simulations (2) at point (above) and block (below) support using the Meuse dataset. Note that prediction values produced by point and block methods are quite similar. Simulations on block support produce smoother maps than the point-support simulations.", out.width="100%"----
knitr::include_graphics("figures/Fig_meuse_block_predictions.jpg")

## ----meuse-block-support-plots1, echo=FALSE, fig.cap="Correlation plots for predictions and prediction variance: point vs block support.", out.width="100%"----
knitr::include_graphics("figures/Fig_meuse_block_support_plots1.png")

## ----meuse-block-support-plots2, echo=FALSE, fig.cap="Difference in variograms sampled from the simulated maps: point vs block support.", out.width="100%"----
knitr::include_graphics("figures/Fig_meuse_block_support_plots2.png")

## In geostatistics, one needs to consider that any input / output spatial

## ----sims-cross-section, echo=FALSE, fig.cap="20 simulations (at block support) of the soil organic carbon for the Meuse study area (cross-section from West to East at Y=330348). Bold line indicates the median value and broken lines indicate upper and lower quantiles (95\\% probability).", out.width="100%"----
knitr::include_graphics("figures/Fig_20_sims_cross_section.png")

## ----hist-om-predicted-simulated, echo=FALSE, fig.cap="Histogram for the target variable (Meuse data set; log of organic matter) based on the actual observations (left), predictions at all grid nodes (middle) and simulations (right). Note that the histogram for predicted values will always show somewhat narrower distribution (smoothed), depending on the strength of the model, while the simulations should be able to reproduce the original range (for more discussion see also: Yamamoto et al. (2008)).", out.width="100%"----
knitr::include_graphics("figures/Fig_hist_om_predicted_vs_simulated.png")

## ------------------------------------------------------------------------
om.rksim.p <- predict(omm, meuse.grid, block=c(0,0), nsim=20)
log1p(meuse@data[1,"om"])
extract(raster(om.rk.p@predicted), meuse[1,])
extract(om.rksim.p@realizations, meuse[1,])

## ------------------------------------------------------------------------
mean(extract(om.rksim.p@realizations, meuse[1,]))

## ------------------------------------------------------------------------
library(intamap)
demo(meuse, echo=FALSE)
meuse$value = meuse$zinc
output <- interpolate(meuse, meuse.grid, list(mean=TRUE, variance=TRUE))

## ------------------------------------------------------------------------
str(output, max.level = 2)

## Automated mapping is the computer-aided generation of (meaningful) maps

## ----scheme-statmodels, echo=FALSE, fig.cap="A modern workflow of predictive soil mapping. This often includes state-of-the-art Machine Learning Algorithms. Image source: Hengl et al. (2017) doi: 10.1371/journal.pone.0169748.", out.width="60%"----
knitr::include_graphics("figures/Fig_statmodels.png")

## ------------------------------------------------------------------------
library(caret); library(rgdal)
demo(meuse, echo=FALSE)
meuse.ov <- cbind(over(meuse, meuse.grid), meuse@data)
meuse.ov$x0 = 1

## ---- warning=FALSE------------------------------------------------------
fitControl <- trainControl(method="repeatedcv", number=2, repeats=2)
mFit0 <- caret::train(om~x0, data=meuse.ov, method="glm", 
               family=gaussian(link=log), trControl=fitControl, 
               na.action=na.omit)
mFit1 <- caret::train(om~soil, data=meuse.ov, method="glm", 
               family=gaussian(link=log), trControl=fitControl, 
               na.action=na.omit)
mFit2 <- caret::train(om~dist+soil+ffreq, data=meuse.ov, method="glm", 
               family=gaussian(link=log), trControl=fitControl, 
               na.action=na.omit)
mFit3 <- caret::train(om~dist+soil+ffreq, data=meuse.ov, method="ranger", 
               trControl=fitControl, na.action=na.omit)

## ----bwplot-meuse, fig.width=5, out.width="60%", fig.cap="Comparison of spatial prediction accuracy (RMSE at cross-validation points) for simple averaging (Mean), GLM with only soil map as covariate (Soilmap), GLM and random forest (RF) models with all possible covariates. Error bars indicate range of RMSE values for repeated CV."----
resamps <- resamples(list(Mean=mFit0, Soilmap=mFit1, GLM=mFit2, RF=mFit3))
bwplot(resamps, layout = c(2, 1), metric=c("RMSE","Rsquared"), 
       fill="grey", scales = list(relation = "free", cex = .7), 
       cex.main = .7, cex.axis = .7)

## ------------------------------------------------------------------------
round((1-min(mFit3$results$RMSE)/min(mFit0$results$RMSE))*100)

## Because soil variables are auto-correlated in both horizontal and

## ----voxel-scheme, echo=FALSE, fig.cap="Spatial 3D prediction locations in a gridded system (voxels). In soil mapping, we often predict for larger blocks of land e.g. 100 to 1000 m, but then for vertical depths of few tens of centimeters, so the output voxels might appear in reality as being somewhat disproportional.", out.width="55%"----
knitr::include_graphics("figures/Fig_voxel_scheme.png")

## ----multiscale-vs-multisource, echo=FALSE, fig.cap="A general scheme for generating spatial predictions using multiscale and multisource data.", out.width="90%"----
knitr::include_graphics("figures/Fig_multiscale_vs_multisource.png")

## A sensible approach to merging multiple predictions

## ----cross-validation-types, echo=FALSE, fig.cap="General types of validation procedures for evaluating accuracy of spatial prediction models.", out.width="60%"----
knitr::include_graphics("figures/Fig_cross_validation_types.png")

## ----cross-validation-repetitions, echo=FALSE, fig.cap="Left: confidence limits for the amount of variation explained (0–100\\%) for two spatial prediction methods: inverse distance interpolation (IDW) and regression-kriging (RK) for mapping organic carbon content (Meuse data set). Right: the average amount of variation explained for two realizations (5-fold cross-validation) as a function of the number of cross-validation runs (repetitions). In this case, the RK method is distinctly better than method IDW, but the cross-validation score seems to stabilize only after 10 runs.", out.width="85%"----
knitr::include_graphics("figures/Fig_cross_validation_repetitions.png")

## Cross-validation is a cost-efficient way to get an objective estimate of

## ----z-scores-histogram, fig.width=5, out.width="65%", fig.cap="Z-scores for the cross-validation of the soil organic carbon model."----
om.rk.cv <- krige.cv(log1p(om)~dist+soil, meuse.s, vr.fit)
hist(om.rk.cv$zscore, main = "Z-scores histogram", 
     xlab = "z-score value", col = "grey", breaks = 25, 
     cex.axis = .7, cex.main = .7, cex.lab = .7)

## ----difference-accuracy-reliability, echo=FALSE, fig.cap="Mapping accuracy and model reliability (accuracy of the prediction intervals vs actual intervals). Although a method can be accurate in predicting the mean values, it could fail in predicting the prediction intervals i.e. the associated uncertainty.", out.width="75%"----
knitr::include_graphics("figures/Fig_difference_accuracy_reliability.png")

## ------------------------------------------------------------------------
var(om.rk.cv$zscore, na.rm=TRUE)

## ------------------------------------------------------------------------
signif(quantile(meuse$om, c(.025, .975), na.rm=TRUE), 2)

## ------------------------------------------------------------------------
om.rk <- predict(omm, meuse.grid)

## ------------------------------------------------------------------------
pt1 <- data.frame(x=179390, y=330820)
coordinates(pt1) <- ~x+y
proj4string(pt1) = proj4string(meuse.grid)
pt1.om <- over(pt1, om.rk@predicted["om"])
pt1.om.sd <- over(pt1, om.rk@predicted["var1.var"])
signif(expm1(pt1.om-1.645*sqrt(pt1.om.sd)), 2)
signif(expm1(pt1.om+1.645*sqrt(pt1.om.sd)), 2)

## ------------------------------------------------------------------------
signif((expm1(pt1.om+1.645*sqrt(pt1.om.sd)) -
       expm1(pt1.om-1.645*sqrt(pt1.om.sd)))/2, 2)

## ----confidence-limits-boxplot, fig.cap="Prediction intervals for three flooding frequency classes for sampled and predicted soil organic matter. The grey boxes show 1st and 3rd quantiles i.e. range where of data falls.", out.width="80%"----
om.rksim <- predict(omm, meuse.grid, nsim=5, debug.level=0)
ov <- as(om.rksim@realizations, "SpatialGridDataFrame")
meuse.grid$om.sim1 <- expm1(ov@data[,1][meuse.grid@grid.index])
meuse.grid$om.rk <- expm1(om.rk@predicted$om)
par(mfrow=c(1,2))
boxplot(om~ffreq, omm@regModel$data, col="grey",
    xlab="Flooding frequency classes",
    ylab="Organic matter in %",
    main="Sampled (N = 153)", ylim=c(0,20),
    cex.axis = .7, cex.main = .7, cex.lab = .7)
boxplot(om.sim1~ffreq, meuse.grid, col="grey",
    xlab="Flooding frequency classes",
    ylab="Organic matter in %",
    main="Predicted (spatial simulations)", ylim=c(0,20),
    cex.axis = .7, cex.main = .7, cex.lab = .7)

## ------------------------------------------------------------------------
sd.om <- qt(0.975, df=length(meuse$om)-1) *
    sd(meuse$om, na.rm=TRUE)/sqrt(length(meuse$om))
sd.om

## ------------------------------------------------------------------------
lapply(levels(meuse.grid$ffreq), function(x){
    sapply(subset(meuse.grid@data, ffreq==x,
           select=om.sim1), sd, na.rm=TRUE)
})

## ------------------------------------------------------------------------
omm0 <- lm(om~ffreq-1, omm@regModel$data)
om.r <- predict(omm0, meuse.grid, se.fit=TRUE)
meuse.grid$se.fit <- om.r$se.fit
signif(mean(meuse.grid$se.fit, na.rm=TRUE), 3)

## Prediction intervals (upper and lower ranges of expected values with some

## ------------------------------------------------------------------------
aggregate(sqrt(meuse.grid$se.fit^2+om.r$residual.scale^2),
     by=list(meuse.grid$ffreq), mean, na.rm=TRUE)

## ------------------------------------------------------------------------
aggregate(meuse.grid$om.sim1, by=list(meuse.grid$ffreq), sd, na.rm=TRUE)

## ----validation-scheme, echo=FALSE, fig.cap="Universal plots of predictive performance: (a) 1:1 predicted vs observed plot, (b) CCC vs standard deviation of the z-scores plot, (c) nominal vs coverage probabilities, and (d) variogram of cross-validation residuals. Image source: Hengl et al. (2018) doi: 10.7717/peerj.5518.", out.width="80%"----
knitr::include_graphics("figures/Fig_validation_plots.png")

## ----scale-costs-ratio, echo=FALSE, fig.cap="Some basic concepts of soil survey: (a) relationship between cartographic scale and pixel size (Hengl, 2006), (b) soil survey costs and scale relationship based on the empirical data of (Legros, 2006).", out.width="100%"----
knitr::include_graphics("figures/Fig_scale_costs_ratio.png")

## ----costs-RMSE-scheme, echo=FALSE, fig.cap="General relationship between the sampling intensity (i.e. survey costs) and amount of variation in the target variable explained by a spatial prediction model. After Hengl et al. (2013) doi: 10.1016/j.jag.2012.02.005.", out.width="80%"----
knitr::include_graphics("figures/Fig_costs_RMSE_scheme.png")

## Soil mapping efficiency can be expressed as the cost of producing bytes

## ----cost-methods-scheme, echo=FALSE, fig.cap="An schematic example of a performance plot (‘predictogram’) for comparing spatial prediction models. For more details see: Hengl et al. (2013) doi: 10.1016/j.jag.2012.02.005.", out.width="65%"----
knitr::include_graphics("figures/Fig_costs_RMSE_scheme-2.png")

## Modern soil mapping is driven by the objective assessment of

