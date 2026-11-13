.PHONY: RdFiles source vignettes vignette-intro vignette-mcmc

VIGNETTE_RMDS  := $(wildcard vignettes/*.Rmd)
VIGNETTE_HTMLS := $(patsubst vignettes/%.Rmd,inst/doc/%.html,$(VIGNETTE_RMDS))



all:

clean:
	rm -f src/*.o src/*.so src/*~
	rm -f src/backend/src/*.so src/backend/src/*.o src/backend/src/*~
	rm -rf src/backend/lib 
	rm -f inst/bin/ocl*
	# Lokale Artefakte in vignettes/ löschen
	rm -rf vignettes/.cl_cache
	rm -f vignettes/*.html vignettes/*.R
	find . -name .cl_cache -exec rm -rf {} \; -print

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


NAMESPACE: NAMESPACE.in src/RcppExports.cpp
	cp NAMESPACE.in NAMESPACE
	@echo "Starting Roxygen delete process..."
	LD_LIBRARY_PATH="$(PWD)/src:$(PWD)/inst/lib:$(PWD)/src/backend/build:$(LD_LIBRARY_PATH)" Rscript -e "pkgload::load_all('.'); if (file.exists('NAMESPACE')) file.remove('NAMESPACE'); roxygen2::roxygenise(package.dir = '.',roclets='namespace')"

src/RcppExports.cpp: src/*.cpp 
	@echo " Starting Rcpp::compileAttributes()..."
	Rscript -e "Rcpp::compileAttributes()"

RdFiles: src/RcppExports.cpp dist-clean
	@echo "Generate Rd documentation via Roxygen2 with temporary LD_LIBRARY_PATH..."
	LD_LIBRARY_PATH="$(PWD)/src:$(PWD)/inst/lib:$(PWD)/src/backend/build:$(LD_LIBRARY_PATH)" Rscript -e "roxygen2::roxygenise(package.dir = '.', roclets='rd')"


# Baut alle Vignetten (nutzt die Pattern-Rule unten)
vignettes: $(VIGNETTE_HTMLS)

# Bequeme Kurznamen für einzelne Rechner
vignette-intro: inst/doc/OpenCLeaR_Introduction_Vignette.html
vignette-mcmc: inst/doc/OpenCLeaR_MCMC_Vignette.html

# Pattern-Rule: baut genau EINE Vignette aus vignettes/<Name>.Rmd
inst/doc/%.html: vignettes/%.Rmd
	mkdir -p inst/doc
	@echo "Processing vignette: $*..."
	Rscript -e "rmarkdown::render('$<', output_dir='inst/doc')"
	Rscript -e "knitr::purl('$<', output=file.path('inst/doc', '$*.R'))"
	@title=$$(grep -m 1 "^title:" "$<" | sed -E 's/^title:[[:space:]]*["'\'']?(.*)["'\'']?/\1/' || echo "$*"); \
	[ -z "$$title" ] && title="$*"; \
	echo "%\\VignetteIndexEntry{$$title}" > inst/doc/$*.html.asis; \
	echo "%\\VignetteEngine{knitr::rmarkdown}" >> inst/doc/$*.html.asis; \
	echo "%\\VignetteEncoding{UTF-8}" >> inst/doc/$*.html.asis

# Builds the source package (.tar.gz) directly via devtools in the parent directory (..)
# vignettes=TRUE ensures that devtools builds the vignettes cleanly and generates the index.
source: 
	if [ -f /opt/intel/oneapi/setvars.sh ]; then \
		. /opt/intel/oneapi/setvars.sh; \
	fi; \
	Rscript -e "devtools::build(pkg = '.', path = '..', vignettes = FALSE)"

cleanchars:
	perl -i -pe 's/[^\x00-\x7F]//g' R/OpenCLeaR-package.R R/debug.R R/nmath.R
