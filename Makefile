SHELL = /bin/bash

CJC = cjc
CPM = cjpm

MODULE_NAME = circuitscj
BUILD_DIR = build
BIN_DIR = bin
MODULE_DIR = $(BUILD_DIR)/$(MODULE_NAME)
SRC_DIR = src
DOT_DIR = dot
DOCS_DIR = docs
DOCS_OUT = $(DOCS_DIR)/_build

MIDDLE_EXT = cjo

CPM_FLAGS = --verbose --incremental

MODULE_RESOLVE_JSON = module-resolve.json

# All the dot files in dot/
DOTS = $(shell if [ -d "$(DOT_DIR)" ]; then find dot/*.dot 2> /dev/null ; fi)
# Dot svgs
DOTS_SVGS = $(foreach dot, $(DOTS), $(dot).svg)
# Dot pngs
DOTS_PNGS = $(foreach dot, $(DOTS), $(dot).png)

.PHONY: main build dot dotpng docs clean cleandot cleandocs

main: build

build:
	$(CPM) build $(CPM_FLAGS)

docs: $(DOCS_BUILD)
	cd docs && make html

# Make all the dot graphs
dot: $(DOTS_SVGS)

# Make all the dot graphs
dotpng: $(DOTS_PNGS)

clean:
	$(CPM) clean

cleandot:
	rm -f $(DOT_DIR)/*.dot $(DOT_DIR)/*.svg $(DOT_DIR)/*.png

cleandocs:
	rm -rf $(DOCS_OUT)

cleanall: clean cleandot cleandocs

# Draw a dot graph
$(DOT_DIR)/%.svg: $(DOT_DIR)/%
	dot -Tsvg $(DOT_DIR)/$* -O

$(DOT_DIR)/%.png: $(DOT_DIR)/%
	dot -Tpng $(DOT_DIR)/$* -O
