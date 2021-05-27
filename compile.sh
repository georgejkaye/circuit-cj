#!/bin/bash

ROOT=`pwd`
BUILD="$ROOT/build"
SRC="$ROOT/src"
BIN="$ROOT/bin"
DOT="$DOT/dot"
CJ_ROOT=$1

MODULES_DIR="$CJ_ROOT/build/build/modules"

IO_MODULE="$MODULES_DIR/io"
IO_O="$IO_MODULE/cangjieIO.o"
IO_CJO="$IO_MODULE/io.cjo"

IMPORTS="$ROOT/import.conf"
OBJS="$IO_O"

MAIN="main"
PACKAGES=("settings" "debug" "circuits" "examples")

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

if [ "$#" == "1" ] ; then
    MODE="all"
else
    MODE="$2"
fi

CURRENT_PKG=1

if [ "$MODE" == "all" ] ; then 
    rm -rf $BUILD
    rm -rf $BIN
    mkdir $BUILD
    mkdir $BIN
    rm -f $IMPORTS
    touch $IMPORTS

    TOTAL_PKG=${#PACKAGES[@]}

    printf "io=$IO_CJO\n" >> $IMPORTS
    
    for p in ${PACKAGES[@]} ; do
        compile_package $p $CURRENT_PKG $((TOTAL_PKG+1))
        (( CURRENT_PKG++ ))
    done
else 
    for p in ${PACKAGES[@]} ; do 
        OBJS="$OBJS $BUILD/$p/$p.o"
    done
fi

if [ "$MODE" == "main" ] ; then
    TOTAL_PKG=0
fi

compile_exec $MAIN $CURRENT_PKG $(($TOTAL_PKG+1))