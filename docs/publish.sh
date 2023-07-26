#!/bin/bash

REPO_URL=https://gitee.com/HW-PLLab/circuit-cj.git
REPO_NAME=circuit-cj
DOCS_BRANCH=docs
DOCS_MAKE_TARGET=docs
DOCS_BUILD=docs/build

DATE=$(date +"%Y-%m-%dT%T")

mkdir $DATE
cd $DATE
git clone $REPO_URL .$REPO_NAME
cd .circuit-cj
make $DOCS_MAKE_TARGET
cp -r $DOCS_BUILD/html ..
git switch $DOCS_BRANCH
rm -rf *
mv ../html/* .
git add .
git commit -m "Docs as of "
git push

cd ..
rm -rf $DATE