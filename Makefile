CJC = cjc

MODULE_NAME = circuitscj
BUILD_DIR = build
BIN_DIR = bin
MODULE_DIR = $(BUILD_DIR)/$(MODULE_NAME)
SRC_DIR = src
DOT_DIR = dot

MIDDLE_EXT = cjo

FLAGS = -g

MODULE_RESOLVE_JSON = module-resolve.json

# All the directories contained in src/
PACKAGES = $(foreach pkg, $(shell find $(SRC_DIR)/* -name $(LEGACY_DIR) -prune -o -type d -print), $(MODULE_NAME)/$(notdir $(pkg)))
# The corresponding object files for each package
OBJS = $(foreach pkg, $(PACKAGES),$(BUILD_DIR)/$(pkg).$(MIDDLE_EXT))
# All the dot files in dot/
DOTS = $(shell find $(DOT_DIR)/*.dot)
# Dot svgs
DOTS_SVGS = $(foreach dot, $(DOTS), $(dot).svg)
# Dot pngs
DOTS_PNGS = $(foreach dot, $(DOTS), $(dot).png)

.PHONY: main clean dot dotpng clean

main: $(BIN_DIR)/main.out

# Make all the dot graphs
dot: $(DOTS_SVGS)

# Make all the dot graphs
dotpng: $(DOTS_PNGS)

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(BIN_DIR)
	rm -f $(MODULE_RESOLVE_JSON)
	rm -f *bc
	rm -f dot/*svg dot/*png
	rm -f log.*.txt

# Make the directories

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(MODULE_DIR):
	mkdir -p $(MODULE_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

.SECONDEXPANSION:

$(BUILD_DIR)/$(MODULE_NAME)/%.cjo: $$(shell find $(SRC_DIR)/$$*/*.cj) $$(shell python dependencies.py --package $$*) | $(MODULE_DIR)
	$(CJC) $(FLAGS) --import-path $(BUILD_DIR) -p $(SRC_DIR)/$(basename $(notdir $@)) --module-name $(MODULE_NAME) --output-type=staticlib -o $(MODULE_DIR)/lib$(MODULE_NAME)_$(basename $(notdir $@)).a

$(BIN_DIR)/main.out: $(SRC_DIR)/main.cj $$(shell python dependencies.py --package default) | $(MODULE_DIR) $(BIN_DIR)
	$(CJC) $(FLAGS) --import-path $(BUILD_DIR) -p $(SRC_DIR) --module-name $(MODULE_NAME) $(foreach PKG,$(shell python dependencies.py --order),-L $(MODULE_DIR) -l$(MODULE_NAME)_$(notdir $(PKG))) --output-dir $(BIN_DIR) -o main.out

# make a cjo file
$(PACKAGES): $(BUILD_DIR)/$$@.cjo

# Draw a dot graph
$(DOT_DIR)/%.svg: $(DOT_DIR)/%
	dot -Tsvg $(DOT_DIR)/$* -O

$(DOT_DIR)/%.png: $(DOT_DIR)/%
	dot -Tpng $(DOT_DIR)/$* -O
