#!/bin/bash

ROOT=`pwd`
BUILD="$ROOT/build"
SRC="$ROOT/src"
BIN="$ROOT/bin"
DOT="$DOT/dot"

if [ "$CangJie_ROOT" == "" ] ; then
    echo "Please set \$CangJie_ROOT"
    exit
fi

CJ_ROOT="$CangJie_ROOT"
MODULES_DIR="$CJ_ROOT/build/build/modules"

IO_MODULE="$MODULES_DIR/io"
IO_O="$IO_MODULE/cangjieIO.o"
IO_CJO="$IO_MODULE/io.cjo"

IMPORTS="$ROOT/import.conf"
OBJS="$IO_O"

MODULE_NAME="circuits"

MAIN="main"

IFS=":"
read -ra PATHS <<< "$CANGJIE_PATH"

MAP_CAPACITY=200

YELLOW="\033[1;33m"
NC="\033[0m"
MAP_PATH="$CJ_ROOT/stdlib/core/Map.cj"
echo -e "${YELLOW}[WARNING]${NC} It is recommended to set DEFAULT_INITIAL_CAPACITY in $MAP_PATH to $MAP_CAPACITY in order to avoid blowing the stack when making circuits"

check_package_in_path() {
    if [[ ! " ${PATHS[@]} " =~ " $1 " ]] ; then
        echo "Package $1 not found, ensure the following are in your \$CANGJIE_PATH:"
        for p in ${PKG_PATHS} ; do 
            echo "    $p"
        done
        exit 1
    fi
}

check_local_package_in_path() {
    BUILD_DIR="$BUILD/$1" 
    check_package_in_path $BUILD_DIR
}

pre_package() {
    BUILD_DIR="$BUILD/$1"
    SRC_DIR="$SRC/$1"
    mkdir $BUILD_DIR
}

post_package(){
    OBJ="$BUILD_DIR/$1.o"
    CJO="$BUILD_DIR/$1.cjo"
    OBJS="$OBJS:$OBJ"
}

check_errors(){
    if [ "$1" != "0" ] ; then
        echo "Error $1, aborting..."
        exit 1
    fi
}

compile_package() {
    echo "Building package $1 ($2/$3)"
    pre_package $1
    cjc -c -p $SRC_DIR -o $BUILD_DIR $OBJS
    check_errors $?
    post_package $1
}

compile_package_exec() {
    echo "Building executable from package $1 ($2/$3)"
    pre_package $1
    cjc -p $SRC_DIR -o $BUILD_DIR $OBJS
    check_errors $?
    post_package $1    
}

compile_exec() { 
    echo "Building executable $1 ($2/$3)"
    SRC="$SRC/$1.cj"
    OUT="$BIN/$1.out"
    cjc $SRC -o $OUT $OBJS
    check_errors $?
}

if [ "$#" == "0" ] ; then
    MODE="all"
else
    MODE="$1"
fi

if [ "$MODE" == "hack" ] ; then
    PACKAGES=("settings" "debug")
else 
    PACKAGES=("settings" "debug" "circuits" "examples")
fi

PKG_PATHS=("$MODULES_DIR/io")

for p in ${PACKAGES} l ; do
    PKG_PATHS+=("$BUILD_DIR/$p")
done

for p in ${PKG_PATHS} ; do
     check_package_in_path $p
done

CURRENT_PKG=1

if [ "$MODE" == "all" ] || [ "$MODE" == "hack" ] ; then 
    rm -rf $BUILD
    rm -rf $BIN
    mkdir $BUILD
    mkdir $BIN
    rm -f $IMPORTS
    touch $IMPORTS

    TOTAL_PKG=${#PACKAGES[@]}

    printf "io=$IO_CJO\n" >> $IMPORTS
    
    for p in ${PACKAGES[@]} ; do
        compile_package $p $CURRENT_PKG $((TOTAL_PKG+1)) true
        (( CURRENT_PKG++ ))
    done
else 
    for p in ${PACKAGES[@]} ; do 
        OBJS="$OBJS:$BUILD/$p/$p.o"
    done
fi

if [ "$MODE" == "main" ] ; then
    TOTAL_PKG=0
fi

if [ "$MODE" == "hack" ] ; then
    compile_package_exec "circuits" $CURRENT_PKG $(($TOTAL_PKG+1)) false
else
    compile_exec $MAIN $CURRENT_PKG $(($TOTAL_PKG+1))
fi