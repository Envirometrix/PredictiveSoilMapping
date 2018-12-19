html:
	Rscript -e 'bookdown::render_book("index.Rmd", output_format = "bookdown::gitbook", clean = FALSE)'
	cp -fvr css/style.css docs/
	# cp -fvr images _book/
	cp -fvr _main.utf8.md docs/main.md

build:
	make html
	Rscript -e 'browseURL("_book/index.html")'

pdf:
	Rscript -e 'bookdown::render_book("index.Rmd", output_format = "bookdown::pdf_book")'

md:
	Rscript -e 'bookdown::render_book("index.Rmd", output_format = "bookdown::pdf_book", clean = FALSE)'
	
all:
	Rscript -e 'bookdown::render_book("index.Rmd", output_format = "bookdown::gitbook")'
	cp -fvr css/style.css docs/
	Rscript -e 'bookdown::render_book("index.Rmd", output_format = "bookdown::pdf_book", output_file = "psm.pdf")'
	Rscript -e 'bookdown::render_book("index.Rmd", output_format = "bookdown::epub_book", output_file = "psm.epub")'

install:
	Rscript -e 'devtools::install_github("nowosad/PSMpkg")'

deploy:
	Rscript -e 'bookdown::publishdocs(render="local", account="thengl")'

clean:
	Rscript -e "bookdown::clean_book(TRUE)"
	rm -fvr *.log Rplots.pdf _bookdown_files land.sqlite3

cleaner:
	make clean && rm -fvr rsconnect
	rm -frv *.aux *.out  *.toc # Latex output
	rm -fvr *.html # rogue html files
	rm -fvr *utf8.md # rogue md files
