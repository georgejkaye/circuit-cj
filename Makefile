CJC = cjc
SRC = src
MAIN = main
BUILD = circuits
PKG_OPT = --package
LIB_OPT = -c
MOD_NAME_OPT = --module-name
MOD_NAME = circuits
OUTPUT_OPT = --output
LIBS = -lcangjie-collection -lcangjie-core -lcangjie-ffi.c
OUT_EXT = out
MIDDLE_EXT = o

PACKAGES = settings debug
OBJS = $(foreach pkg, $(PACKAGES),circuits/$(pkg).$(MIDDLE_EXT))

.PHONY: all prep main clean library

all: prep $(OBJS) main

library: prep $(OBJS)

prep:
	mkdir -p $(BUILD)

$(OBJS):
	$(CJC) $(LIB_OPT) $(PKG_OPT) $(SRC)/$(notdir $(basename $@)) $(MOD_NAME_OPT) $(MOD_NAME) $(OUTPUT_OPT) $(MOD_NAME)	

main:
	$(CJC) $(LIBS) $(OBJS) $(SRC)/$(MAIN).cj $(OUTPUT_OPT) $(MAIN).$(OUT_EXT)

clean:
	rm -rf $(BUILD) $(MAIN).$(OUT_EXT)