#!/bin/bash

CANGJIE_ROOT=$1
CORE="$CANGJIE_ROOT/build/build/modules/core/core.cjo"

if [ -f "$CORE" ] ; then
    echo "Found core library at $CORE, continuing..."
else 
    echo "Core library not found at $CORE, aborting..."
    exit 1
fi

echo

IMPORTS="import.conf"
OBJS=""

rm -rf build/
rm -rf bin/
mkdir build
mkdir bin
rm -f $IMPORTS
touch $IMPORTS

printf "core=$CORE\n" >> $IMPORTS

compile_package() {
    echo "Building package $1..."
    BUILD_DIR="build/$1"
    SRC_DIR="src/$1"
    mkdir $BUILD_DIR
    COMMAND="cjc -import-config $IMPORTS -c -p $SRC_DIR -o $BUILD_DIR" 
    echo $COMMAND
    $COMMAND
    CODE=$?
    if [ "$CODE" != "0" ] ; then
        echo "Error $CODE, aborting..."
        exit 1
    fi
    OBJ=$BUILD_DIR/$1.o
    CJO=$BUILD_DIR/$1.cjo
    OBJS="$OBJS $OBJ"
    printf "$1=$CJO\n" >> $IMPORTS
    echo
}

compile_exec() { 
    echo "Building executable $1..."
    SRC="src/$1.cj"
    COMMAND="cjc -import-config $IMPORTS $OBJS src/$1.cj -o bin/$1.out"
    echo $COMMAND
    $COMMAND
    CODE=$?
    if [ "$CODE" != "0" ] ; then
        echo "Error $CODE, aborting..."
        exit 1
    fi
    echo
}

compile_package "hypergraphs"
compile_exec "main"