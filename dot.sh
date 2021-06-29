#!/bin/bash

ROOT=`pwd`
DOT="$ROOT/dot"

cd $DOT

draw_dot() {
    dot -T$2 $1 -O
    CODE=$?
    if [ "$CODE" != "0" ] ; then
        echo "Error $CODE, aborting..."
        exit 1
    fi
}

for FILE in *.dot ; do 
    echo "Drawing svg graph from $FILE"
    draw_dot $FILE "svg"
    echo "Drawing png graph from $FILE"
    draw_dot $FILE "png"
done

cd $ROOT