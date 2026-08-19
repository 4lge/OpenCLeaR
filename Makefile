.PHONY: RdFiles source

# automates some house cleaning tasks

all:

clean:
	@echo "clean up ..."
	rm -f src/*.o src/*.so src/*~
	rm -f src/backend/src/*.so src/backend/src/*.o src/backend/src/*~

dist-clean: clean
	@echo "clean up all temporary stuff ..."
	find . -name \*SFConflict\* -delete
	find . -name \*.orig -delete
	find . -name \*.rej -delete
	find . -name \*.o -delete
	find . -name \*.obj -delete
	find . -name \*.so -delete
	find . -name \*.dll -delete
	find . -name \*.dylib -delete
	find . -name \*~ -delete
	rm -rf 	src/backend/CMakeFiles/ 
	rm -rf inst/include/*
	rm -f src/backend/CMakeCache.txt
	rm -f src/backend/CMakeFiles/
	rm -rf src/backend/lib/ 
	rm -rf src/backend/OpenCL_CLHPP-prefix/ 
	rm -rf src/backend/OpenCL_Headers-prefix/
	rm -rf src/backend/build/ 
	rm -rf src/backend/lib/ 
	rm -f vignettes/OpenCLeaR-Overview.md 
	rm -f vignettes/OpenCLeaR-Overview.log


NAMESPACE: NAMESPACE.in
	@echo "run roxygen to recreate NAMESPACE ..."
	cp inst/NAMESPACE.in NAMESPACE
	Rscript -e "pkgload::load_all('.'); if (file.exists('NAMESPACE')) file.remove('NAMESPACE'); roxygen2::roxygenise(package.dir = '.',roclets='namespace')"

src/RcppExports.cpp: src/*.cpp
	@echo "rebuild Rcpp exports ..."
	Rscript -e "Rcpp::compileAttributes()"

RdFiles: dist-clean
	@echo "run roxygen to recreate help pages ..."
	Rscript -e "roxygen2::roxygenise(package.dir = '.',roclets='rd')"

vignettes/OpenCLeaR-Overview.md: vignettes/OpenCLeaR-Overview.Rmd
	@echo "generate plain mardown version ov overview vignette ..."
	cd vignettes; Rscript -e "rmarkdown::render(\"OpenCLeaR-Overview.Rmd\", output_format = \"md_document\")"

source: dist-clean
	@echo "regenerate source package one directory level above ..."
	(cd ..; R CMD build OpenCLeaR)
