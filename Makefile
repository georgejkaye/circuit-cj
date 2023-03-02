CJC = cjc
CPM = cpm

MODULE_NAME = circuitscj
BUILD_DIR = build
BIN_DIR = bin
MODULE_DIR = $(BUILD_DIR)/$(MODULE_NAME)
SRC_DIR = src
DOT_DIR = dot

MIDDLE_EXT = cjo

CPM_FLAGS = --verbose --incremental

MODULE_RESOLVE_JSON = module-resolve.json

# All the dot files in dot/
DOTS = $(shell find $(DOT_DIR)/*.dot)
# Dot svgs
DOTS_SVGS = $(foreach dot, $(DOTS), $(dot).svg)
# Dot pngs
DOTS_PNGS = $(foreach dot, $(DOTS), $(dot).png)

.PHONY: main build clean dot dotpng

main: build

build:
	$(CPM) build $(CPM_FLAGS)

# Make all the dot graphs
dot: $(DOTS_SVGS)

# Make all the dot graphs
dotpng: $(DOTS_PNGS)

clean:
	$(CPM) clean

cleandot:
	rm -f dot/*.dot dot/*.svg dot/*.png

# Draw a dot graph
$(DOT_DIR)/%.svg: $(DOT_DIR)/%
	dot -Tsvg $(DOT_DIR)/$* -O

$(DOT_DIR)/%.png: $(DOT_DIR)/%
	dot -Tpng $(DOT_DIR)/$* -O
