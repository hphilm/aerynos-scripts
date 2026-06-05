#!/bin/env bash

### IMPORTANT!
# Make sure that you are in the root of your packaging repo before you run this script!
repo_root=$(pwd)
LIST=$repo_root/kde-gear.lst

while read pkg; do
  # Change to the top directory in the git status list
  pkg_dir=${pkg:0:1}/$pkg
  echo "Changing directory to: {$pkg_dir}"
  cd $pkg_dir
  git add .
  pkg_name=$pkg
  vers=$(cat stone.yaml | grep version | awk '{ print $3 }' | sed 's/\"//g')
  git commit -m "${pkg_name}: Update to v${vers}"
  cd $repo_root
done < $LIST
