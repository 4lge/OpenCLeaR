.PHONY: RdFiles source

all:

clean:
	rm -f src/*.o src/*.so src/*~
	rm -f src/backend/src/*.so src/backend/src/*.o src/backend/src/*~

dist-clean: clean
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
	rm -rf src/backend/lib \
  src/backend/OpenCL_CLHPP-prefix/ \
  src/backend/OpenCL_Headers-prefix/ \
  src/backend/build/ \
  src/backend/lib/ \
	vignettes/OpenCLeaR-Overview.md \
	vignettes/OpenCLeaR-Overview.log


NAMESPACE: NAMESPACE.in
	cp NAMESPACE.in NAMESPACE
	@echo "Starte dynamischen Roxygen-Lösch-Prozess..."
	Rscript -e "pkgload::load_all('.'); if (file.exists('NAMESPACE')) file.remove('NAMESPACE'); roxygen2::roxygenise(package.dir = '.',roclets='namespace')"

src/RcppExports.cpp: src/*.cpp
	Rscript -e "Rcpp::compileAttributes()"

RdFiles: dist-clean
	Rscript -e "roxygen2::roxygenise(package.dir = '.',roclets='rd')"

vignettes/OpenCLeaR-Overview.md: vignettes/OpenCLeaR-Overview.Rmd
		cd vignettes; Rscript -e "rmarkdown::render(\"OpenCLeaR-Overview.Rmd\", output_format = \"md_document\")"

source: dist-clean
	(cd ..; R CMD build OpenCLeaR)
