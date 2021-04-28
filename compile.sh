#!/bin/bash

ROOT=`pwd`
BUILD="$ROOT/build"
SRC="$ROOT/src"
BIN="$ROOT/bin"
DOT="$DOT/dot"

IMPORTS="$ROOT/import.conf"
OBJS=""

MAIN="main"
PACKAGES=("hypergraphs" "examples")
PKGNO=${#PACKAGES[@]}

rm -rf $BUILD
rm -rf $BIN
mkdir $BUILD
mkdir $BIN
rm -f $IMPORTS
touch $IMPORTS

compile_package() {
    echo "Building package $1 ($2/$3)"
    BUILD_DIR="$BUILD/$1"
    SRC_DIR="$SRC/$1"
    mkdir $BUILD_DIR
    cjc -import-config $IMPORTS $OBJS -c -p $SRC_DIR -o $BUILD_DIR
    CODE=$?
    if [ "$CODE" != "0" ] ; then
        echo "Error $CODE, aborting..."
        exit 1
    fi
    OBJ=$BUILD_DIR/$1.o
    CJO=$BUILD_DIR/$1.cjo
    OBJS="$OBJS $OBJ"
    printf "$1=$CJO\n" >> $IMPORTS
}

compile_exec() { 
    echo "Building executable $1 ($2/$3)"
    SRC="$SRC/$1.cj"
    OUT="$BIN/$1.out"
    cjc -import-config $IMPORTS $OBJS $SRC -o $OUT
    CODE=$?
    if [ "$CODE" != "0" ] ; then
        echo "Error $CODE, aborting..."
        exit 1
    fi
}

i=1
for p in ${PACKAGES[@]} ; do
    compile_package $p $i $(($PKGNO+1))
    (( i++ ))
done

compile_exec $MAIN $i $(($PKGNO+1))