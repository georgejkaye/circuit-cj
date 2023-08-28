#!/bin/bash

REPO_DIR=$1
GITEE_EMAIL="$2"
GITEE_NAME="$3"

DOCS_BRANCH=docs
DEVELOP_BRANCH=dev
DOCS_MAKE_TARGET=docs
DOCS_BUILD=docs/_build

DATE=$(date +"%Y-%m-%d %T")
TEMP_DIR=$DATE

# Make temp dir
mkdir $TEMP_DIR
cd $TEMP_DIR

# Copy the repo to avoid messing up current working directory
cp -r $REPO_DIR .
cd "${REPO_DIR##*/}"

# Reset to head
git switch $DEVELOP_BRANCH
git fetch
git reset --hard origin/$DEVELOP_BRANCH

# Set up user details for this repo
git config user.email $GITEE_EMAIL
git config user.name $GITEE_NAME

# Make the docs
make $DOCS_MAKE_TARGET

# Copy docs out of repo
cp -r $DOCS_BUILD/html ..

# Switch to docs branch
git switch $DOCS_BRANCH
git fetch
git reset --hard origin/$DOCS_BRANCH

# Delete old docs
rm -rf *

# Move new docs back in
mv ../html/* .

# Commit
git add .
git commit -m "Docs as of $DATE"
git push --set-upstream origin $DOCS_BRANCH

# Delete temp dir
cd ../..
rm -rf $TEMP_DIR