SHELL = /bin/bash

CPM = cjpm
CPM_FLAGS = --verbose --incremental

BUILD_DIR = build
DOCS_DIR = docs
DOCS_OUT = $(DOCS_DIR)/_build


.PHONY: main build docs clean cleandocs

main: build

build:
	$(CPM) build $(CPM_FLAGS)

docs: $(DOCS_BUILD)
	cd docs && make html

clean:
	$(CPM) clean

cleandot:
	rm -f $(DOT_DIR)/*.dot $(DOT_DIR)/*.svg $(DOT_DIR)/*.png

cleandocs:
	rm -rf $(DOCS_OUT)

cleanall: clean cleandot cleandocs