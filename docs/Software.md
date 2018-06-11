

# Software installation and first steps {#software}

*Edited by: T. Hengl*

This section contains instruction on how to install and use software to run predictive soil mapping and export results to GIS or web applications. It has been written (as most of the book) for Linux users, but should not be too much of a problem to adopt to Microsoft Windows OS and/or Mac OS. 

## List of software in use

\begin{figure}[t]

{\centering \includegraphics[width=0.6\linewidth]{figures/software_triangle} 

}

\caption{Software combination used in this book.}(\#fig:software-triangle)
\end{figure}

For processing the covariates we used a combination of Open Source GIS
software, primarily SAGA GIS [@gmd-8-1991-2015], packages raster [@raster],
sp [@pebesma2005classes], and GDAL [@mitchell2014geospatial] for reprojecting,
mosaicking and merging tiles. GDAL and parallel packages in R are highly suitable for
processing large data.

Software (required):

*  [R](http://cran.r-project.org/bin/windows/base/) or [MRO](https///mran.microsoft.com/download/);

*  [RStudio](http://www.rstudio.com/products/RStudio/);

*  R packages: GSIF, plotKML, landgis, aqp, ranger, caret, xgboost, plyr, raster, gstat, randomForest, ggplot2, e1071 (see: [how to install R package](http://www.r-bloggers.com/installing-r-packages/))

*  [SAGA GIS](http://sourceforge.net/projects/saga-gis/) (on Windows machines run windows installer);

*  Google Earth or Google Earth Pro; 

*  [GDAL v2.x](https///trac.osgeo.org/gdal/wiki/DownloadingGdalBinaries) for Windows machines use e.g. ["gdal-*-1800-x64-core.msi"](http://download.gisinternals.com/sdk/downloads/release-1800-x64-gdal-2-1-3-mapserver-7-0-4/gdal-201-1800-x64-core.msi);

R script used in this tutorial you can download from the **[github](https://github.com/envirometrix/PredictiveSoilMapping)**. As a gentle introduction to R programming languange and soil classes in R we recommend the chapter on importing and using soil data. Some more example of SAGA GIS + R usage you can find in the soil covariates chapter. To visualize spatial predictions in a web-browser or Google Earth you could also consider following the soil web-maps tutorial. As a gentle introduction to R programming languange and spatial classes in R we recommend following [the Geocomputation with R book](https://geocompr.robinlovelace.net/). Obtaining also the [R reference card](https///cran.r-project.org/doc/contrib/Baggott-refcard-v2.pdf) is highly recommended.

## Installing software on Ubuntu OS

On Ubuntu (often the recommended standard for GIS community) main software can be installed within 10--20 minutes. We start with installing GDAL, proj4 and some packages that you might need later on:


```bash
sudo apt-get install libgdal-dev libproj-dev libjasper-dev
sudo apt-get install gdal-bin python-gdal
```

Next, we can install R and RStudio. For R studio you can use the CRAN distribution or the optimized distribution provided by (the former REvolution company; now Microsoft):


```bash
wget https://mran.blob.core.windows.net/install/mro/3.4.3/microsoft-r-open-3.4.3.tar.gz
tar -xf microsoft-r-open-3.4.3.tar.gz
cd microsoft-r-open/
sudo ./install.sh
```

Note that the R versions are constantly being updated so you will need to replace the URL based on the information provided on the home page (http://mran.microsoft.com). Once you run ```install.sh``` you will have to accept the license terms two times before the installation can be completed. If everything went succesful, you can get the session info by:


```r
sessionInfo()
#> R version 3.4.3 (2017-11-30)
#> Platform: x86_64-pc-linux-gnu (64-bit)
#> Running under: Ubuntu 16.04.4 LTS
#> 
#> Matrix products: default
#> BLAS: /opt/microsoft/ropen/3.4.3/lib64/R/lib/libRblas.so
#> LAPACK: /opt/microsoft/ropen/3.4.3/lib64/R/lib/libRlapack.so
#> 
#> locale:
#>  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
#>  [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
#>  [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
#>  [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                 
#>  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
#> [11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       
#> 
#> attached base packages:
#> [1] methods   stats     graphics  grDevices utils     datasets  base     
#> 
#> other attached packages:
#> [1] microbenchmark_1.4-2.1 RevoUtils_10.0.7       RevoUtilsMath_10.0.1  
#> 
#> loaded via a namespace (and not attached):
#>  [1] Rcpp_0.12.14     knitr_1.18       magrittr_1.5     munsell_0.4.3   
#>  [5] colorspace_1.3-2 rlang_0.1.6      stringr_1.2.0    plyr_1.8.4      
#>  [9] tools_3.4.3      grid_3.4.3       gtable_0.2.0     xfun_0.1        
#> [13] htmltools_0.3.6  yaml_2.1.16      lazyeval_0.2.1   rprojroot_1.3-1 
#> [17] digest_0.6.13    tibble_1.4.1     bookdown_0.7.12  ggplot2_2.2.1   
#> [21] codetools_0.2-15 evaluate_0.10.1  rmarkdown_1.8    stringi_1.1.6   
#> [25] compiler_3.4.3   pillar_1.0.1     scales_0.5.0     backports_1.1.2
system("gdalinfo --version")
```

This shows for example that the this installation of R is based on the Ubuntu 16.* LTS and the version of GDAL is up to date. Using an optimized distribution of R (read more about ["The Benefits of Multithreaded Performance with Microsoft R Open"](https://mran.microsoft.com/documents/rro/multithread)) is especially important if you plan to use R for production purposes i.e. to optimize computing and generation of soil maps for large amount of pixels.

To install RStudio we can run:


```bash
sudo apt-get install gdebi-core
wget https://download1.rstudio.org/rstudio-1.1.447-amd64.deb 
sudo gdebi rstudio-1.1.447-amd64.deb
sudo rm rstudio-1.1.447-amd64.deb
```

Again, RStudio is constantly updated so you might have to adjust the rstudio version and distribution.

Predictive soil mapping is about making maps, and maps require a GIS software so that one can open view overlay and analyze the maps. GIS software recommended for soil mapping in this book is SAGA GIS, QGIS, GRASS GIS and Google Earth. To install SAGA GIS on Ubuntu we can use:


```bash
sudo add-apt-repository ppa:ubuntugis/ubuntugis-unstable
sudo apt-get update
sudo apt-get install saga
```

If installation was succesful, you should be able to access SAGA command line also from R by using:


```r
system("saga_cmd --version")
```

To install QGIS (https://download.qgis.org/) you might first have to add the location of the debian libraries:


```bash
sudo sh -c 'echo "deb http://qgis.org/debian xenial main" >> /etc/apt/sources.list'  
sudo sh -c 'echo "deb-src http://qgis.org/debian xenial main " >> /etc/apt/sources.list'  
sudo apt-get update 
sudo apt-get install qgis python-qgis qgis-plugin-grass
```

Other utility software that you might need include ```htop``` that allows you to track processing progress:


```bash
sudo apt-get install htop iotop
```

and some additional libraries used be devtools, geoR and similar can be installed via:


```bash
sudo apt-get install build-essential automake; 
        libcurl4-openssl-dev pkg-config libxml2-dev;
        libfuse-dev mtools libpng-dev libudunits2-dev
```

You might also need the 7z software for easier compression and pigz for parallelized compression:


```bash
sudo apt-get install pigz zip unzip p7zip-full 
```

## RStudio {#Rstudio}

RStudio is, in principle, the main R scripting environment and can be used to control all other software used in the course. A more detailed RStudio tutorial is available at: [RStudio — Online Learning](http://www.rstudio.com/resources/training/online-learning/). Consider also following some spatial data tutorials e.g. by James Cheshire (http://spatial.ly/r/). Below is an example of RStudio session with R editor on right and R console on left.

\begin{figure}[t]

{\centering \includegraphics[width=1\linewidth]{figures/rstudio_example} 

}

\caption{RStudio is a commonly used R editor written in C++.}(\#fig:rstudio-example)
\end{figure}

To install all required R packages used in some script at once, you can use:


```r
ls <- c("rgdal", "raster", "GSIF", "plotKML", 
        "nnet", "plyr", "ROCR", "randomForest", 
        "psych", "mda", "h2o", "dismo", "grDevices", 
        "snowfall", "hexbin", "lattice", "ranger", 
        "soiltexture", "aqp", "colorspace",
        "randomForestSRC", "ggRandomForests", "scales",
        "xgboost", "parallel", "doParallel", "caret")
new.packages <- ls[!(ls %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
```

This will basically check if some package is installed already, then install it if it is missing only. You can put this line at top of each R script that you share so that anybody using that script will automatically get all missing packages.

The h2o package requires Java libraries, so you should first install Java by using e.g.:


```bash
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java8-installer
java -version
```

## plotKML and GSIF packages

Many examples in the GSIF course rely on the top 5 most commonly used packages for spatial data: (1) [sp and rgdal](https///cran.r-project.org/web/views/Spatial.html), (2) [raster](https///cran.r-project.org/web/packages/raster/), (3) [plotKML](http://plotkml.r-forge.r-project.org/) and (4) [GSIF](http://gsif.r-forge.r-project.org/). To install most up-to-date version of plotKML/GSIF, you can also use the R-Forge versions of the package:


```r
if(!require(GSIF)){
  install.packages("GSIF", repos=c("http://R-Forge.R-project.org"), 
                 type = "source", dependencies = TRUE)
}
#> Loading required package: GSIF
#> GSIF version 0.5-4 (2017-04-25)
#> URL: http://gsif.r-forge.r-project.org/
```

A copy of the most-up-to-date stable versions of plotKML and GSIF is also available on [github](https///github.com/cran/GSIF). To run only some specific function from GSIF package you could do for example:


```r
source_https <- function(url, ...) {
   # load package
   require(RCurl)
   # download:
   cat(getURL(url, followlocation = TRUE, 
       cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl")), 
       file = basename(url))
   source(basename(url))
}
source_https("https://raw.githubusercontent.com/cran/GSIF/master/R/OCSKGM.R")
```

To test if these packages work properly create soil maps and visualize them in Google Earth by running the following lines of code (see also function: [fit.gstatModel](http://gsif.r-forge.r-project.org/fit.gstatModel.html)):


```r
library(GSIF)
library(sp)
library(boot)
library(aqp)
#> This is aqp 1.15
library(plyr)
library(rpart)
library(splines)
library(gstat)
library(quantregForest)
#> Loading required package: randomForest
#> randomForest 4.6-12
#> Type rfNews() to see new features/changes/bug fixes.
#> Loading required package: RColorBrewer
library(plotKML)
#> plotKML version 0.5-9 (2017-05-15)
#> URL: http://plotkml.r-forge.r-project.org/
demo(meuse, echo=FALSE)
omm <- fit.gstatModel(meuse, om~dist+ffreq, meuse.grid, method="quantregForest")
#> Fitting a Quantile Regression Forest model...
#> Fitting a 2D variogram...
#> Saving an object of class 'gstatModel'...
om.rk <- predict(omm, meuse.grid)
#> Subsetting observations to fit the prediction domain in 2D...
#> Prediction error for 'randomForest' model estimated using the 'quantreg' package.
#> Generating predictions using the trend model (RK method)...
#> [using ordinary kriging]
#>  11% done100% done
#> Running 5-fold cross validation using 'krige.cv'...
#> Creating an object of class "SpatialPredictions"
om.rk
#>   Variable           : om 
#>   Minium value       : 1 
#>   Maximum value      : 17 
#>   Size               : 153 
#>   Total area         : 4964800 
#>   Total area (units) : square-m 
#>   Resolution (x)     : 40 
#>   Resolution (y)     : 40 
#>   Resolution (units) : m 
#>   Vgm model          : Exp 
#>   Nugget (residual)  : 2.34 
#>   Sill (residual)    : 8.32 
#>   Range (residual)   : 5760 
#>   RMSE (validation)  : 1.7 
#>   Var explained      : 75.2% 
#>   Effective bytes    : 1226 
#>   Compression method : gzip
#plotKML(om.rk)
```

\begin{figure}[t]

{\centering \includegraphics[width=0.9\linewidth]{figures/ge_preview} 

}

\caption{Example of plotKML output.}(\#fig:ge-preview)
\end{figure}

## Connecting R and SAGA GIS

SAGA GIS is an extensive GIS geoprocessor software with over [600 functions](http://www.saga-gis.org/saga_tool_doc/index.html). 
SAGA GIS can not be installed from RStudio (it is not a package for R). 
Instead, you need to install SAGA GIS using the installation instructions from the [software homepage](https///sourceforge.net/projects/saga-gis/). 
After you have installed SAGA GIS, you can send processes from 
R to SAGA GIS by using the ```saga_cmd``` command line interface:


```r
if(!Sys.info()['sysname']=="Linux"){
  saga_cmd = "C:/Progra~1/SAGA-GIS/saga_cmd.exe"
} else {
  saga_cmd = "saga_cmd"
}
system(paste(saga_cmd, "-v"))
```

To use some SAGA GIS function you need to carefully follow 
the [SAGA GIS command line arguments](http://www.saga-gis.org/saga_tool_doc/index.html). For example, 


```r
library(plotKML)
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
#> 
#> Attaching package: 'raster'
#> The following objects are masked from 'package:aqp':
#> 
#>     metadata, metadata<-
data("eberg_grid")
gridded(eberg_grid) <- ~x+y
proj4string(eberg_grid) <- CRS("+init=epsg:31467")
writeGDAL(eberg_grid["DEMSRT6"], "./extdata/DEMSRT6.sdat", "SAGA")
system(paste(saga_cmd, 'ta_lighting 0 -ELEVATION "./extdata/DEMSRT6.sgrd" 
             -SHADE "./extdata/hillshade.sgrd" -EXAGGERATION 2'))
```

\begin{figure}[t]

{\centering \includegraphics[width=1\linewidth]{figures/rstudio_saga_gis} 

}

\caption{Deriving hillshading using SAGA GIS and then visualizing the result in R.}(\#fig:rstudio-saga-gis)
\end{figure}

## Connecting R and GDAL

Another very important software for handling spatial data (and especially for exchanging / converting spatial data) is GDAL. GDAL also needs to be installed separately (for Windows machines use e.g. ["gdal-201-1800-x64-core.msi"](http://download.gisinternals.com/sdk/downloads/release-1800-x64-gdal-2-1-3-mapserver-7-0-4/gdal-201-1800-x64-core.msi)) and then can be called from command line:


```r
if(.Platform$OS.type == "windows"){
  gdal.dir <- shortPathName("C:/Program files/GDAL")
  gdal_translate <- paste0(gdal.dir, "/gdal_translate.exe")
  gdalwarp <- paste0(gdal.dir, "/gdalwarp.exe") 
} else {
  gdal_translate = "gdal_translate"
  gdalwarp = "gdalwarp"
}
system(paste(gdalwarp, "--help"))
```

We can use GDAL to reproject grid from the previous example:


```r
system('gdalwarp ./extdata/DEMSRT6.sdat ./extdata/DEMSRT6_ll.tif -t_srs \"+proj=longlat +datum=WGS84\"')
library(raster)
plot(raster("./extdata/DEMSRT6_ll.tif"))
```

\begin{figure}[t]

{\centering \includegraphics{Software_files/figure-latex/plot-eberg-ll-1} 

}

\caption{Ebergotzen DEM reprojected in geographical coordinates.}(\#fig:plot-eberg-ll)
\end{figure}
