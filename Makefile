CJC = cjc
SRC_DIR = src
MAIN = main
SRC_EXT = cj
MAINFILE = $(SRC_DIR)/$(MAIN).$(SRC_EXT)

BUILD_DIR = circuits
OPTS = -g
PKG_OPT = --package
LIB_OPT = -c
MOD_NAME_OPT = --module-name
MOD_NAME = circuits
OUTPUT_OPT = --output
OUT_EXT = out
MIDDLE_EXT = o
DOT_DIR = dot
LEGACY_DIR = legacy

# All the directories contained in src/
PACKAGES = $(foreach pkg, $(shell find $(SRC_DIR)/* -name $(LEGACY_DIR) -prune -o -type d -print), $(notdir $(pkg)))
# The corresponding object files for each package
OBJS = $(foreach pkg, $(PACKAGES),$(BUILD_DIR)/$(pkg).$(MIDDLE_EXT))
# All the dot files in dot/
DOTS = $(shell find $(DOT_DIR)/*.dot)
# Dot svgs
DOTS_SVGS = $(foreach dot, $(DOTS), $(dot).svg)
# Dot pngs
DOTS_PNGS = $(foreach dot, $(DOTS), $(dot).png)

.PHONY: all prep main clean library cleandot $(PACKAGES) dot dotpng

all: prep $(PACKAGES) main

# Build all packages in src/
library: $(PACKAGES)
# Build the main file src/main.cj
main: $(MAIN).$(OUT_EXT)

# Make all the dot graphs
dot: $(DOTS_SVGS)

# Make all the dot graphs
dotpng: $(DOTS_PNGS)

cleandot:
	rm -f $(DOT_DIR)/*

# Clean up
clean:
	rm -rf $(BUILD_DIR) $(MAIN).$(OUT_EXT)
	rm -f $(DOT_DIR)/*svg
	rm -f $(DOT_DIR)/*png

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.SECONDEXPANSION:

# Build a package in src/
$(PACKAGES): $(BUILD_DIR)/$$@.$(MIDDLE_EXT)

# Build an object file in circuits/
$(BUILD_DIR)/%.$(MIDDLE_EXT): $(BUILD_DIR) $$(shell python dependencies.py $(BUILD_DIR) $(SRC_DIR) $(MIDDLE_EXT) $$*) $$(shell find $(SRC_DIR)/$$*/*${SRC_EXT})
	@echo "Building $*"
	$(CJC) $(OPTS) $(LIB_OPT) $(PKG_OPT) $(SRC_DIR)/$* $(MOD_NAME_OPT) $(MOD_NAME) $(OUTPUT_OPT) $(MOD_NAME)/

# Build the main.out file
$(MAIN).$(OUT_EXT): $$(shell python dependencies.py $(BUILD_DIR) $(SRC_DIR) $(MIDDLE_EXT)) $(SRC_DIR)/$(MAIN).$(SRC_EXT)
	$(CJC) $(OPTS) $(shell find $(BUILD_DIR)/*.$(MIDDLE_EXT)) $(SRC_DIR)/$(MAIN).$(SRC_EXT) $(OUTPUT_OPT) $(MAIN).$(OUT_EXT)

# Draw a dot graph
$(DOT_DIR)/%.svg: $(DOT_DIR)/%
	dot -Tsvg $(DOT_DIR)/$* -O

$(DOT_DIR)/%.png: $(DOT_DIR)/%
	dot -Tpng $(DOT_DIR)/$* -O
