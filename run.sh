#!/bin/bash

ROOT=`pwd`
BIN="$ROOT/bin"
DOT="$ROOT/dot"
OUT="main"

if [ ! -d $DOT ] ; then
    mkdir $DOT
fi

rm -f $DOT/*

if [ "$1" == "hack" ] ; then
    EXE="$ROOT/build/circuits/$OUT"
else
    EXE="$ROOT/bin/$OUT.out"
fi

# run executable
echo "Running $EXE"
$EXE
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