html:
	Rscript -e 'bookdown::renderdocs("index.Rmd", output_format = "bookdown::gitbook", clean = FALSE)'
	cp -fvr css/style.css docs/
	cp -fvr images docs/
	cp -fvr _main.utf8.md docs/main.md

build:
	make html
	Rscript -e 'browseURL("docs/index.html")'
	
pdf:
  Rscript --quiet _render.R "bookdown::pdf_book"

md:
	Rscript -e 'bookdown::renderdocs("index.Rmd", output_format = "bookdown::pdfdocs",clean=FALSE)'
	
install:
	Rscript -e 'devtools::install_github("envirometrix/PredictiveSoilMapping")'

## Deploy
deploy:
	Rscript -e 'bookdown::publishdocs(render="local", account="thengl")'

clean:
	Rscript -e "bookdown::cleandocs(TRUE)"
	rm -fvr *.log Rplots.pdf docsdown_files land.sqlite3

cleaner:
	make clean && rm -fvr rsconnect
	rm -frv *.aux *.out  *.toc # Latex output
	rm -fvr *.html # rogue html files
	
