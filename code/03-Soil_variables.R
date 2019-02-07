## ----soil-vars, echo=FALSE, fig.cap="Types of soil observations in relation to data usage and production costs. Descriptive soil observations (e.g. manual texture or diagnostic soil horizons) are often not directly useable by end users, who are often more interested in specific secondary soil properties (e.g. water holding capacity, erosion index, soil fertility) as inputs to their modeling. However, descriptive field observations are often orders of magnitude more affordable to obtain than laboratory analysis.", out.width="65%", out.extra="angle=0"----
knitr::include_graphics("figures/Fig_types_observations.png")

## Soil can be assessed quantitatively based on direct or indirect

## ----soi-var-depth, echo=FALSE, fig.cap="Soil observations can refer to genetic horizons (left), fixed depths i.e. point support (center) and/or can refer to aggregate values for the complete profile (right).", out.width="70%"----
knitr::include_graphics("figures/Fig_soi_var_depth.png")

## ----scheme-solum, echo=FALSE, fig.cap="Standard soil horizons, solum thickness and depth to bedrock (left) vs six standard depths used in the GlobalSoilMap project (right).", out.width="75%"----
knitr::include_graphics("figures/Fig_scheme_solum.png")

## ----globalsoilmap, echo=FALSE-------------------------------------------
knitr::kable(
  head(read.csv("extdata/globalsoilmap_specs.csv", header = TRUE, stringsAsFactors = FALSE), 10), booktabs = TRUE,
  caption = 'The GlobalSoilMap project has selected seven primary (depth to bedrock, organic carbon content, pH, soil texture fractions, coarse fragments), three derived (effective soil depth, bulk density and available water capacity) and two optional (effective cation exchange capacity and electrical conductivity) target soil properties of interest for global soil mapping and modelling.'
)

## ---- tidy=TRUE----------------------------------------------------------
library(GSIF)
data(soil.legends)
str(soil.legends)

## <Placemark> <Point>

## ----scheme-depth-to-bedrock, echo=FALSE, fig.cap="Depth to bedrock for censored and uncensored observations. Image source: Shangguan et al. (2017) doi: 10.1002/2016MS000686.", out.width="100%"----
knitr::include_graphics("figures/Fig_depth_2_bedrock.png")

## Depth to bedrock is the mean distance to `R` horizon (layer

## ----rootingdepths, echo=FALSE-------------------------------------------
knitr::kable(
  head(read.csv("extdata/maximum_rooting_depth.csv", header = TRUE, stringsAsFactors = FALSE), 10), booktabs = TRUE, 
  caption = 'Summary of maximum rooting depth by biome (after Canadell et al. (1996)). MMRD = Mean maximum rooting depth in m; HVRD = Highest value for rooting depth in m.'
  )

## ----lri-scheme, echo=FALSE, fig.cap="Derivation of the Limiting Rooting Index: (left) soil pH values and corresponding LRI, (right) coarse fragments and corresponding LRI. Based on Leenaars et al. (2018) doi: 10.1016/j.geoderma.2018.02.046.", out.width="90%"----
knitr::include_graphics("figures/Fig_LRI_scheme.png")

## ------------------------------------------------------------------------
## sample profile from Nigeria (ISRIC:NG0017):
UHDICM = c(0, 18, 36, 65, 87, 127)
LHDICM = c(18, 36, 65, 87, 127, 181)
SNDPPT = c(66, 70, 54, 43, 35, 47)
SLTPPT = c(13, 11, 14, 14, 18, 23)
CLYPPT = c(21, 19, 32, 43, 47, 30)
CRFVOL = c(17, 72, 73, 54, 19, 17)
BLD = c(1.57, 1.60, 1.52, 1.50, 1.40, 1.42)*1000
PHIHOX = c(6.5, 6.9, 6.5, 6.2, 6.2, 6.0)
CEC = c(9.3, 4.5, 6.0, 8.0, 9.4, 10.9)
ENA = c(0.1, 0.1, 0.1, 0.1, 0.1, 0.2)
EACKCL = c(0.1, 0.1, 0.1, NA, NA, 0.5)
EXB = c(8.9, 4.0, 5.7, 7.4, 8.9, 10.4)
ORCDRC = c(18.4, 4.4, 3.6, 3.6, 3.2, 1.2)
x <- LRI(UHDICM=UHDICM, LHDICM=LHDICM, SNDPPT=SNDPPT, 
   SLTPPT=SLTPPT, CLYPPT=CLYPPT, CRFVOL=CRFVOL, 
   BLD=BLD, ORCDRC=ORCDRC, CEC=CEC, ENA=ENA, EACKCL=EACKCL, 
   EXB=EXB, PHIHOX=PHIHOX, print.thresholds=TRUE)
x
## Most limiting: BLD.f and CRFVOL, but nothing < 20

## ------------------------------------------------------------------------
sel <- x==FALSE
if(!all(sel==FALSE)){ 
  UHDICM[which(sel==TRUE)[1]] 
} else {
  max(LHDICM)
}

xI <- attr(x, "minimum.LRI")
## derive Effective rooting depth:
ERDICM(UHDICM=UHDICM, LHDICM=LHDICM, minimum.LRI=xI, DRAINFAO="M")

## Soil Organic Carbon is one of the key measures of soil health.

## ----sprofs-soil-carbon, echo=FALSE, fig.cap="Histogram and soil-depth density distribution for a global compilation of measurements of soil organic carbon content (ORCDRC) in permilles. Based on the records from WOSIS (http://www.earth-syst-sci-data.net/9/1/2017/). The log-transformation is used to ensure close-to-normal distribution in the histogram.", out.width="90%"----
knitr::include_graphics("figures/Fig_sprofs_ORCDRC.png")

## ----sprops-phiho5, echo=FALSE, fig.cap="Histogram and soil-depth density distribution for a global compilation of measurements of soil pH (suspension of soil in H2O). Based on the records from WOSIS (http://www.earth-syst-sci-data.net/9/1/2017/).", out.width="100%"----
knitr::include_graphics("figures/Fig_sprofs_PHIHO5.png")

## ----sprops-phikcl, echo=FALSE, fig.cap="Histogram and soil-depth density distribution for a global compilation of measurements of soil pH (suspension of soil in KCl). Based on the records from WOSIS (http://www.earth-syst-sci-data.net/9/1/2017/).", out.width="100%"----
knitr::include_graphics("figures/Fig_sprofs_PHIKCL.png")

## ----color-legend-phi, echo=FALSE, fig.cap="Histogram for soil pH and connected color legend available via the GSIF package. Color breaks in the legend have been selected using histogram equalization (i.e. by using constant quantiles) to ensure maximum contrast in the output maps.", out.width="85%"----
knitr::include_graphics("figures/Fig_color_legend_PHI.png")

## ------------------------------------------------------------------------
ph_h2o = 7.2
0.918*ph_h2o-0.3556

## Soil pH is negative decimal logarithm of the hydrogen ion activity in a

## Nitrogen, Phosphorus and Potassium are the three relatively mobile and

## ----sprofs-crfvol, echo=FALSE, fig.cap="Histogram and soil-depth density distribution for a global compilation of measurements of coarse fragments in percent. Based on the records from WOSIS (http://www.earth-syst-sci-data.net/9/1/2017/). This variable in principle follows a zero inflated distribution.", out.width="90%"----
knitr::include_graphics("figures/Fig_sprofs_CRFVOL.png")

## ----texture-limits, echo=FALSE, fig.cap="Particle size limits used in European countries, Australia and America. Image source: Minasny and McBratney (2001) doi: 10.1071/SR00065.", out.width="85%"----
knitr::include_graphics("figures/Fig_texture_limits_Minasny2001.jpg")

## ----sprofs-snd, echo=FALSE, fig.cap="Histogram and soil-depth density distribution for a global compilation of measurements of sand content in percent. Based on the records from WOSIS (http://www.earth-syst-sci-data.net/9/1/2017/).", out.width="90%"----
knitr::include_graphics("figures/Fig_sprofs_SNDPPT.png")

## ----sprofs-slt, echo=FALSE, fig.cap="Histogram and soil-depth density distribution for a global compilation of measurements of silt content in percent. Based on the records from WOSIS (http://www.earth-syst-sci-data.net/9/1/2017/).", out.width="90%"----
knitr::include_graphics("figures/Fig_sprofs_SLTPPT.png")

## ----sprofs-cly, echo=FALSE, fig.cap="Histogram and soil-depth density distribution for a global compilation of measurements of clay content in percent. Based on the records from WOSIS (http://www.earth-syst-sci-data.net/9/1/2017/).", out.width="90%"----
knitr::include_graphics("figures/Fig_sprofs_CLYPPT.png")

## The most commonly used standard for designation of fine earth texture

## ----usdafaotexture, echo=FALSE------------------------------------------
knitr::kable(
  head(read.csv("extdata/usda_fao_texture_limits.csv", header = TRUE, stringsAsFactors = FALSE)), booktabs = TRUE,
  caption = 'Differences between the International, USDA and ISO/FAO particle size classifications.'
)

## Bulk density is the oven-dry mass of soil material divided by the total

## ----sprofs-bld, echo=FALSE, fig.cap="Histogram and soil-depth density distribution for a global compilation of measurements of bulk density (tonnes per cubic metre). Based on the records from WOSIS (http://www.earth-syst-sci-data.net/9/1/2017/).", out.width="90%"----
knitr::include_graphics("figures/Fig_sprofs_BLD.png")

## ----ocs-calculus-scheme, echo=FALSE, fig.cap="Soil organic carbon stock calculus scheme. Example of how total soil organic carbon stock (OCS), and its propagated error, can be estimated for a given volume of soil using organic carbon content (ORC), bulk density (BLD), thickness of horizon (HOT), and percentage of coarse fragments (CRF). Image source: Hengl et al. (2014) doi: 10.1371/journal.pone.0169748. OCSKGM function also available via the GSIF package.", out.width="100%"----
knitr::include_graphics("figures/Fig_OCS_calculus_scheme.png")

## ------------------------------------------------------------------------
Area <- 1E4  ## 1 ha
HSIZE <- 30 ## 0--30 cm
ORCDRC <- 50  ## 5%
ORCDRC.sd <- 10  ## +/-1%
BLD <- 1500  ## 1.5 tonnes per cubic meter
BLD.sd <- 100  ## +/-0.1 tonnes per cubic meter
CRFVOL <- 10  ## 10%
CRFVOL.sd <- 5  ## +/-5%         
x <- OCSKGM(ORCDRC, BLD, CRFVOL, HSIZE, ORCDRC.sd, BLD.sd, CRFVOL.sd)
x  ## 20.25 +/-4.41 kg/m^2
x[[1]] * Area / 1000 ## in tonnes per ha:

## ----available-soil-water, echo=FALSE, fig.cap="Example of a soil-water plot. Actual water content can be measured using soil moisture probes i.e. automated sensor networks.", out.width="100%"----
knitr::include_graphics("figures/Fig_available_soil_water.png")

## The AWC is expressed in mm (which equals mm water/cm soil depth, or

## Available water capacity (expressed in mm of water for the effective

## ------------------------------------------------------------------------
SNDPPT = 30 
SLTPPT = 25 
CLYPPT = 48 
ORCDRC = 23 
BLD = 1200 
CEC = 12 
PHIHOX = 6.4
x <- AWCPTF(SNDPPT, SLTPPT, CLYPPT, ORCDRC, BLD, CEC, PHIHOX)
str(x)
attr(x, "coef")

## ----usdatexturec, echo=FALSE--------------------------------------------
knitr::kable(
  head(read.csv("extdata/usda_texture_classes.csv", header = TRUE, stringsAsFactors = FALSE), 12), booktabs = TRUE,
  caption = 'Simple conversion of the USDA texture-by-hand classes to texture fractions (sd indicates estimated standard deviation).'
)

## Soil observations, such as observation of texture-by-hand class, are

## USDA's Soil Taxonomy is probably the most developed soil classification system in the world. Its use is highly recommended also because all documents, databases and guidelines are publicly available without restrictions.

## ----worldmap-suborders, echo=FALSE, fig.cap="The USDA-NRCS map of the Keys to Soil Taxonomy soil suborders of the world at 20 km. The map shows the distribution of 12 soil orders. The original map also contains assumed distributions for suborders e.g. Histels, Udolls, Calcids, and similar. Projected in the Robinson projection commonly used to display world maps.", out.width="100%"----
knitr::include_graphics("figures/Fig_worldmap_suborders.png")

## ----barplot-suborders, echo=FALSE, fig.cap="(ref:barplot-suborders)", out.width="100%"----
knitr::include_graphics("figures/Fig_barplot_suborders.png")

## ----usda-categories, echo=FALSE, fig.cap="USDA classification system and approximate minimum number of observations required to fit a global multinomial regression model.", out.width="60%", out.extra="angle=0"----
knitr::include_graphics("figures/Fig_USDA_categories.png")

## ----plot-tt-triangle,fig.height=8, fig.width=8, out.width="70%", fig.cap="Soil texture triangle based on the USDA system. Generated using the soiltexture package (http://cran.r-project.org/web/packages/soiltexture/)."----
library(soiltexture)
TT.plot(class.sys = "USDA.TT")

## ------------------------------------------------------------------------
TT.classes.tbl(class.sys="USDA.TT", collapse=", ")

## ------------------------------------------------------------------------
vert <- TT.vertices.tbl(class.sys = "USDA.TT")
vert$x <- 1-vert$SAND+(vert$SAND-(1-vert$SILT))*0.5
vert$y <- vert$CLAY*sin(pi/3)
USDA.TT <- data.frame(TT.classes.tbl(class.sys = "USDA.TT", collapse = ", "))
TT.pnt <- as.list(rep(NA, length(USDA.TT$name)))
poly.lst <- as.list(rep(NA, length(USDA.TT$name)))

## ------------------------------------------------------------------------
library(sp)
for(i in 1:length(USDA.TT$name)){
  TT.pnt[[i]] <- as.integer(strsplit(unclass(paste(USDA.TT[i, "points"])), ", ")[[1]])
  poly.lst[[i]] <- vert[TT.pnt[[i]],c("x","y")]
  ## add extra point:
  pp <- Polygon(rbind(poly.lst[[i]], poly.lst[[i]][1,]))
  poly.lst[[i]] <- sp::Polygons(list(pp), ID=i)
}

## ------------------------------------------------------------------------
poly.sp <- SpatialPolygons(poly.lst, proj4string=CRS(as.character(NA)))
poly.USDA.TT <- SpatialPolygonsDataFrame(poly.sp, 
                      data.frame(ID=USDA.TT$name), match.ID=FALSE)

## ------------------------------------------------------------------------
slot(slot(poly.USDA.TT, "polygons")[[1]], "labpt")

## ------------------------------------------------------------------------
get.TF.from.XY <- function(df, xcoord, ycoord) {
  df$CLAY <- df[,ycoord]/sin(pi/3)
  df$SAND <- (2 - df$CLAY - 2 * df[,xcoord]) * 0.5
  df$SILT <- 1 - (df$SAND + df$CLAY)
  return(df)
}

## ------------------------------------------------------------------------
USDA.TT.cnt <- data.frame(t(sapply(slot(poly.USDA.TT, "polygons"), slot, "labpt")))
USDA.TT.cnt$name <- poly.USDA.TT$ID
USDA.TT.cnt <- get.TF.from.XY(USDA.TT.cnt, "X1", "X2")
USDA.TT.cnt[,c("SAND","SILT","CLAY")] <- signif(USDA.TT.cnt[,c("SAND","SILT","CLAY")], 2)
USDA.TT.cnt[,c("name","SAND","SILT","CLAY")]

## ------------------------------------------------------------------------
sim.Cl <- data.frame(spsample(poly.USDA.TT[poly.USDA.TT$ID=="clay",], 
                              type="random", n=100))
sim.Cl <- get.TF.from.XY(sim.Cl, "x", "y")
sd(sim.Cl$SAND); sd(sim.Cl$SILT); sd(sim.Cl$CLAY)

## ------------------------------------------------------------------------
require(GSIF)
data(afsp)
tdf <- afsp$horizons[,c("CLYPPT", "SLTPPT", "SNDPPT")]
tdf <- tdf[!is.na(tdf$SNDPPT)&!is.na(tdf$SLTPPT)&!is.na(tdf$CLYPPT),]
tdf <- tdf[runif(nrow(tdf))<.15,]
tdf$Sum <- rowSums(tdf)
for(i in c("CLYPPT", "SLTPPT", "SNDPPT")) { tdf[,i] <- tdf[,i]/tdf$Sum * 100 }
names(tdf)[1:3] <- c("CLAY", "SILT", "SAND")

## ----plot-tt-afsis, fig.height=8, fig.width=8, out.width="70%", fig.cap="Distribution of observed soil textures for the Africa Soil Profiles."----
TT.plot(class.sys = "USDA.TT", tri.data = tdf, 
        grid.show = FALSE, pch="+", cex=.4, col="red")

## ------------------------------------------------------------------------
load("extdata/munsell_rgb.rdata")
library(colorspace)
munsell.rgb[round(runif(1)*2350, 0),]

## ------------------------------------------------------------------------
as(colorspace::RGB(R=munsell.rgb[1007,"R"]/255, 
                   G=munsell.rgb[1007,"G"]/255, 
                   B=munsell.rgb[1007,"B"]/255), "HSV")

## ------------------------------------------------------------------------
aqp::munsell2rgb(the_hue = "10B", the_value = 2, the_chroma = 12)

## ------------------------------------------------------------------------
grDevices::col2rgb("#003A7CFF")

## ------------------------------------------------------------------------
plotKML::col2kml("#003A7CFF")

## ------------------------------------------------------------------------
data(afsp)
head(afsp$horizons[!is.na(afsp$horizons$MCOMNS),"MCOMNS"])

## ------------------------------------------------------------------------
mcol <- plyr::join(afsp$horizons[,c("SOURCEID","MCOMNS","UHDICM","LHDICM")],
                   afsp$sites[,c("SOURCEID","LONWGS84","LATWGS84")])
mcol <- mcol[!is.na(mcol$MCOMNS),]
str(mcol)

## ------------------------------------------------------------------------
mcol$Munsell <- sub(" ", "", sub("/", "_", mcol$MCOMNS))
hue.lst <- expand.grid(c("2.5", "5", "7.5", "10"),
                       c("YR","GY","BG","YE","YN","YY","R","Y","B","G"))
hue.lst$mhue <- paste(hue.lst$Var1, hue.lst$Var2, sep="")
for(j in hue.lst$mhue[1:28]){
  mcol$Munsell <- sub(j, paste(j, "_", sep=""), mcol$Munsell, fixed=TRUE)
}
mcol$depth <- mcol$UHDICM + (mcol$LHDICM-mcol$UHDICM)/2
mcol.RGB <- merge(mcol, munsell.rgb, by="Munsell")
str(mcol.RGB)

## ------------------------------------------------------------------------
mcol.RGB <- mcol.RGB[!is.na(mcol.RGB$R),]
mcol.RGB$Rc <- round(mcol.RGB$R/255, 3)
mcol.RGB$Gc <- round(mcol.RGB$G/255, 3)
mcol.RGB$Bc <- round(mcol.RGB$B/255, 3)
mcol.RGB$col <- rgb(mcol.RGB$Rc, mcol.RGB$Gc, mcol.RGB$Bc)
mcol.RGB <- mcol.RGB[mcol.RGB$depth>0 & mcol.RGB$depth<30 & !is.na(mcol.RGB$col),]
coordinates(mcol.RGB) <- ~ LONWGS84+LATWGS84

## ----plot-af-soil-cols, fig.width=5, fig.cap="Actual observed soil colors (moist) for the top soil based on the Africa Soil Profiles Database."----
load("extdata/admin.af.rda")
proj4string(admin.af) <- "+proj=longlat +datum=WGS84"
country <- as(admin.af, "SpatialLines")
par(mar=c(.0,.0,.0,.0), mai=c(.0,.0,.0,.0))
plot(country, col="darkgrey", asp=1)
points(mcol.RGB, pch=21, bg=mcol.RGB$col, col="black")

## ------------------------------------------------------------------------
library(plyr)
library(aqp)
lon = 3.90; lat = 7.50; id = "ISRIC:NG0017"; FAO1988 = "LXp"
top = c(0, 18, 36, 65, 87, 127)
bottom = c(18, 36, 65, 87, 127, 181)
ORCDRC = c(18.4, 4.4, 3.6, 3.6, 3.2, 1.2)
hue = c("7.5YR", "7.5YR", "2.5YR", "5YR", "5YR", "10YR")
value = c(3, 4, 5, 5, 5, 7); chroma = c(2, 4, 6, 8, 4, 3)
## prepare a SoilProfileCollection:
prof1 <- plyr::join(data.frame(id, top, bottom, ORCDRC, hue, value, chroma),  
              data.frame(id, lon, lat, FAO1988), type='inner')
prof1$soil_color <- with(prof1, aqp::munsell2rgb(hue, value, chroma))
depths(prof1) <- id ~ top + bottom
site(prof1) <- ~ lon + lat + FAO1988
coordinates(prof1) <- ~ lon + lat
proj4string(prof1) <- CRS("+proj=longlat +datum=WGS84")
prof1

## ---- eval=FALSE---------------------------------------------------------
## plotKML(prof1, var.name="ORCDRC", color.name="soil_color")

## ----soil-profile-plot, echo=FALSE, fig.cap="Soil profile from Nigeria plotted in Google Earth with actual observed colors.", out.width="70%"----
knitr::include_graphics("figures/soil_profile_plot.png")

## ------------------------------------------------------------------------
library(randomForestSRC)
library(ggRandomForests)
library(ggplot2)
library(scales)
load("extdata/sprops.wise.rda")
str(SPROPS.WISE)

## ------------------------------------------------------------------------
bd.fm = as.formula("BLD ~ ORCDRC + PHIHOX + SNDPPT + CLYPPT + CRFVOL + DEPTH")
rfsrc_BD <- rfsrc(bd.fm, data=SPROPS.WISE)
rfsrc_BD

## ----bulk-density-ptf, echo=FALSE, fig.cap="Bulk density as a function of organic carbon, pH, sand and clay content, coarse fragments and depth.", out.width="100%"----
knitr::include_graphics("figures/bulk_density_ptf_plots.png")

## ------------------------------------------------------------------------
predict(rfsrc_BD, data.frame(ORCDRC=1.2, PHIHOX=7.6, 
                  SNDPPT=45, CLYPPT=12, CRFVOL=0, DEPTH=20))$predicted

## ------------------------------------------------------------------------
predict(rfsrc_BD, data.frame(ORCDRC=150, PHIHOX=4.6, 
                  SNDPPT=25, CLYPPT=35, CRFVOL=0, DEPTH=20))$predicted

## ------------------------------------------------------------------------
load("extdata/wise_tax.rda")
str(WISE_tax)

## ------------------------------------------------------------------------
leg <- read.csv("extdata/taxousda_greatgroups.csv")
str(leg)

## ------------------------------------------------------------------------
x.PHIHOX <- aggregate(SPROPS.WISE$PHIHOX, 
                      by=list(SPROPS.WISE$SOURCEID), 
                      FUN=mean, na.rm=TRUE); names(x.PHIHOX)[1] = "SOURCEID"
x.CLYPPT <- aggregate(SPROPS.WISE$CLYPPT, 
                      by=list(SPROPS.WISE$SOURCEID), 
                      FUN=mean, na.rm=TRUE); names(x.CLYPPT)[1] = "SOURCEID"
WISE_tax$PHIHOX <- plyr::join(WISE_tax, x.PHIHOX, type="left")$x
WISE_tax$CLYPPT <- plyr::join(WISE_tax, x.CLYPPT, type="left")$x

## ------------------------------------------------------------------------
sel.tax = complete.cases(WISE_tax[,c("TAXNWRB","PHIHOX","CLYPPT","TAXOUSDA")])
WISE_tax.sites <- WISE_tax[sel.tax,]
WISE_tax.sites$TAXOUSDA.f <- NA
for(j in leg$Suborder){
  sel <- grep(j, WISE_tax.sites$TAXOUSDA, ignore.case=TRUE)
  WISE_tax.sites$TAXOUSDA.f[sel] = j
}
WISE_tax.sites$TAXOUSDA.f <- as.factor(WISE_tax.sites$TAXOUSDA.f)
WISE_tax.sites$TAXNWRB <- as.factor(paste(WISE_tax.sites$TAXNWRB))

## ------------------------------------------------------------------------
TAXNUSDA.rf <- rfsrc(TAXOUSDA.f ~ TAXNWRB + PHIHOX + CLYPPT, data=WISE_tax.sites)
#TAXNUSDA.rf

## ------------------------------------------------------------------------
newdata = data.frame(TAXNWRB=factor("Calcaric Cambisol", 
                  levels=levels(WISE_tax.sites$TAXNWRB)), 
                  PHIHOX=7.8, CLYPPT=12)
x <- data.frame(predict(TAXNUSDA.rf, newdata, type="prob")$predicted)
x[,order(1/x)[1:2]]

