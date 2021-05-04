#!/bin/bash

ROOT=`pwd`
BIN="$ROOT/bin"
DOT="$ROOT/dot"
EXE="main"

if [ ! -d $DOT ] ; then
    mkdir $DOT
fi

rm -f $DOT/$EXE.dot*
touch $DOT/$EXE.dot

# run executable
echo "Running $BIN/$EXE.out"
$BIN/$EXE.out
CODE=$?
if [ "$CODE" != "0" ] ; then
    echo "Error $CODE, aborting..."
    exit 1
fi

# draw graph
echo "Drawing svg graph from $DOT/$EXE.dot"
dot -Tsvg $DOT/$EXE.dot -O
CODE=$?
if [ "$CODE" != "0" ] ; then
    echo "Error $CODE, aborting..."
    exit 1
fi