
# Machine Learning Algorithms for soil mapping {#soilmapping-using-mla}

*Edited by: T. Hengl*

## Spatial prediction of soil properties and classes using MLA's

This chapter looks at some common Machine learning algorithms (MLA's) that are potentially of interest to soil mapping projects i.e. for generating spatial prediction. We put especial focus on using the tree-based algorithms such as [random forest](https://en.wikipedia.org/wiki/Random_forest), [gradient boosting](https://en.wikipedia.org/wiki/Gradient_boosting) and [Cubist](https://cran.r-project.org/package=Cubist). For a more in-depth overview of machine learning algorithms used in statistics refer to the CRAN Task View on [Machine Learning & Statistical Learning](https://cran.r-project.org/web/views/MachineLearning.html). Some other examples of how MLA's can be used to fit Pedo-Transfer-Functions can be found in section \@ref(mla-ptfs).

### Loading the packages and data

We start by loading all required packages:


```r
library(plotKML)
#> plotKML version 0.5-9 (2017-05-15)
#> URL: http://plotkml.r-forge.r-project.org/
library(sp)
library(randomForest)
#> randomForest 4.6-12
#> Type rfNews() to see new features/changes/bug fixes.
library(nnet)
library(e1071)
library(GSIF)
#> GSIF version 0.5-4 (2017-04-25)
#> URL: http://gsif.r-forge.r-project.org/
library(plyr)
library(raster)
#> 
#> Attaching package: 'raster'
#> The following object is masked from 'package:e1071':
#> 
#>     interpolate
library(caret)
#> Loading required package: lattice
#> Loading required package: ggplot2
#> 
#> Attaching package: 'ggplot2'
#> The following object is masked from 'package:randomForest':
#> 
#>     margin
library(Cubist)
library(GSIF)
library(xgboost)
```

Next, we load the ([Ebergotzen](http://plotkml.r-forge.r-project.org/eberg.html)) data set which consists of soil augers and stack of rasters containing all covariates:


```r
library(plotKML)
data(eberg)
data(eberg_grid)
coordinates(eberg) <- ~X+Y
proj4string(eberg) <- CRS("+init=epsg:31467")
gridded(eberg_grid) <- ~x+y
proj4string(eberg_grid) <- CRS("+init=epsg:31467")
```

The covariates can be further converted to principal components:


```r
eberg_spc <- spc(eberg_grid, ~ PRMGEO6+DEMSRT6+TWISRT6+TIRAST6)
#> Converting PRMGEO6 to indicators...
#> Converting covariates to principal components...
eberg_grid@data <- cbind(eberg_grid@data, eberg_spc@predicted@data)
```

All further analysis is run using the so-called *regression matrix* (matrix produced using overlay of points and grids), which contains values of the target variable and all covariates for all training points:


```r
ov <- over(eberg, eberg_grid)
m <- cbind(ov, eberg@data)
dim(m)
#> [1] 3670   44
```

In this case the regression matrix consists of 3670 observations and has 44 columns.

### Spatial prediction of soil classes using MLA's

In the first example we focus on mapping soil types using the auger data. First, we need to filter out some classes that do not come frequently enough to allow for statistical modelling. As a rule of thumb, a class should have at least 5 observations:


```r
xg <- summary(m$TAXGRSC, maxsum=(1+length(levels(m$TAXGRSC))))
str(xg)
#>  Named int [1:14] 71 790 86 1 186 1 704 215 252 487 ...
#>  - attr(*, "names")= chr [1:14] "Auenboden" "Braunerde" "Gley" "HMoor" ...
selg.levs <- attr(xg, "names")[xg > 5]
attr(xg, "names")[xg <= 5]
#> [1] "HMoor" "Moor"
```

this shows that two classes probably have too little observations and can be excluded from further modeling:


```r
m$soiltype <- m$TAXGRSC
m$soiltype[which(!m$TAXGRSC %in% selg.levs)] <- NA
m$soiltype <- droplevels(m$soiltype)
str(summary(m$soiltype, maxsum=length(levels(m$soiltype))))
#>  Named int [1:11] 790 704 487 376 252 215 186 86 71 43 ...
#>  - attr(*, "names")= chr [1:11] "Braunerde" "Parabraunerde" "Pseudogley" "Regosol" ...
```

We can also remove all points that contain missing values for any combination of covariates and target variable:


```r
m <- m[complete.cases(m[,1:(ncol(eberg_grid)+2)]),]
m$soiltype <- as.factor(m$soiltype)
summary(m$soiltype)
#>     Auenboden     Braunerde          Gley    Kolluvisol Parabraunerde 
#>            48           669            68           138           513 
#>  Pararendzina       Pelosol    Pseudogley        Ranker       Regosol 
#>           176           177           411            17           313 
#>      Rendzina 
#>            22
```

We can now test fitting a MLA i.e. a random forest model using four covariate layers (parent material map, elevation, TWI and Aster thermal band):


```r
## subset to speed-up:
s <- sample.int(nrow(m), 500)
TAXGRSC.rf <- randomForest(x=m[-s,paste0("PC",1:10)], y=m$soiltype[-s],
                           xtest=m[s,paste0("PC",1:10)], ytest=m$soiltype[s])
## accuracy:
TAXGRSC.rf$test$confusion[,"class.error"]
#>     Auenboden     Braunerde          Gley    Kolluvisol Parabraunerde 
#>         0.750         0.479         0.692         0.652         0.524 
#>  Pararendzina       Pelosol    Pseudogley        Ranker       Regosol 
#>         0.543         0.674         0.678         1.000         0.625 
#>      Rendzina 
#>         0.667
```

Note that, by specifying `xtest` and `ytest`, we run both model fitting and cross-validation with 500 excluded points. The results show relatively high prediction error of about 60% i.e. relative classification accuracy of about 40%.

We can also test some other MLA's that are suited for this data — multinom from the [nnet](https://cran.r-project.org/package=nnet) package, and svm (Support Vector Machine) from the [e1071](https://cran.r-project.org/package=e1071) package:


```r
TAXGRSC.rf <- randomForest(x=m[,paste0("PC",1:10)], y=m$soiltype)
fm <- as.formula(paste("soiltype~", paste(paste0("PC",1:10), collapse="+")))
TAXGRSC.mn <- nnet::multinom(fm, m)
#> # weights:  132 (110 variable)
#> initial  value 6119.428736 
#> iter  10 value 4161.338634
#> iter  20 value 4118.296050
#> iter  30 value 4054.454486
#> iter  40 value 4020.653949
#> iter  50 value 3995.113270
#> iter  60 value 3980.172669
#> iter  70 value 3975.188371
#> iter  80 value 3973.743572
#> iter  90 value 3973.073564
#> iter 100 value 3973.064186
#> final  value 3973.064186 
#> stopped after 100 iterations
TAXGRSC.svm <- e1071::svm(fm, m, probability=TRUE, cross=5)
TAXGRSC.svm$tot.accuracy
#> [1] 39.7
```

This shows about the same accuracy levels as for random forest. Because all three methods produce comparable accuracy, we can also merge predictions by calculating a simple average:


```r
probs1 <- predict(TAXGRSC.mn, eberg_grid@data, type="probs", na.action = na.pass) 
probs2 <- predict(TAXGRSC.rf, eberg_grid@data, type="prob", na.action = na.pass)
probs3 <- attr(predict(TAXGRSC.svm, eberg_grid@data, 
                       probability=TRUE, na.action = na.pass), "probabilities")
```

derive average prediction:


```r
leg <- levels(m$soiltype)
lt <- list(probs1[,leg], probs2[,leg], probs3[,leg])
probs <- Reduce("+", lt) / length(lt)
## copy and make new raster object:
eberg_soiltype <- eberg_grid
eberg_soiltype@data <- data.frame(probs)
```

Check that all predictions sum up to 100%:


```r
ch <- rowSums(eberg_soiltype@data)
summary(ch)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>       1       1       1       1       1       1
```

To plot the result we can use the raster package (Fig. \@ref(fig:plot-eberg-soiltype)):

<div class="figure" style="text-align: center">
<img src="Soilmapping_using_mla_files/figure-html/plot-eberg-soiltype-1.png" alt="Predicted soil types for the Ebergotzen case study." width="864" />
<p class="caption">(\#fig:plot-eberg-soiltype)Predicted soil types for the Ebergotzen case study.</p>
</div>

By using the produced predictions we can further derive Confusion Index (to map thematic uncertainty) and see if some classes could be aggregated. We can also generate factor-type map by selecting for each pixel class which is most probable, by using e.g.:


```r
eberg_soiltype$cl <- as.factor(apply(eberg_soiltype@data,1,which.max))
levels(eberg_soiltype$cl) = attr(probs, "dimnames")[[2]][as.integer(levels(eberg_soiltype$cl))]
summary(eberg_soiltype$cl)
#>     Auenboden     Braunerde          Gley    Kolluvisol Parabraunerde 
#>            46          2282           140            63          2266 
#>  Pararendzina       Pelosol    Pseudogley       Regosol      Rendzina 
#>           780           471          1289           324          2339
```

### Modelling numeric soil properties using h2o

Random forest is suited for both classification and regression problems (it is one of the most popular MLA's for soil mapping), hence we can use it also for modelling numeric soil properties i.e. to fit models and generate predictions. However, because randomForest package in R is not suited for large data sets, we can also use some parallelized version of random forest (or more scalable) i.e. the one implemented in the [h2o package](http://www.h2o.ai/) [@richter2015multi]. h2o is a Java-based implementation hence installing the package requires Java libraries (size of package is about 80MB so it might take some to download and install) and all computing is in principle run outside of R i.e. within the JVM (Java Virtual Machine). 

In the following example we look at mapping sand content for top horizons. To initiate h2o we run:


```r
library(h2o)
localH2O = h2o.init(startH2O=FALSE)
#>  Connection successful!
#> 
#> R is connected to the H2O cluster: 
#>     H2O cluster uptime:         4 hours 14 minutes 
#>     H2O cluster version:        3.16.0.2 
#>     H2O cluster version age:    6 months and 6 days !!! 
#>     H2O cluster name:           H2O_started_from_R_root_baf962 
#>     H2O cluster total nodes:    1 
#>     H2O cluster total memory:   3.11 GB 
#>     H2O cluster total cores:    8 
#>     H2O cluster allowed cores:  8 
#>     H2O cluster healthy:        TRUE 
#>     H2O Connection ip:          localhost 
#>     H2O Connection port:        54321 
#>     H2O Connection proxy:       NA 
#>     H2O Internal Security:      FALSE 
#>     H2O API Extensions:         XGBoost, Algos, AutoML, Core V3, Core V4 
#>     R Version:                  R version 3.4.3 (2017-11-30)
#> Warning in h2o.clusterInfo(): 
#> Your H2O cluster version is too old (6 months and 6 days)!
#> Please download and install the latest version from http://h2o.ai/download/
```

This shows that multiple cores will be used for computing (to control the number of cores you can use the `nthreads` argument). Next, we need to prepare regression matrix and prediction locations using the `as.h2o` function so that they are visible to h2o:


```r
eberg.hex <- as.h2o(m, destination_frame = "eberg.hex")
#>   |                                                                         |                                                                 |   0%  |                                                                         |=================================================================| 100%
eberg.grid <- as.h2o(eberg_grid@data, destination_frame = "eberg.grid")
#>   |                                                                         |                                                                 |   0%  |                                                                         |=================================================================| 100%
```

We can now fit a random forest model by using all computing power we have:


```r
RF.m <- h2o.randomForest(y = which(names(m)=="SNDMHT_A"), 
                        x = which(names(m) %in% paste0("PC",1:10)), 
                        training_frame = eberg.hex, ntree = 50)
#>   |                                                                         |                                                                 |   0%  |                                                                         |===                                                              |   4%  |                                                                         |=================================================================| 100%
RF.m
#> Model Details:
#> ==============
#> 
#> H2ORegressionModel: drf
#> Model ID:  DRF_model_R_1528283394277_4 
#> Model Summary: 
#>   number_of_trees number_of_internal_trees model_size_in_bytes min_depth
#> 1              50                       50              643906        20
#>   max_depth mean_depth min_leaves max_leaves mean_leaves
#> 1        20   20.00000        901       1073  1021.30000
#> 
#> 
#> H2ORegressionMetrics: drf
#> ** Reported on training data. **
#> ** Metrics reported on Out-Of-Bag training samples **
#> 
#> MSE:  217
#> RMSE:  14.7
#> MAE:  10
#> RMSLE:  0.428
#> Mean Residual Deviance :  217
```

This shows that the model fitting R-square is about 50%. This is also visible from the predicted vs observed plot:


```r
library(scales)
library(lattice)
SDN.pred <- as.data.frame(h2o.predict(RF.m, eberg.hex, na.action=na.pass))$predict
#>   |                                                                         |                                                                 |   0%  |                                                                         |=================================================================| 100%
plt1 <- xyplot(m$SNDMHT_A ~ SDN.pred, asp=1, 
               par.settings=list(
                 plot.symbol = list(col=alpha("black", 0.6), 
                 fill=alpha("red", 0.6), pch=21, cex=0.8)),
                 ylab="measured", xlab="predicted (machine learning)")
plt1
```

<div class="figure" style="text-align: center">
<img src="Soilmapping_using_mla_files/figure-html/obs-pred-snd-1.png" alt="Measured vs predicted SAND content based on the Random Forest model." width="672" />
<p class="caption">(\#fig:obs-pred-snd)Measured vs predicted SAND content based on the Random Forest model.</p>
</div>

To produce a map based on predictions we use:


```r
eberg_grid$RFx <- as.data.frame(h2o.predict(RF.m, eberg.grid, na.action=na.pass))$predict
#>   |                                                                         |                                                                 |   0%  |                                                                         |=================================================================| 100%
```

<div class="figure" style="text-align: center">
<img src="Soilmapping_using_mla_files/figure-html/map-snd-1.png" alt="Predicted sand content based on random forest." width="768" />
<p class="caption">(\#fig:map-snd)Predicted sand content based on random forest.</p>
</div>

h2o has another MLA of interest to soil mapping called *deep learning* (a feed-forward multilayer artificial neural network). Fitting the model is equivalent to using random forest:


```r
DL.m <- h2o.deeplearning(y = which(names(m)=="SNDMHT_A"), 
                         x = which(names(m) %in% paste0("PC",1:10)), 
                         training_frame = eberg.hex)
#>   |                                                                         |                                                                 |   0%  |                                                                         |=============                                                    |  20%  |                                                                         |==========================================================       |  90%  |                                                                         |=================================================================| 100%
DL.m
#> Model Details:
#> ==============
#> 
#> H2ORegressionModel: deeplearning
#> Model ID:  DeepLearning_model_R_1528283394277_5 
#> Status of Neuron Layers: predicting SNDMHT_A, regression, gaussian distribution, Quadratic loss, 42,601 weights/biases, 508.3 KB, 25,520 training samples, mini-batch size 1
#>   layer units      type dropout       l1       l2 mean_rate rate_rms
#> 1     1    10     Input  0.00 %                                     
#> 2     2   200 Rectifier  0.00 % 0.000000 0.000000  0.015031 0.011310
#> 3     3   200 Rectifier  0.00 % 0.000000 0.000000  0.127455 0.174916
#> 4     4     1    Linear         0.000000 0.000000  0.001320 0.000966
#>   momentum mean_weight weight_rms mean_bias bias_rms
#> 1                                                   
#> 2 0.000000    0.007715   0.105052  0.359862 0.057063
#> 3 0.000000   -0.018960   0.071143  0.954458 0.017925
#> 4 0.000000    0.003088   0.052899  0.082360 0.000000
#> 
#> 
#> H2ORegressionMetrics: deeplearning
#> ** Reported on training data. **
#> ** Metrics reported on full training frame **
#> 
#> MSE:  218
#> RMSE:  14.8
#> MAE:  10.3
#> RMSLE:  0.427
#> Mean Residual Deviance :  218
```

Which shows a performance comparable to random forest model. The output predictions (map) does show somewhat different pattern from the random forest predictions (compare Fig. \@ref(fig:map-snd) and Fig. \@ref(fig:map-snd-dl)).


```r
## predictions:
eberg_grid$DLx <- as.data.frame(h2o.predict(DL.m, eberg.grid, na.action=na.pass))$predict
#>   |                                                                         |                                                                 |   0%  |                                                                         |=================================================================| 100%
```

<div class="figure" style="text-align: center">
<img src="Soilmapping_using_mla_files/figure-html/map-snd-dl-1.png" alt="Predicted SAND content based on deep learning." width="768" />
<p class="caption">(\#fig:map-snd-dl)Predicted SAND content based on deep learning.</p>
</div>

Which of the two methods should we use? Since they both have comparable performance, the most logical option is to generate ensemble (merged) predictions i.e. to produce a map that shows patterns between the two methods  (note: many sophisticated MLA such as random forest, neural nets, SVM and similar will often produce comparable results i.e. they are often equally applicable and there is no clear *winner*). We can use weighted average i.e. R-square as a simple approach to produce merged predictions:


```r
rf.R2 <- RF.m@model$training_metrics@metrics$r2
dl.R2 <- DL.m@model$training_metrics@metrics$r2
eberg_grid$SNDMHT_A <- rowSums(cbind(eberg_grid$RFx*rf.R2, 
                         eberg_grid$DLx*dl.R2), na.rm=TRUE)/(rf.R2+dl.R2)
```

<div class="figure" style="text-align: center">
<img src="Soilmapping_using_mla_files/figure-html/map-snd-ensemble-1.png" alt="Predicted SAND content based on ensemble predictions." width="768" />
<p class="caption">(\#fig:map-snd-ensemble)Predicted SAND content based on ensemble predictions.</p>
</div>

Indeed, the output map now shows patterns of both methods and is more likely slightly more accurate than any of the individual MLA's [@krogh1996learning].

### Spatial prediction of 3D (numeric) variables {#prediction-3D}

In the last exercise we look at another two ML-based packages that are also of interest for soil mapping projects — cubist [@kuhn2012cubist; @kuhn2013applied] and xgboost [@2016arXiv160302754C]. The object is now to fit models and predict continuous soil properties in 3D. To fine-tune some of the models we will also use the [caret](http://topepo.github.io/caret/) package, which is highly recommended for optimizing model fitting and cross-validation. Read more about how to derive soil organic carbon stock using 3D soil mapping in section \@ref(ocs-3d-approach).

We look at another soil mapping data set from Australia called [“Edgeroi”](http://gsif.r-forge.r-project.org/edgeroi.html) and which is described in detail in @Malone2009Geoderma. We can load the profile data and covariates by using:


```r
data(edgeroi)
edgeroi.sp <- edgeroi$sites
coordinates(edgeroi.sp) <- ~ LONGDA94 + LATGDA94
proj4string(edgeroi.sp) <- CRS("+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs")
edgeroi.sp <- spTransform(edgeroi.sp, CRS("+init=epsg:28355"))
load("extdata/edgeroi.grids.rda")
gridded(edgeroi.grids) <- ~x+y
proj4string(edgeroi.grids) <- CRS("+init=epsg:28355")
```

Here we are interested in modelling soil organic carbon content in g/kg for different depths. We again start by producing the regression matrix:


```r
ov2 <- over(edgeroi.sp, edgeroi.grids)
ov2$SOURCEID <- edgeroi.sp$SOURCEID
str(ov2)
#> 'data.frame':	359 obs. of  7 variables:
#>  $ DEMSRT5 : num  208 199 203 202 195 201 198 210 190 195 ...
#>  $ TWISRT5 : num  19.8 19.9 19.7 19.3 19.3 19.7 19.5 19.6 19.6 19.2 ...
#>  $ PMTGEO5 : Factor w/ 7 levels "Qd","Qrs","Qrt/Jp",..: 2 2 2 2 2 2 2 2 2 2 ...
#>  $ EV1MOD5 : num  -0.08 2.41 2.62 -0.39 -0.78 -0.75 1.14 5.16 -0.48 -0.84 ...
#>  $ EV2MOD5 : num  -2.47 -2.84 -2.43 5.2 1.27 -4.96 1.62 1.33 -2.66 1.01 ...
#>  $ EV3MOD5 : num  -1.59 -0.31 1.43 1.96 -0.44 2.47 -5.74 -6.78 2.29 -1.59 ...
#>  $ SOURCEID: Factor w/ 359 levels "199_CAN_CP111_1",..: 1 2 3 4 5 6 7 8 9 10 ...
```

Because we will run 3D modelling, we also need to add depth of horizons. We use a small function to assign depths to center of all horizons (as shown in figure below). Because we know where the horizons start and stop, we can copy values of target variables two times so that the model knows at which depth values of properties change. 


```r
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
```

<div class="figure" style="text-align: center">
<img src="figures/horizon_depths_for_3d_modeling_scheme.png" alt="Training points assigned to a soil profile with 3 horizons. Using the function from above, we assign a total of 7 training points i.e. about 2 times more training points than there are horizons." width="75%" />
<p class="caption">(\#fig:hor-3d-scheme)Training points assigned to a soil profile with 3 horizons. Using the function from above, we assign a total of 7 training points i.e. about 2 times more training points than there are horizons.</p>
</div>


```r
h2 <- hor2xyd(edgeroi$horizons)
## regression matrix:
m2 <- plyr::join_all(dfs = list(edgeroi$sites, h2, ov2))
#> Joining by: SOURCEID
#> Joining by: SOURCEID
## spatial prediction model:
formulaStringP2 <- ORCDRC ~ DEMSRT5+TWISRT5+PMTGEO5+EV1MOD5+EV2MOD5+EV3MOD5+DEPTH
mP2 <- m2[complete.cases(m2[,all.vars(formulaStringP2)]),]
```

Note that `DEPTH` is used as a covariate, which makes this model 3D as one can predict anywhere in 3D space. To improve random forest modelling, we use the caret package that tries to pick up also the optimal `mtry` parameter i.e. based on the cross-validation performance:


```r
library(caret)
ctrl <- trainControl(method="repeatedcv", number=5, repeats=1)
sel <- sample.int(nrow(mP2), 500)
tr.ORCDRC.rf <- train(formulaStringP2, data=mP2[sel,], 
                      method = "rf", trControl = ctrl, tuneLength = 3)
tr.ORCDRC.rf
#> Random Forest 
#> 
#> 500 samples
#>   7 predictor
#> 
#> No pre-processing
#> Resampling: Cross-Validated (5 fold, repeated 1 times) 
#> Summary of sample sizes: 400, 400, 400, 401, 399 
#> Resampling results across tuning parameters:
#> 
#>   mtry  RMSE  Rsquared  MAE 
#>    2    4.94  0.500     2.86
#>    7    4.08  0.619     2.21
#>   12    4.20  0.607     2.25
#> 
#> RMSE was used to select the optimal model using the smallest value.
#> The final value used for the model was mtry = 7.
```

In this case mtry = 12 seems to achieve best performance. Note that we sub-set the initial matrix to speed up fine-tuning of the parameters (otherwise the computing time could easily blow up). Next, we can fit the final model by using all data (this time we also turn cross-validation off):


```r
ORCDRC.rf <- train(formulaStringP2, data=mP2, 
                   method = "rf", tuneGrid=data.frame(mtry=7),
                   trControl=trainControl(method="none"))
w1 <- 100*max(tr.ORCDRC.rf$results$Rsquared)
```

Variable importance plot shows that DEPTH is far the most important predictor:

<div class="figure" style="text-align: center">
<img src="Soilmapping_using_mla_files/figure-html/varimp-plot-edgeroi-1.png" alt="Variable importance plot for predicting soil organic carbon content (ORC) in 3D." width="70%" />
<p class="caption">(\#fig:varimp-plot-edgeroi)Variable importance plot for predicting soil organic carbon content (ORC) in 3D.</p>
</div>

We can also try fitting models using the xgboost package and the cubist packages: 


```r
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
#> [1] 61.9 62.8 65.8
```

On the end of the statistical modelling process, we can merge the predictions by using the CV R-square estimates:


```r
edgeroi.grids$DEPTH = 2.5
edgeroi.grids$Random_forest <- predict(ORCDRC.rf, edgeroi.grids@data, na.action = na.pass) 
edgeroi.grids$Cubist <- predict(ORCDRC.cb, edgeroi.grids@data, na.action = na.pass)
edgeroi.grids$XGBoost <- predict(ORCDRC.gb, edgeroi.grids@data, na.action = na.pass)
edgeroi.grids$ORCDRC_5cm <- (edgeroi.grids$Random_forest*w1 + 
                               edgeroi.grids$Cubist*w2 + 
                               edgeroi.grids$XGBoost*w3)/(w1+w2+w3)
```

<div class="figure" style="text-align: center">
<img src="Soilmapping_using_mla_files/figure-html/maps-soc-edgeroi-1.png" alt="Comparison of three MLA's and final ensemble prediction (ORCDRC 5cm) of soil organic carbon content for 2.5 cm depth." width="672" />
<p class="caption">(\#fig:maps-soc-edgeroi)Comparison of three MLA's and final ensemble prediction (ORCDRC 5cm) of soil organic carbon content for 2.5 cm depth.</p>
</div>

The final plot shows that xgboost possibly overpredicts and that cubist possibly underpredicts values of `ORCDRC`, while random forest is somewhere in-between the two. Again, merged predictions are probably the safest option considering that all three MLA's have a similar performances.

We can quickly test the overall performance using a script on github prepared for testing performance of merged predictions:


```r
source_https <- function(url, ...) {
  require(RCurl)
  if(!file.exists(paste0("R/", basename(url)))){
    cat(getURL(url, followlocation = TRUE, cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl")), file = paste0("R/", basename(url)))
  }
  source(paste0("R/", basename(url)))
}
wdir = "https://raw.githubusercontent.com/ISRICWorldSoil/SoilGrids250m/"
source_https(paste0(wdir, "master/grids/cv/cv_functions.R"))
#> Loading required package: RCurl
#> Loading required package: bitops
```

We can hence run 5-fold cross validation:


```r
mP2$SOURCEID = paste(mP2$SOURCEID)
test.ORC <- cv_numeric(formulaStringP2, rmatrix=mP2, 
                       nfold=5, idcol="SOURCEID", Log=TRUE)
#> Running 5-fold cross validation with model re-fitting method ranger ...
#> Subsetting observations by unique location
#> Loading required package: snowfall
#> Loading required package: snow
#> Warning in searchCommandline(parallel, cpus = cpus, type = type,
#> socketHosts = socketHosts, : Unknown option on commandline: --file
#> R Version:  R version 3.4.3 (2017-11-30)
#> snowfall 1.84-6.1 initialized (using snow 0.4-2): parallel execution on 4 CPUs.
#> Library plyr loaded.
#> Library plyr loaded in cluster.
#> Library ranger loaded.
#> Library ranger loaded in cluster.
#> 
#> Attaching package: 'ranger'
#> The following object is masked from 'package:randomForest':
#> 
#>     importance
#> 
#> Stopping cluster
str(test.ORC)
#> List of 2
#>  $ CV_residuals:'data.frame':	4972 obs. of  4 variables:
#>   ..$ Observed : num [1:4972] 10.9 5.4 5.4 3.7 1.2 ...
#>   ..$ Predicted: num [1:4972] 12.18 8.33 6.29 4.5 2.24 ...
#>   ..$ SOURCEID : chr [1:4972] "399_EDGEROI_ed012_1" "399_EDGEROI_ed012_1" "399_EDGEROI_ed012_1" "399_EDGEROI_ed012_1" ...
#>   ..$ fold     : int [1:4972] 1 1 1 1 1 1 1 1 1 1 ...
#>  $ Summary     :'data.frame':	1 obs. of  6 variables:
#>   ..$ ME          : num -0.131
#>   ..$ MAE         : num 2.12
#>   ..$ RMSE        : num 3.62
#>   ..$ R.squared   : num 0.573
#>   ..$ logRMSE     : num 0.483
#>   ..$ logR.squared: num 0.653
```

Which shows that the R-squared based on cross-validation is about 65% i.e. the average error of predicting soil organic carbon content using ensemble method is about $\pm 4$ g/kg. The final observed-vs-predict plot shows that the model is unbiased and that the predictions generally match cross-validation points:

<div class="figure" style="text-align: center">
<img src="Soilmapping_using_mla_files/figure-html/plot-measured-predicted-1.png" alt="Predicted vs observed plot for soil organic carbon ML-based model (Edgeroi data set)." width="672" />
<p class="caption">(\#fig:plot-measured-predicted)Predicted vs observed plot for soil organic carbon ML-based model (Edgeroi data set).</p>
</div>

### Ensemble predictions using h2oEnsemble

Ensemble models often outperform single models. There is certainly opportunity for increasing the mapping accuracy by combining power of 3–4 MLA's. The h2o environment for ML offers automation of ensemble models fitting and predictions [@ledell2015scalable].


```r
library(h2o)
#devtools::install_github("h2oai/h2o-3/h2o-r/ensemble/h2oEnsemble-package")
library(h2oEnsemble)
#> h2oEnsemble R package for H2O-3
#> Version: 0.2.1
#> Package created on 2017-08-02
```

we first specify all learners of interest:


```r
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
#> Warning in doTryCatch(return(expr), name, parentenv, handler): Test/
#> Validation dataset is missing column 'fold_id': substituting in a column of
#> 0.0

#> Warning in doTryCatch(return(expr), name, parentenv, handler): Test/
#> Validation dataset is missing column 'fold_id': substituting in a column of
#> 0.0
perf
```

which shows that, in this specific case, ensemble model is only slightly better than a single model. Note that we would need to repeat testing the ensemble modeling several times until we can be certain what the accuracy gain is.

We can also test ensemble predictions using the cookfarm data set [@Gasch2015SPASTA]. This data set consists of 183 profiles, each consisting of multiple soil horizons (1050 in total). To create a regression matrix we use:


```r
data(cookfarm)
cookfarm.hor <- cookfarm$profiles
str(cookfarm.hor)
#> 'data.frame':	1050 obs. of  9 variables:
#>  $ SOURCEID: Factor w/ 369 levels "CAF001","CAF002",..: 3 3 3 3 3 5 5 5 5 5 ...
#>  $ Easting : num  493383 493383 493383 493383 493383 ...
#>  $ Northing: num  5180586 5180586 5180586 5180586 5180586 ...
#>  $ TAXSUSDA: Factor w/ 6 levels "Caldwell","Latah",..: 3 3 3 3 3 4 4 4 4 4 ...
#>  $ HZDUSD  : Factor w/ 67 levels "2R","A","A1",..: 12 2 7 35 36 12 2 16 43 44 ...
#>  $ UHDICM  : num  0 21 39 65 98 0 17 42 66 97 ...
#>  $ LHDICM  : num  21 39 65 98 153 17 42 66 97 153 ...
#>  $ BLD     : num  1.46 1.37 1.52 1.72 1.72 1.56 1.33 1.36 1.37 1.48 ...
#>  $ PHIHOX  : num  4.69 5.9 6.25 6.54 6.75 4.12 5.73 6.26 6.59 6.85 ...
cookfarm.hor$depth <- cookfarm.hor$UHDICM + (cookfarm.hor$LHDICM - cookfarm.hor$UHDICM)/2
sel.id <- unique(cookfarm.hor$SOURCEID)
cookfarm.xy <- cookfarm.hor[sel.id,c("SOURCEID","Easting","Northing")]
coordinates(cookfarm.xy) <- ~ Easting + Northing
grid10m <- cookfarm$grids
coordinates(grid10m) <- ~ x + y
gridded(grid10m) = TRUE
ov.cf <- over(cookfarm.xy, grid10m)
rm.cookfarm <- plyr::join(cookfarm.hor, cbind(cookfarm.xy@data, ov.cf))
#> Joining by: SOURCEID
```

Here, we are interested in predicting soil pH in 3D, hence we will use a model of form:


```r
fm.PHI <- PHIHOX~DEM+TWI+MUSYM+Cook_fall_ECa+Cook_spr_ECa+depth
mP3 <- rm.cookfarm[complete.cases(rm.cookfarm[,all.vars(fm.PHI)]),all.vars(fm.PHI)]
str(mP3)
#> 'data.frame':	1085 obs. of  7 variables:
#>  $ PHIHOX       : num  4.69 4.69 5.9 5.9 6.25 6.25 6.54 6.54 6.75 6.75 ...
#>  $ DEM          : num  788 788 788 788 788 ...
#>  $ TWI          : num  4.3 4.3 4.3 4.3 4.3 ...
#>  $ MUSYM        : Factor w/ 7 levels "Thatuna silt loam, 7 to 25 percent slopes",..: 6 6 6 6 6 6 6 6 6 6 ...
#>  $ Cook_fall_ECa: num  7.7 7.7 7.7 7.7 7.7 ...
#>  $ Cook_spr_ECa : num  33 33 33 33 33 ...
#>  $ depth        : num  10.5 10.5 30 30 52 ...
```

We can again test fitting an ensemble model using two MLA's:


```r
k.f3 <- dismo::kfold(mP3, k=4)
## split data into training and validation:
cookfarm_v.hex <- as.h2o(mP3[k.f==1,], destination_frame = "cookfarm_v.hex")
cookfarm_t.hex <- as.h2o(mP3[!k.f==1,], destination_frame = "cookfarm_t.hex")
learner3 = c("h2o.glm.wrapper", "h2o.randomForest.wrapper",
            "h2o.gbm.wrapper", "h2o.deeplearning.wrapper")
fit3 <- h2o.ensemble(x = which(names(mP3) %in% all.vars(fm.PHI)[-1]), 
                    y = which(names(mP3)=="PHIHOX"), 
                    training_frame = cookfarm_t.hex, learner = learner3, 
                    cvControl = list(V = 5))
perf3 <- h2o.ensemble_performance(fit3, newdata = cookfarm_v.hex)
#> Warning in doTryCatch(return(expr), name, parentenv, handler): Test/
#> Validation dataset is missing column 'fold_id': substituting in a column of
#> 0.0

#> Warning in doTryCatch(return(expr), name, parentenv, handler): Test/
#> Validation dataset is missing column 'fold_id': substituting in a column of
#> 0.0

#> Warning in doTryCatch(return(expr), name, parentenv, handler): Test/
#> Validation dataset is missing column 'fold_id': substituting in a column of
#> 0.0

#> Warning in doTryCatch(return(expr), name, parentenv, handler): Test/
#> Validation dataset is missing column 'fold_id': substituting in a column of
#> 0.0
perf3
```

In this case Ensemble performance (MSE) seems to be worse then the single best spatial predictor (random forest in this case). This could be because we are basically *forcing* using learners that have problems to map this feature. This illustrates that ensemble predictions should be taken with care.


```r
h2o.shutdown()
```

## A generic framework for spatial prediction using Random Forest

We have seen in previous examples that MLA's can be used efficiently to 
map soil properties and classes. Most of currently used MLA's, however, ignore the spatial
locations of the observations and hence any spatial autocorrelation in
the data not accounted for by the covariates. Spatial auto-correlation, 
especially if still existent in the cross-validation residuals, indicates 
that the predictions are maybe biased, and this is suboptimal. 
To account for this, @Hengl2018RFsp describe a framework for using Random Forest 
(as implemented in the ranger package) in combination with geographical 
distances to sampling locations to fit models and predict values (RFsp).

### General principle of RFsp

RF is in essence a non-spatial approach to spatial prediction as 
the sampling locations and general sampling pattern are ignored during
the estimation of MLA model parameters. This can potentially lead to
sub-optimal predictions and possibly systematic over- or
under-prediction, especially where the spatial autocorrelation in the
target variable is high and where point patterns show clear sampling
bias. To overcome this problem @Hengl2018RFsp propose the following generic *“RFsp”*
system:

\begin{equation}
Y({{\bf s}}) = f \left( {{\bf X}_G}, {{\bf X}_R}, {{\bf X}_P} \right)
(\#eq:rf-BUGP)
\end{equation}

where ${{\bf X}_G}$ are covariates accounting for geographical proximity
and spatial relations between observations (to mimic spatial correlation
used in kriging):

\begin{equation}
{{\bf X}_G} = \left( d_{p1}, d_{p2}, \ldots , d_{pN} \right)
\end{equation}

where $d_{pi}$ is the buffer distance (or any other complex proximity
upslope/downslope distance, as explained in the next section) to the
observed location $pi$ from ${\bf s}$ and $N$ is the total number of
training points. ${{\bf X}_R}$ are surface reflectance covariates, i.e.
usually spectral bands of remote sensing images, and ${{\bf X}_P}$ are
process-based covariates. For example, the Landsat infrared band is a
surface reflectance covariate, while the topographic wetness index and
soil weathering index are process-based covariates. Geographic
covariates are often smooth and reflect geometric composition of points,
reflectance-based covariates can carry significant amount of noise and
tell usually only about the surface of objects, and process-based
covariates require specialized knowledge and rethinking of how to
represent processes. Assuming that the RFsp is fitted only using the
${\bf {X}_G}$, the predictions would resemble OK. If all covariates are
used Eq. \@ref(eq:rf-BUGP), RFsp would resemble regression-kriging.

### Geographical covariates {#geographical-covariates}

One of the key principles of geography is that *“everything is related
to everything else, but near things are more related than distant
things”* [@miller2004tobler]. This principle forms the basis of
geostatistics, which converts this rule into a mathematical model, i.e.,
through spatial autocorrelation functions or variograms. The key to
making RF applicable to spatial statistics problems hence lies also in
preparing geographical measures of proximity and connectivity between
observations, so that spatial autocorrelation is accounted for. There
are multiple options for quantifying proximity and geographical
connection (Fig. \@ref(fig:distances-examples)):

1.  Geographical coordinates $s_1$ and $s_2$, i.e., easting
    and northing.

2.  Euclidean distances to reference points in the study area. For
    example, distance to the center and edges of the study area, etc.

3.  Euclidean distances to sampling locations, i.e., distances from
    observation locations. Here one buffer distance map can be generated
    per observation point or group of points. These are also distance
    measures used in geostatistics.

4.  Downslope distances, i.e., distances within a watershed: for each
    sampling point one can derive upslope/downslope distances to the
    ridges and hydrological network and/or downslope or upslope areas
    [@GRUBER2009171]. This requires, on top of using a Digital Elevation
    Model, a hydrological analysis of the terrain.

5.  Resistance distances or weighted buffer distances, i.e., distances
    of the cumulative effort derived using terrain ruggedness and/or
    natural obstacles.

The package , for example, provides a framework to derive complex
distances based on terrain complexity [@vanEtten2017r]. Here additional
input to compute complex distances are the Digital Elevation Model (DEM)
and DEM-derivatives, such as slope (Fig. \@ref(fig:distances-examples)b).
SAGA GIS [@gmd-8-1991-2015] offers a wide diversity of DEM derivatives
that can be derived per location of interest.

<div class="figure" style="text-align: center">
<img src="figures/Fig_distances_examples.png" alt="Examples of distance maps to some location in space (yellow dot) based on different derivation algorithms: (a) simple Euclidean distances, (b) complex speed-based distances based on the package and Digital Elevation Model (DEM) [@vanEtten2017r], and (c) upslope area derived based on the DEM in SAGA GIS [@gmd-8-1991-2015]. Case study: Ebergötzen [@bohner2006saga]." width="100%" />
<p class="caption">(\#fig:distances-examples)Examples of distance maps to some location in space (yellow dot) based on different derivation algorithms: (a) simple Euclidean distances, (b) complex speed-based distances based on the package and Digital Elevation Model (DEM) [@vanEtten2017r], and (c) upslope area derived based on the DEM in SAGA GIS [@gmd-8-1991-2015]. Case study: Ebergötzen [@bohner2006saga].</p>
</div>

Here we only show predictive performance with Eucledean buffer distances 
(to all sampling points), but the code could be adopted to
include other families of geographical covariates (as shown in
Fig. \@ref(fig:distances-examples)). Note also that RF tolerates high
number of covariates and multicolinearity [@Biau2016], hence multiple
types of geographical covariates (Euclidean buffer distances, upslope
and downslope areas) can be used at the same time.

### Spatial prediction 2D continuous variable using RFsp

To run these examples it is recommended to install [ranger](https://github.com/imbs-hl/ranger) [@wright2017ranger] directly from github:


```r
if(!require(ranger)){ devtools::install_github("imbs-hl/ranger") }
```

Quantile regression random forest and derivation of standard errors using Jackknifing is available from ranger version >0.9.4. Other packages that we use here include:


```r
library(GSIF)
library(rgdal)
#> rgdal: version: 1.2-16, (SVN revision 701)
#>  Geospatial Data Abstraction Library extensions to R successfully loaded
#>  Loaded GDAL runtime: GDAL 2.2.2, released 2017/09/15
#>  Path to GDAL shared files: /usr/share/gdal/2.2
#>  GDAL binary built with GEOS: TRUE 
#>  Loaded PROJ.4 runtime: Rel. 4.9.2, 08 September 2015, [PJ_VERSION: 492]
#>  Path to PROJ.4 shared files: (autodetected)
#>  Linking to sp version: 1.2-5
library(raster)
library(geoR)
#> --------------------------------------------------------------
#>  Analysis of Geostatistical Data
#>  For an Introduction to geoR go to http://www.leg.ufpr.br/geoR
#>  geoR version 1.7-5.2 (built on 2016-05-02) is now loaded
#> --------------------------------------------------------------
library(ranger)
```


```
#> 
#> Attaching package: 'parallel'
#> The following objects are masked from 'package:snow':
#> 
#>     clusterApply, clusterApplyLB, clusterCall, clusterEvalQ,
#>     clusterExport, clusterMap, clusterSplit, makeCluster,
#>     parApply, parCapply, parLapply, parRapply, parSapply,
#>     splitIndices, stopCluster
#> 
#> Attaching package: 'gridExtra'
#> The following object is masked from 'package:randomForest':
#> 
#>     combine
```

If no other information is available, we can use buffer distances to all points as covariates to predict values of some continuous or categorical variable in the RFsp framework. These can be derived with the help of the [raster](https://cran.r-project.org/package=raster) package [@raster]. Consider for example the meuse data set from the [gstat](https://github.com/edzer/gstat) package:


```r
demo(meuse, echo=FALSE)
```

We can derive buffer distance by using:


```r
grid.dist0 <- GSIF::buffer.dist(meuse["zinc"], meuse.grid[1], as.factor(1:nrow(meuse)))
```

which takes few seconds as it generates 155 gridded maps. The value of the target variable `zinc` can be now modeled as a function of buffer distances:


```r
dn0 <- paste(names(grid.dist0), collapse="+")
fm0 <- as.formula(paste("zinc ~ ", dn0))
fm0
#> zinc ~ layer.1 + layer.2 + layer.3 + layer.4 + layer.5 + layer.6 + 
#>     layer.7 + layer.8 + layer.9 + layer.10 + layer.11 + layer.12 + 
#>     layer.13 + layer.14 + layer.15 + layer.16 + layer.17 + layer.18 + 
#>     layer.19 + layer.20 + layer.21 + layer.22 + layer.23 + layer.24 + 
#>     layer.25 + layer.26 + layer.27 + layer.28 + layer.29 + layer.30 + 
#>     layer.31 + layer.32 + layer.33 + layer.34 + layer.35 + layer.36 + 
#>     layer.37 + layer.38 + layer.39 + layer.40 + layer.41 + layer.42 + 
#>     layer.43 + layer.44 + layer.45 + layer.46 + layer.47 + layer.48 + 
#>     layer.49 + layer.50 + layer.51 + layer.52 + layer.53 + layer.54 + 
#>     layer.55 + layer.56 + layer.57 + layer.58 + layer.59 + layer.60 + 
#>     layer.61 + layer.62 + layer.63 + layer.64 + layer.65 + layer.66 + 
#>     layer.67 + layer.68 + layer.69 + layer.70 + layer.71 + layer.72 + 
#>     layer.73 + layer.74 + layer.75 + layer.76 + layer.77 + layer.78 + 
#>     layer.79 + layer.80 + layer.81 + layer.82 + layer.83 + layer.84 + 
#>     layer.85 + layer.86 + layer.87 + layer.88 + layer.89 + layer.90 + 
#>     layer.91 + layer.92 + layer.93 + layer.94 + layer.95 + layer.96 + 
#>     layer.97 + layer.98 + layer.99 + layer.100 + layer.101 + 
#>     layer.102 + layer.103 + layer.104 + layer.105 + layer.106 + 
#>     layer.107 + layer.108 + layer.109 + layer.110 + layer.111 + 
#>     layer.112 + layer.113 + layer.114 + layer.115 + layer.116 + 
#>     layer.117 + layer.118 + layer.119 + layer.120 + layer.121 + 
#>     layer.122 + layer.123 + layer.124 + layer.125 + layer.126 + 
#>     layer.127 + layer.128 + layer.129 + layer.130 + layer.131 + 
#>     layer.132 + layer.133 + layer.134 + layer.135 + layer.136 + 
#>     layer.137 + layer.138 + layer.139 + layer.140 + layer.141 + 
#>     layer.142 + layer.143 + layer.144 + layer.145 + layer.146 + 
#>     layer.147 + layer.148 + layer.149 + layer.150 + layer.151 + 
#>     layer.152 + layer.153 + layer.154 + layer.155
```

Further analysis is similar to any regression analysis using the [ranger package](https://github.com/imbs-hl/ranger). First we overlay points and grids to create a regression matrix:


```r
ov.zinc <- over(meuse["zinc"], grid.dist0)
rm.zinc <- cbind(meuse@data["zinc"], ov.zinc)
```

to estimate also the prediction error variance i.e. prediction intervals we set `quantreg=TRUE` which initiates the Quantile Regression RF approach [@meinshausen2006quantile]:


```r
m.zinc <- ranger(fm0, rm.zinc, quantreg=TRUE, num.trees=150, seed=1)
m.zinc
#> Ranger result
#> 
#> Call:
#>  ranger(fm0, rm.zinc, quantreg = TRUE, num.trees = 150, seed = 1) 
#> 
#> Type:                             Regression 
#> Number of trees:                  150 
#> Sample size:                      155 
#> Number of independent variables:  155 
#> Mtry:                             12 
#> Target node size:                 5 
#> Variable importance mode:         none 
#> OOB prediction error (MSE):       67501 
#> R squared (OOB):                  0.499
```

This shows that, only buffer distance explain almost 50% of variation in the target variable. To generate prediction for the `zinc` variable and using the RFsp model, we use:


```r
q <- c((1-.682)/2, 0.5, 1-(1-.682)/2)
zinc.rfd <- predict(m.zinc, grid.dist0@data, 
                    type="quantiles", quantiles=q)$predictions
str(zinc.rfd)
#>  num [1:3103, 1:3] 257 257 257 257 257 ...
#>  - attr(*, "dimnames")=List of 2
#>   ..$ : NULL
#>   ..$ : chr [1:3] "quantile= 0.159" "quantile= 0.5" "quantile= 0.841"
```

this will estimate 67% probability lower and upper limits and median value. Note that “median” can often be different from the “mean”, so if you prefer to derive mean, then the `quantreg=FALSE` needs to be used as the Quantile Regression Forests approach can only derive median. 

To be able to plot or export predicted values as maps, we add them to the spatial pixels object:


```r
meuse.grid$zinc_rfd = zinc.rfd[,2]
meuse.grid$zinc_rfd_range = (zinc.rfd[,3]-zinc.rfd[,1])/2
```

We can compare the RFsp approach with the model-based geostatistics (see e.g. [geoR package](http://leg.ufpr.br/geoR/geoRdoc/geoRintro.html)), where we first decide about the transformation, then fit variogram of the target variable [@Diggle2007Springer; @Brown2014JSS]:


```r
zinc.geo <- as.geodata(meuse["zinc"])
ini.v <- c(var(log1p(zinc.geo$data)),500)
zinc.vgm <- likfit(zinc.geo, lambda=0, ini=ini.v, cov.model="exponential")
#> kappa not used for the exponential correlation function
#> ---------------------------------------------------------------
#> likfit: likelihood maximisation using the function optim.
#> likfit: Use control() to pass additional
#>          arguments for the maximisation function.
#>         For further details see documentation for optim.
#> likfit: It is highly advisable to run this function several
#>         times with different initial values for the parameters.
#> likfit: WARNING: This step can be time demanding!
#> ---------------------------------------------------------------
#> likfit: end of numerical maximisation.
zinc.vgm
#> likfit: estimated model parameters:
#>       beta      tausq    sigmasq        phi 
#> "  6.1553" "  0.0164" "  0.5928" "500.0001" 
#> Practical Range with cor=0.05 for asymptotic range: 1498
#> 
#> likfit: maximised log-likelihood = -1014
```

where `likfit` function fits log-likelihood based variogram. Note that we here manually need to specify log-transformation via the `lambda` parameter. To generate predictions and kriging variance using geoR we run:


```r
locs <- meuse.grid@coords
zinc.ok <- krige.conv(zinc.geo, locations=locs, krige=krige.control(obj.model=zinc.vgm))
#> krige.conv: model with constant mean
#> krige.conv: performing the Box-Cox data transformation
#> krige.conv: back-transforming the predicted mean and variance
#> krige.conv: Kriging performed using global neighbourhood
meuse.grid$zinc_ok <- zinc.ok$predict
meuse.grid$zinc_ok_range <- sqrt(zinc.ok$krige.var)
```

in this case geoR automatically back-transforms values to the original scale, which is a recommended feature. Comparison of predictions and prediction error maps produced using geoR (ordinary kriging) and RFsp (with buffer distances and by just using coordinates) is given in Fig. \@ref(fig:comparison-OK-RF-zinc-meuse).

<div class="figure" style="text-align: center">
<img src="figures/Fig_comparison_OK_RF_zinc_meuse.png" alt="Comparison of predictions based on ordinary kriging as implemented in the geoR package (left) and random forest (right) for Zinc concentrations, Meuse data set: (first row) predicted concentrations in log-scale and (second row) standard deviation of the prediction errors for OK and RF methods. After @Hengl2018RFsp." width="100%" />
<p class="caption">(\#fig:comparison-OK-RF-zinc-meuse)Comparison of predictions based on ordinary kriging as implemented in the geoR package (left) and random forest (right) for Zinc concentrations, Meuse data set: (first row) predicted concentrations in log-scale and (second row) standard deviation of the prediction errors for OK and RF methods. After @Hengl2018RFsp.</p>
</div>

From the plot above, it can be concluded that RFsp gives very similar results as ordinary kriging via geoR. The differences between geoR and RFsp, however, are:

- RF requires no transformation i.e. works equally good with skewed and normally distributed variables; in general RF, has much less statistical assumptions than model-based geostatistics,
- RF prediction error variance in average shows somewhat stronger contrast than OK variance map i.e. it emphasizes isolated less probable local points much more than geoR,
- RFsp is significantly more computational as distances need to be derived from any sampling point to all new predictions locations,
- geoR uses global model parameters and as such also prediction patterns are relatively uniform, RFsp on the other hand (being a tree-based) will produce patterns that as much as possible match data, 

### Spatial prediction 2D variable with covariates using RFsp

Next we can also consider adding extra covariates that describe soil forming processes or characteristics of the land of interest to the list of buffer distances, for example the surface water occurrence [@pekel2016high] and elevation ([AHN](http://ahn.nl)):


```r
f1 = "extdata/Meuse_GlobalSurfaceWater_occurrence.tif"
f2 = "extdata/ahn.asc"
meuse.grid$SW_occurrence <- readGDAL(f1)$band1[meuse.grid@grid.index]
#> extdata/Meuse_GlobalSurfaceWater_occurrence.tif has GDAL driver GTiff 
#> and has 104 rows and 78 columns
meuse.grid$AHN = readGDAL(f2)$band1[meuse.grid@grid.index]
#> extdata/ahn.asc has GDAL driver AAIGrid 
#> and has 104 rows and 78 columns
```

to convert all covariates to numeric values and impute all missing pixels we use Principal Component transformation:


```r
grids.spc = GSIF::spc(meuse.grid, as.formula("~ SW_occurrence + AHN + ffreq + dist"))
#> Converting ffreq to indicators...
#> Converting covariates to principal components...
```

so that we can fit a ranger model using both geographical covariates (buffer distances) and covariates imported previously:


```r
nms <- paste(names(grids.spc@predicted), collapse = "+")
fm1 <- as.formula(paste("zinc ~ ", dn0, " + ", nms))
fm1
#> zinc ~ layer.1 + layer.2 + layer.3 + layer.4 + layer.5 + layer.6 + 
#>     layer.7 + layer.8 + layer.9 + layer.10 + layer.11 + layer.12 + 
#>     layer.13 + layer.14 + layer.15 + layer.16 + layer.17 + layer.18 + 
#>     layer.19 + layer.20 + layer.21 + layer.22 + layer.23 + layer.24 + 
#>     layer.25 + layer.26 + layer.27 + layer.28 + layer.29 + layer.30 + 
#>     layer.31 + layer.32 + layer.33 + layer.34 + layer.35 + layer.36 + 
#>     layer.37 + layer.38 + layer.39 + layer.40 + layer.41 + layer.42 + 
#>     layer.43 + layer.44 + layer.45 + layer.46 + layer.47 + layer.48 + 
#>     layer.49 + layer.50 + layer.51 + layer.52 + layer.53 + layer.54 + 
#>     layer.55 + layer.56 + layer.57 + layer.58 + layer.59 + layer.60 + 
#>     layer.61 + layer.62 + layer.63 + layer.64 + layer.65 + layer.66 + 
#>     layer.67 + layer.68 + layer.69 + layer.70 + layer.71 + layer.72 + 
#>     layer.73 + layer.74 + layer.75 + layer.76 + layer.77 + layer.78 + 
#>     layer.79 + layer.80 + layer.81 + layer.82 + layer.83 + layer.84 + 
#>     layer.85 + layer.86 + layer.87 + layer.88 + layer.89 + layer.90 + 
#>     layer.91 + layer.92 + layer.93 + layer.94 + layer.95 + layer.96 + 
#>     layer.97 + layer.98 + layer.99 + layer.100 + layer.101 + 
#>     layer.102 + layer.103 + layer.104 + layer.105 + layer.106 + 
#>     layer.107 + layer.108 + layer.109 + layer.110 + layer.111 + 
#>     layer.112 + layer.113 + layer.114 + layer.115 + layer.116 + 
#>     layer.117 + layer.118 + layer.119 + layer.120 + layer.121 + 
#>     layer.122 + layer.123 + layer.124 + layer.125 + layer.126 + 
#>     layer.127 + layer.128 + layer.129 + layer.130 + layer.131 + 
#>     layer.132 + layer.133 + layer.134 + layer.135 + layer.136 + 
#>     layer.137 + layer.138 + layer.139 + layer.140 + layer.141 + 
#>     layer.142 + layer.143 + layer.144 + layer.145 + layer.146 + 
#>     layer.147 + layer.148 + layer.149 + layer.150 + layer.151 + 
#>     layer.152 + layer.153 + layer.154 + layer.155 + PC1 + PC2 + 
#>     PC3 + PC4 + PC5 + PC6
ov.zinc1 <- over(meuse["zinc"], grids.spc@predicted)
rm.zinc1 <- do.call(cbind, list(meuse@data["zinc"], ov.zinc, ov.zinc1))
```

this finally gives:


```r
m1.zinc <- ranger(fm1, rm.zinc1, importance="impurity", quantreg=TRUE, num.trees=150, seed=1)
m1.zinc
#> Ranger result
#> 
#> Call:
#>  ranger(fm1, rm.zinc1, importance = "impurity", quantreg = TRUE,      num.trees = 150, seed = 1) 
#> 
#> Type:                             Regression 
#> Number of trees:                  150 
#> Sample size:                      155 
#> Number of independent variables:  161 
#> Mtry:                             12 
#> Target node size:                 5 
#> Variable importance mode:         impurity 
#> OOB prediction error (MSE):       54750 
#> R squared (OOB):                  0.594
```

which shows that there is a slight improvement from using only buffer distances as covariates. 
We can further evaluate this model to see which specific points and covariates are 
most important for spatial predictions:


```r
xl <- as.list(ranger::importance(m1.zinc))
par(mfrow=c(1,1),oma=c(0.7,2,0,1), mar=c(4,3.5,1,0))
plot(vv <- t(data.frame(xl[order(unlist(xl), decreasing=TRUE)[10:1]])), 1:10, 
     type = "n", ylab = "", yaxt = "n", xlab = "Variable Importance (Node Impurity)")
abline(h = 1:10, lty = "dotted", col = "grey60")
points(vv, 1:10)
axis(2, 1:10, labels = dimnames(vv)[[1]], las = 2)
```

<div class="figure" style="text-align: center">
<img src="Soilmapping_using_mla_files/figure-html/rf-variableImportance-1.png" alt="Variable importance plot for mapping zinc content based on the Meuse data set." width="672" />
<p class="caption">(\#fig:rf-variableImportance)Variable importance plot for mapping zinc content based on the Meuse data set.</p>
</div>

which shows, for example, that point 54, 59 and 53 are most influential points, 
and these are almost equally important as covariates (PC2–PC4).

This type of modeling can be best compared to using Universal Kriging or Regression-Kriging in the geoR package:


```r
zinc.geo$covariate = ov.zinc1
sic.t = ~ PC1 + PC2 + PC3 + PC4 + PC5
zinc1.vgm <- likfit(zinc.geo, trend = sic.t, lambda=0, ini=ini.v, cov.model="exponential")
#> kappa not used for the exponential correlation function
#> ---------------------------------------------------------------
#> likfit: likelihood maximisation using the function optim.
#> likfit: Use control() to pass additional
#>          arguments for the maximisation function.
#>         For further details see documentation for optim.
#> likfit: It is highly advisable to run this function several
#>         times with different initial values for the parameters.
#> likfit: WARNING: This step can be time demanding!
#> ---------------------------------------------------------------
#> likfit: end of numerical maximisation.
zinc1.vgm
#> likfit: estimated model parameters:
#>      beta0      beta1      beta2      beta3      beta4      beta5 
#> "  5.6929" " -0.4351" "  0.0002" " -0.0791" " -0.0485" " -0.3725" 
#>      tausq    sigmasq        phi 
#> "  0.0566" "  0.1992" "499.9990" 
#> Practical Range with cor=0.05 for asymptotic range: 1498
#> 
#> likfit: maximised log-likelihood = -980
```

this time geostatistical modeling results in estimate of beta (regression coefficients) and variogram parameters (all estimated at once). Predictions using this Universal Kriging model can be generated by:


```r
KC = krige.control(trend.d = sic.t, 
                   trend.l = ~ grids.spc@predicted$PC1 + 
                     grids.spc@predicted$PC2 + grids.spc@predicted$PC3 + 
                     grids.spc@predicted$PC4 + grids.spc@predicted$PC5, 
                   obj.model = zinc1.vgm)
zinc.uk <- krige.conv(zinc.geo, locations=locs, krige=KC)
#> krige.conv: model with mean defined by covariates provided by the user
#> krige.conv: performing the Box-Cox data transformation
#> krige.conv: back-transforming the predicted mean and variance
#> krige.conv: Kriging performed using global neighbourhood
meuse.grid$zinc_UK = zinc.uk$predict
```

<div class="figure" style="text-align: center">
<img src="figures/Fig_RF_covs_bufferdist_zinc_meuse.png" alt="Comparison of predictions (median values) produced using random forest and covariates only (left), and random forest with combined covariates and buffer distances (right)." width="100%" />
<p class="caption">(\#fig:RF-covs-bufferdist-zinc-meuse)Comparison of predictions (median values) produced using random forest and covariates only (left), and random forest with combined covariates and buffer distances (right).</p>
</div>

again, overall predictions (spatial patterns) look fairly similar (Fig.\@ref(fig:RF-covs-bufferdist-zinc-meuse)). 
The difference between using geoR and RFsp is that, in the case of RFsp there are less choices 
and less assumptions to be made. Also, RFsp allows that relationship with covariates 
and geographical distances is fitted all at once. This makes RFsp in general less 
cumbersome than model-based geostatistics, but then more of a “black-box” system 
to a geostatistician. 

### Spatial prediction of binomial variable

RFsp can also be used to predict i.e. map distribution of binomial variables i.e. having only two states (TRUE or FALSE). In the model-based geostatistics equivalent methods are indicator kriging and similar. Consider for example the soil type 1 from the meuse data set:


```r
meuse@data = cbind(meuse@data, data.frame(model.matrix(~soil-1, meuse@data)))
summary(as.factor(meuse$soil1))
#>  0  1 
#> 58 97
```

in this case class `soil1` is the dominant soil type in the area. To produce a map of `soil1` using RFsp we have now two options:

- _Option 1_: treat binomial variable as numeric variable with 0 / 1 values (thus a regression problem),
- _Option 2_: treat binomial variable as factor variable with a single class (thus a classification problem),

In the case of Option 1, we model `soil1` as:


```r
fm.s1 <- as.formula(paste("soil1 ~ ", paste(names(grid.dist0), collapse="+"), 
                         " + SW_occurrence + dist"))
rm.s1 <- do.call(cbind, list(meuse@data["soil1"], 
                             over(meuse["soil1"], meuse.grid), 
                             over(meuse["soil1"], grid.dist0)))
m1.s1 <- ranger(fm.s1, rm.s1, mtry=22, num.trees=150, seed=1, quantreg=TRUE)
m1.s1
#> Ranger result
#> 
#> Call:
#>  ranger(fm.s1, rm.s1, mtry = 22, num.trees = 150, seed = 1, quantreg = TRUE) 
#> 
#> Type:                             Regression 
#> Number of trees:                  150 
#> Sample size:                      155 
#> Number of independent variables:  157 
#> Mtry:                             22 
#> Target node size:                 5 
#> Variable importance mode:         none 
#> OOB prediction error (MSE):       0.0579 
#> R squared (OOB):                  0.754
```

which shows that the model explains about 75% of variability in the `soil1` values. 
We set `quantreg=TRUE` so that we can also derive lower and upper prediction 
intervals following the quantile regression random forest [@meinshausen2006quantile].

In the case of Option 2, we treat binomial variable as a factor variable:


```r
fm.s1c <- as.formula(paste("soil1c ~ ", 
                           paste(names(grid.dist0), collapse="+"), 
                           " + SW_occurrence + dist"))
rm.s1$soil1c = as.factor(rm.s1$soil1)
m2.s1 <- ranger(fm.s1c, rm.s1, mtry=22, num.trees=150, seed=1, probability=TRUE, keep.inbag=TRUE)
m2.s1
#> Ranger result
#> 
#> Call:
#>  ranger(fm.s1c, rm.s1, mtry = 22, num.trees = 150, seed = 1, probability = TRUE,      keep.inbag = TRUE) 
#> 
#> Type:                             Probability estimation 
#> Number of trees:                  150 
#> Sample size:                      155 
#> Number of independent variables:  157 
#> Mtry:                             22 
#> Target node size:                 10 
#> Variable importance mode:         none 
#> OOB prediction error:             0.0586
```

which shows that the Out of Bag prediction error (classification error) is (only) 
0.06 (in the probability scale). Note that, it is not easy to compare the results 
of the regression and classification OOB errors as these are conceptually different. 
Also note that we turn on `keep.inbag = TRUE` so that ranger can estimate the 
classification errors using the Jackknife-after-Bootstrap method [@wager2014confidence].
`quantreg=TRUE` obviously would not work here since it is a classification and not a regression problem. 

To produce predictions using the two options we use:


```r
pred.regr <- predict(m1.s1, cbind(meuse.grid@data, grid.dist0@data), type="response")
pred.clas <- predict(m2.s1, cbind(meuse.grid@data, grid.dist0@data), type="se")
```

in principle, the two options to predicting distribution of binomial variable are mathematically equivalent and should lead to same predictions (also shown in the map below). In practice there can be some smaller differences in numbers due to rounding effect or random start effects. 

<div class="figure" style="text-align: center">
<img src="figures/Fig_comparison_uncertainty_Binomial_variables_meuse.png" alt="Comparison of predictions for soil class “1” produced using (left) regression and prediction of the median value, (middle) regression and prediction of response value, and (right) classification with probabilities." width="90%" />
<p class="caption">(\#fig:comparison-uncertainty-Binomial)Comparison of predictions for soil class “1” produced using (left) regression and prediction of the median value, (middle) regression and prediction of response value, and (right) classification with probabilities.</p>
</div>

This shows that predicting binomial variables using RFsp can be implemented both as a classification and regression problems and both are possible via the ranger package and should lead to same results.

### Spatial prediction of soil types

Spatial prediction of categorical variable using ranger belongs to classification problems. The target variable contains multiple states (3 in this case), but the model follows still the same formulation:


```r
fm.s = as.formula(paste("soil ~ ", paste(names(grid.dist0), collapse="+"), 
                        " + SW_occurrence + dist"))
fm.s
#> soil ~ layer.1 + layer.2 + layer.3 + layer.4 + layer.5 + layer.6 + 
#>     layer.7 + layer.8 + layer.9 + layer.10 + layer.11 + layer.12 + 
#>     layer.13 + layer.14 + layer.15 + layer.16 + layer.17 + layer.18 + 
#>     layer.19 + layer.20 + layer.21 + layer.22 + layer.23 + layer.24 + 
#>     layer.25 + layer.26 + layer.27 + layer.28 + layer.29 + layer.30 + 
#>     layer.31 + layer.32 + layer.33 + layer.34 + layer.35 + layer.36 + 
#>     layer.37 + layer.38 + layer.39 + layer.40 + layer.41 + layer.42 + 
#>     layer.43 + layer.44 + layer.45 + layer.46 + layer.47 + layer.48 + 
#>     layer.49 + layer.50 + layer.51 + layer.52 + layer.53 + layer.54 + 
#>     layer.55 + layer.56 + layer.57 + layer.58 + layer.59 + layer.60 + 
#>     layer.61 + layer.62 + layer.63 + layer.64 + layer.65 + layer.66 + 
#>     layer.67 + layer.68 + layer.69 + layer.70 + layer.71 + layer.72 + 
#>     layer.73 + layer.74 + layer.75 + layer.76 + layer.77 + layer.78 + 
#>     layer.79 + layer.80 + layer.81 + layer.82 + layer.83 + layer.84 + 
#>     layer.85 + layer.86 + layer.87 + layer.88 + layer.89 + layer.90 + 
#>     layer.91 + layer.92 + layer.93 + layer.94 + layer.95 + layer.96 + 
#>     layer.97 + layer.98 + layer.99 + layer.100 + layer.101 + 
#>     layer.102 + layer.103 + layer.104 + layer.105 + layer.106 + 
#>     layer.107 + layer.108 + layer.109 + layer.110 + layer.111 + 
#>     layer.112 + layer.113 + layer.114 + layer.115 + layer.116 + 
#>     layer.117 + layer.118 + layer.119 + layer.120 + layer.121 + 
#>     layer.122 + layer.123 + layer.124 + layer.125 + layer.126 + 
#>     layer.127 + layer.128 + layer.129 + layer.130 + layer.131 + 
#>     layer.132 + layer.133 + layer.134 + layer.135 + layer.136 + 
#>     layer.137 + layer.138 + layer.139 + layer.140 + layer.141 + 
#>     layer.142 + layer.143 + layer.144 + layer.145 + layer.146 + 
#>     layer.147 + layer.148 + layer.149 + layer.150 + layer.151 + 
#>     layer.152 + layer.153 + layer.154 + layer.155 + SW_occurrence + 
#>     dist
```

to produce probability maps per soil class, we need to turn the `probability=TRUE` option:


```r
rm.s <- do.call(cbind, list(meuse@data["soil"], 
                            over(meuse["soil"], meuse.grid), 
                            over(meuse["soil"], grid.dist0)))
m.s <- ranger(fm.s, rm.s, mtry=22, num.trees=150, seed=1, probability=TRUE, keep.inbag=TRUE)
m.s
#> Ranger result
#> 
#> Call:
#>  ranger(fm.s, rm.s, mtry = 22, num.trees = 150, seed = 1, probability = TRUE,      keep.inbag = TRUE) 
#> 
#> Type:                             Probability estimation 
#> Number of trees:                  150 
#> Sample size:                      155 
#> Number of independent variables:  157 
#> Mtry:                             22 
#> Target node size:                 10 
#> Variable importance mode:         none 
#> OOB prediction error:             0.0922
```

this shows that the model is succesful with the OOB prediction error of about 0.09. This number is rather abstract so we can also check what is the actual classification accuracy using hard classes:


```r
m.s0 <- ranger(fm.s, rm.s, mtry=22, num.trees=150, seed=1)
m.s0
#> Ranger result
#> 
#> Call:
#>  ranger(fm.s, rm.s, mtry = 22, num.trees = 150, seed = 1) 
#> 
#> Type:                             Classification 
#> Number of trees:                  150 
#> Sample size:                      155 
#> Number of independent variables:  157 
#> Mtry:                             22 
#> Target node size:                 1 
#> Variable importance mode:         none 
#> OOB prediction error:             10.32 %
```

which shows that the classification or mapping accuracy for hard classes is about 90%. We can produce predictions of probabilities per class by running:


```r
pred.soil_rfc = predict(m.s, cbind(meuse.grid@data, grid.dist0@data), type="se")
pred.grids = meuse.grid["soil"]
pred.grids@data = do.call(cbind, list(pred.grids@data, 
                                      data.frame(pred.soil_rfc$predictions),
                                      data.frame(pred.soil_rfc$se)))
names(pred.grids) = c("soil", paste0("pred_soil", 1:3), paste0("se_soil", 1:3))
str(pred.grids@data)
#> 'data.frame':	3103 obs. of  7 variables:
#>  $ soil      : Factor w/ 3 levels "1","2","3": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ pred_soil1: num  0.716 0.713 0.713 0.693 0.713 ...
#>  $ pred_soil2: num  0.246 0.256 0.256 0.27 0.256 ...
#>  $ pred_soil3: num  0.0374 0.0307 0.0307 0.0374 0.0307 ...
#>  $ se_soil1  : num  0.1806 0.1692 0.1692 0.0901 0.1692 ...
#>  $ se_soil2  : num  0.145 0.0807 0.0807 0.0793 0.0807 ...
#>  $ se_soil3  : num  0.0391 0.039 0.039 0.0391 0.039 ...
```

where `pred_soil1` is the probability of occurrence of class 1 and `se_soil1` is the standard error of prediction for the `pred_soil1` based on the Jackknife-after-Bootstrap method [@wager2014confidence]. The first column in `pred.grids` contains existing map of `soil` with hard classes only.

<div class="figure" style="text-align: center">
<img src="figures/Fig_comparison_uncertainty_Factor_variables_meuse.png" alt="Predictions of soil types for the meuse data set based on the RFsp: (above) probability for three soil classes, and (below) derived standard errors per class." width="90%" />
<p class="caption">(\#fig:comparison-uncertainty-Factor)Predictions of soil types for the meuse data set based on the RFsp: (above) probability for three soil classes, and (below) derived standard errors per class.</p>
</div>

Spatial prediction of binomial and factor-type variables is straight forward with ranger / RFsp: buffer distance and spatial-autocorrelation can be incorporated at once. Compare with geostatistical packages where link functions and/or indicator kriging would need to be used, and which requires that variograms are fitted per class.

## Summary points

In summary, MLA's are fairly attractive for soil mapping and soil modelling problems in general as they often perform better than standard linear models (already recognized by @moran2002spatial and @Henderson2004Geoderma; some recent comparisons of MLA's performance for operational soil mapping can be found in @nussbaum2018evaluation). MLA's often perform better than linear techniques for soil mapping possibily due to the following three reasons:

 1. Non-linear relationships between soil forming factors and soil properties can be efficiently modeled using MLA's,
 2. Tree-based MLA's (random forest, gradient boosting, cubist) are suitable for representing *local* soil-landscape relationships, which is often important for accuracy of spatial prediction models,
 3. In the case of MLA, statistical properties such as multicolinearity and non-Gaussian distribution are dealt with inside the models, which simplifies statistical modeling steps,

On the other hand MLA's can be computationally very intensive and hence require careful planning, especially as the number of points goes beyond few thousand and number of covariates beyond a dozen. Note also that some MLA's such as for example Support Vector Machines (`svm`) is computationally very intensive and is probably not suited for large data sets.

Within PSM, there is increasing interest in doing ensemble predictions, 
model averages or model stacks. Stacking models can improve upon
individual best techniques, achieving improvements of up to 30%, with
the additional costs including only higher computation loads
[@michailidis2017investigating]. In the example above, the extensive
computational load from derivation of models and product predictions had
already obtained improved accuracies, making increasing computing loads
further a matter of diminishing returns. Some interesting Machine Learning Algortims for soil mapping based on regression include: Random Forest [@Biau2016], 
Gradient Boosting Machine (GBM) [@hastie2009elements], Cubist [@kuhn2014cubist], 
Generalized Boosted Regression Models [@ridgeway2010gbm], Support Vector Machines [@chang2011libsvm],
and the Extreme Gradient Boosting approach available via the xgboost package [@2016arXiv160302754C].
None of this techniques is universally the best spatial predictor for all soil variables,
instead we recommend comparing MLA's using robust cross-validation methods as explained above.
Also combining MLA's into ensemble predictions might not be beneficial at all. 
Less is better sometimes.

The RFsp method seems to be suitable for generating spatial and spatiotemporal predictions. 
Computing time, however, can be a cumbersome and working with data sets with $\gg 1000$ 
point locations (hence 1000+ buffer distance maps) is problably not yet recommended. 
Also cross-validation of accuracy of predictions produced using RFsp needs to be 
implemented using leave-location-out CV to account for spatial autocorrelation in data. 
The key to the success of the RFsp framework might be the training data quality — 
especially quality of spatial sampling (to minimize extrapolation problems and any 
type of bias in data), and quality of model validation (to ensure that accuracy is 
not effected by overfitting). For all other details about RFsp refer to @Hengl2018RFsp.
