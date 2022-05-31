CJC = cjc
SRC = src
MAIN = main
SRC_EXT = cj
MAINFILE = $(SRC)/$(MAIN).$(SRC_EXT)

BUILD = circuits
PKG_OPT = --package
LIB_OPT = -c
MOD_NAME_OPT = --module-name
MOD_NAME = circuits
OUTPUT_OPT = --output
LIBS = -lcangjie-collection -lcangjie-core -lcangjie-ffi.c
OUT_EXT = out
MIDDLE_EXT = o

PACKAGES = settings debug syntax graphs
OBJS = $(foreach pkg, $(PACKAGES),circuits/$(pkg).$(MIDDLE_EXT))

SOURCES = $(foreach pkg, $(PACKAGES),$(wildcard src/$(pkg)/*cj))

CURRENT_PKG = $(notdir $(basename $@))
CURRENT_PKG_SOURCES = $(wildcard src/$(CURRENT_PKG)/*cj) 

.PHONY: all prep main clean library

all: prep $(OBJS) main

library: prep $(OBJS)

prep: $(SOURCES) $(MAINFILE)
	@mkdir -p $(BUILD)

$(OBJS): $(SOURCES)
	$(CJC) $(LIB_OPT) $(PKG_OPT) $(SRC)/$(notdir $(basename $@)) $(MOD_NAME_OPT) $(MOD_NAME) $(OUTPUT_OPT) $(MOD_NAME)	

main: $(MAINFILE)
	$(CJC) $(LIBS) $(OBJS) $(SRC)/$(MAIN).cj $(OUTPUT_OPT) $(MAIN).$(OUT_EXT)

clean:
	rm -rf $(BUILD) $(MAIN).$(OUT_EXT)

test:
	echo $(SOURCES)