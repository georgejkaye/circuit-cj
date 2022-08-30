CJC = cjc

MODULE_NAME = circuitscj
BUILD_DIR = build
BIN_DIR = bin
MODULE_DIR = $(BUILD_DIR)/$(MODULE_NAME)
SRC_DIR = src

MIDDLE_EXT = cjo

MODULE_RESOLVE_JSON = module-resolve.json

# All the directories contained in src/
PACKAGES = $(foreach pkg, $(shell find $(SRC_DIR)/* -name $(LEGACY_DIR) -prune -o -type d -print), $(MODULE_NAME)/$(notdir $(pkg)))
# The corresponding object files for each package
OBJS = $(foreach pkg, $(PACKAGES),$(BUILD_DIR)/$(pkg).$(MIDDLE_EXT))

.PHONY: main clean

main: $(BIN_DIR)/main.out

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(MODULE_DIR):
	mkdir -p $(MODULE_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(BIN_DIR)
	rm -f $(MODULE_RESOLVE_JSON)
	rm -f *bc
	rm -f dot/*svg dot/*png

.SECONDEXPANSION:

$(BUILD_DIR)/$(MODULE_NAME)/%.cjo: $$(shell find $(SRC_DIR)/$$*/*.cj) $$(shell python dependencies.py --package $$*) | $(MODULE_DIR)
	$(CJC) --import-path $(BUILD_DIR) -p $(SRC_DIR)/$(basename $(notdir $@)) --module-name $(MODULE_NAME) --output-type=staticlib -o $(MODULE_DIR)/lib$(MODULE_NAME)_$(basename $(notdir $@)).a

$(BIN_DIR)/main.out: $(SRC_DIR)/main.cj $$(shell python dependencies.py --package default) | $(MODULE_DIR) $(BIN_DIR)
	$(CJC) --import-path $(BUILD_DIR) -p $(SRC_DIR) --module-name $(MODULE_NAME) $(foreach PKG,$(shell python dependencies.py --order),-L $(MODULE_DIR) -l$(MODULE_NAME)_$(notdir $(PKG))) --output-dir $(BIN_DIR) -o main.out

# make a cjo file
$(PACKAGES): $(BUILD_DIR)/$$@.cjo
