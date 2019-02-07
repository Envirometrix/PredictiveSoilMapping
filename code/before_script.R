## Needed for Rscript
library("methods")
library("microbenchmark")
library("knitr")

knitr::opts_chunk$set(
  comment = "#>",
  collapse = TRUE,
  cache = TRUE, 
  fig.pos = "H",
  fig.align = "center",
  fig.show = "hold",
  out.width = "100%",
  tidy = TRUE,
  tidy.opts = list(blank = FALSE, width.cutoff = 100)
)
set.seed(2016)
options(digits = 3)
options(dplyr.print_min = 4, dplyr.print_max = 4)
options(knitr.graphics.auto_pdf = TRUE)

figs.lst = list.files("figures", pattern=glob2rx("*.pdf$"), full.names = TRUE)
for(i in 1:length(figs.lst)){ if(!file.exists(gsub(".pdf", ".png", figs.lst[i]))) system(paste0("convert -density 200 ", figs.lst[i], " -quality 90 ", gsub(".pdf", ".png", figs.lst[i]))) }
#for(i in 1:length(figs.lst)){ if(!file.exists(gsub(".pdf", ".png", figs.lst[i]))) system(paste0('inkscape \"', figs.lst[i], '\" -z --export-dpi=200 --export-area-drawing --export-png="', gsub(".pdf", ".png", figs.lst[i]), '"')) }
