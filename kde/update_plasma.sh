#!/bin/env bash

# Get maintainers repo
read -p "Enter your AerynOS recipe fork's URL: " fork

UPDATE_BASE=${HOME}/Documents/contribs/plasma
UPDATE_REPO="${UPDATE_BASE}/$(echo $fork | awk -F'/' '{ print $NF }')"
LOG_DIR=${HOME}/Documents/contribs/plasma/logs
DATE=$(date +%Y-%m-%d)
cwd=$(pwd)
LIST=$cwd/plasma.lst
LIST=$cwd/plasma_build.lst

# Create the update repo if it doesn't exist
if [ ! -d "$UPDATE_REPO" ]; then
  mkdir -pv $UPDATE_BASE
  cd $UPDATE_BASE
  git clone $fork
fi

# Create the log directory if it doesn't exist
if [ ! -d "$LOG_DIR" ]; then
  mkdir -pv $LOG_DIR/$DATE
fi

# If the base LOG_DIR exists, check to see if the log directory for today exists
if [ ! -d "${LOG_DIR}/$DATE" ]; then
  mkdir -pv $LOG_DIR/$DATE
fi

LOG_DIR=$LOG_DIR/$DATE

# Create the log files
failure_log="${LOG_DIR}/$DATE-package-failures.log"
success_log="${LOG_DIR}/$DATE-package-successes.log"

touch $failure_log $success_log

cd $UPDATE_REPO

# Create a unique branch in the update repo
#git checkout main
#git pull -r https://github.com/aerynos/recipes.git main
#git push
#git checkout -b $DATE-plasma-update

while read pkg; do
  cd $UPDATE_REPO/${pkg:0:1}/$pkg
  echo "Calling 'boulder up'"
  echo "Current folder: $(pwd)"
  boulder up stone.yaml -y
  echo "Calling 'boulder up' done"
  
  if [[ "$?" == "0" ]]; then
    version=$(cat stone.yaml | grep version | awk '{ print $3 }' | sed 's/\"//g')
    echo "Building: $pkg $version"
    boulder build --profile local-x86_64 -u
    if [[ "$?" == "0" ]]; then
      just mv-local
      notify-send "Successful Build" "$pkg successfully built; please review"
      echo "$pkg: $version" >> $success_log
    else
      notify-send "Failed Build" "$pkg failed to build; please review"
      echo "$pkg: $version" >> $failure_log
      exit
    fi
  else
    notify-send "Failed Package Update" "$pkg failed to update!"
    version=$(cat stone.yaml | grep version | awk '{ print $3 }' | sed 's/\"//g')
    echo "$pkg: $version" >> $failure_log
    exit
  fi
done < $LIST
