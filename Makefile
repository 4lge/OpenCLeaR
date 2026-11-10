.PHONY: RdFiles source vignettes

all:

clean:
	rm -f src/*.o src/*.so src/*~
	rm -f src/backend/src/*.so src/backend/src/*.o src/backend/src/*~
	rm -rf src/backend/lib 
	rm -f inst/bin/ocl*
	# Lokale Artefakte in vignettes/ löschen
	rm -rf vignettes/.cl_cache
	rm -f vignettes/*.html vignettes/*.R

dist-clean: clean
	find . -name \*SFConflict\* -delete
	find . -name \*.orig -delete
	find . -name \*.rej -delete
	find . -name \*.o -delete
	find . -name \*.a -delete
	find . -name \*.obj -delete
	find . -name \*.so -delete
	find . -name \*.dll -delete
	find . -name \*.dylib -delete
	find . -name \*~ -delete
	rm -rf 	src/backend/CMakeFiles/ 
	rm -rf 	.cl_cache
	rm -rf 	inst/tinytest/.cl_cache
	rm -rf inst/include/*
	rm -rf inst/tinytest/.cl_cache
	rm -f src/backend/CMakeCache.txt
	rm -f src/backend/CMakeFiles/
	rm -rf src/backend/lib \
  src/backend/OpenCL_CLHPP-prefix/ \
  src/backend/OpenCL_Headers-prefix/ \
  src/backend/build/ \
  src/backend/lib/ \
	vignettes/OpenCLeaR-Overview.md \
	vignettes/OpenCLeaR-Overview.log
	# Installierte Dokumente aufräumen
	#rm -rf inst/doc


NAMESPACE: NAMESPACE.in src/RcppExports.cpp
	cp NAMESPACE.in NAMESPACE
	@echo "Starting Roxygen delete process..."
	LD_LIBRARY_PATH="$(PWD)/src:$(PWD)/inst/lib:$(PWD)/src/backend/build:$(LD_LIBRARY_PATH)" Rscript -e "pkgload::load_all('.'); if (file.exists('NAMESPACE')) file.remove('NAMESPACE'); roxygen2::roxygenise(package.dir = '.',roclets='namespace')"

src/RcppExports.cpp: src/*.cpp 
	@echo "🔄 Starte Rcpp::compileAttributes()..."
	Rscript -e "Rcpp::compileAttributes()"

RdFiles: src/RcppExports.cpp dist-clean
	@echo "Generate Rd documentation via Roxygen2 with temporary LD_LIBRARY_PATH..."
	LD_LIBRARY_PATH="$(PWD)/src:$(PWD)/inst/lib:$(PWD)/src/backend/build:$(LD_LIBRARY_PATH)" Rscript -e "roxygen2::roxygenise(package.dir = '.', roclets='rd')"


vignettes: vignettes/OpenCLeaR_MCMC_Vignette.Rmd
	# Verzeichnisse anlegen
	mkdir -p inst/doc
	# Direkt nach inst/doc rendern, damit R den Index dort findet
	Rscript -e "rmarkdown::render('vignettes/OpenCLeaR_MCMC_Vignette.Rmd', output_dir='inst/doc')"
	# Den R-Code extrahieren und nach inst/doc legen
	Rscript -e "knitr::purl('vignettes/OpenCLeaR_MCMC_Vignette.Rmd', output='inst/doc/OpenCLeaR_MCMC_Vignette.R')"
	# WICHTIG: Erzeugt die zwingend erforderliche .html.asis Datei für R's Vignette-Engine
	echo "%\VignetteIndexEntry{OpenCLeaR: GPGPU-Accelerated MCMC Sampling}" > inst/doc/OpenCLeaR_MCMC_Vignette.html.asis
	echo "%\VignetteEngine{knitr::rmarkdown}" >> inst/doc/OpenCLeaR_MCMC_Vignette.html.asis
	echo "%\VignetteEncoding{UTF-8}" >> inst/doc/OpenCLeaR_MCMC_Vignette.html.asis

source: 
	# Baut das Quellpaket (.tar.gz) direkt über devtools im übergeordneten Verzeichnis (..)
	# vignettes=TRUE sorgt dafür, dass devtools die Vignetten sauber baut und den Index generiert.
	if [ -f /opt/intel/oneapi/setvars.sh ]; then \
		. /opt/intel/oneapi/setvars.sh; \
	fi; \
	Rscript -e "devtools::build(pkg = '.', path = '..', vignettes = FALSE)"

cleanchars:
	perl -i -pe 's/[^\x00-\x7F]//g' R/OpenCLeaR-package.R R/debug.R R/nmath.R
