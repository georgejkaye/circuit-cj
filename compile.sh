#!/bin/bash

rm -rf build/
rm -rf bin
mkdir build
mkdir bin

# hypergraphs
mkdir build/hypergraphs
cjc -c /home/gkaye/circuits-cj/src/hypergraphs/hypergraphs.cj -o build/hypergraphs/hypergraphs.o

# main
cjc -import-config pkg.cfg1 build/hypergraphs/hypergraphs.o src/main.cj -o bin/main.out