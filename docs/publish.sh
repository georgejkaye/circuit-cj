#!/bin/bash

REPO_URL=https://gitee.com/HW-PLLab/circuit-cj.git
REPO_NAME=circuit-cj
DOCS_BRANCH=docs
DOCS_MAKE_TARGET=docs
DOCS_BUILD=docs/_build

GITEE_EMAIL="george.kaye1@huawei.com"
GITEE_NAME="George Kaye"

DATE=$(date +"%Y-%m-%dT%T")
TEMP_DIR=$REPO_NAME-$DATE

# Make temp dir
mkdir $TEMP_DIR
cd $TEMP_DIR

# Clone the repo
git clone $REPO_URL $REPO_NAME
cd $REPO_NAME

# Set up user details for this repo
git config user.email $GITEE_EMAIL
git config user.name $GITEE_NAME

# Make the docs
make $DOCS_MAKE_TARGET

# Copy docs out of repo
cp -r $DOCS_BUILD/html ..

# Switch to docs branch
git switch $DOCS_BRANCH

# Delete old docs
rm -rf *

# Move new docs back in
mv ../html/* .

# Commit
git add .
git commit -m "Docs as of $DATE"
git push

# Delete temp dir
cd ../..
rm -rf $TEMP_DIR