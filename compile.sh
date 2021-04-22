#!/bin/bash

DIR="/home/gkaye/circuits-cj"
IMPORTS="$DIR/pkg.cfg1"
OBJS=""

rm -rf build/
rm -rf bin/
mkdir build
mkdir bin
rm $IMPORTS
touch $IMPORTS

printf "core=/home/gkaye/arklang-sync/build/build/modules/core/core.cjo\n" >> $IMPORTS

compile_object() {
    if [ "$2" != "" ] ; then
        BUILD_DIR="$DIR/build/$2"
        SRC_DIR="$DIR/src/$2"
        if [ ! -d $BUILD_DIR ] ; then
            mkdir $BUILD_DIR
        fi
    else
        BUILD_DIR="$DIR/build"
        SRC_DIR="$DIR/src"
    fi
        
    BASE="$BUILD_DIR/$1"
    echo "Building object $BASE.o"
    OBJ="$BASE.o"
    COMMAND="cjc -import-config $IMPORTS -c $SRC_DIR/$1.cj -o $OBJ"
    OBJS="$OBJS $OBJ"
    echo $COMMAND
    $COMMAND
    CODE=$?
    if [ "$CODE" != "0" ] ; then
        echo "Error $CODE, aborting..."
        exit 1
    fi
    CJO="$BASE.cjo"
    printf "$1=$CJO\n" >> $IMPORTS
}

compile_exec() { 
    SRC="$DIR/src/$1.cj"
    echo "Building executable $SRC"
    COMMAND="cjc -import-config $IMPORTS $OBJS $DIR/src/$1.cj -o $DIR/bin/$1.out"
    echo $COMMAND
    $COMMAND
    CODE=$?
    if [ "$CODE" != "0" ] ; then
        echo "Error $CODE, aborting..."
        exit 1
    fi
}

compile_all_objects() {
    for FILE in * ; do
        if [ "$FILE" != "main.cj" ] ; then
            if [[ -d $FILE ]] ; then
                cd $FILE
                if [ "$1" != "" ] ; then
                    PKG=$1/$FILE
                else 
                    PKG=$FILE
                fi 
                compile_all_objects $PKG
                cd ..
            else 
                FILE="${FILE%.*}"
                compile_object $FILE $1 
            fi
        fi
    done
}

python3 process.py
compile_object "code" ""
compile_exec "main"
rm src/code.cj