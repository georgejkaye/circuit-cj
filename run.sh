#!/bin/bash

ROOT=`pwd`
BIN="$ROOT/bin"
DOT="$ROOT/dot"
EXE="main"

if [ ! -d $DOT ] ; then
    mkdir $DOT
fi

rm -f $DOT/*

# run executable
echo "Running $BIN/$EXE.out"
$BIN/$EXE.out
CODE=$?
if [ "$CODE" != "0" ] ; then
    echo "Error $CODE, aborting..."
    exit 1
fi

# draw graphs

cd $DOT

for FILE in *; do 
    echo "Drawing svg graph from $FILE"
    dot -Tsvg $FILE -O
    CODE=$?
    if [ "$CODE" != "0" ] ; then
        echo "Error $CODE, aborting..."
        exit 1
    fi
done

cd $ROOT