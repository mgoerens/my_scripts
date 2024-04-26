#!/bin/bash

echo "> Syncing fork with upstream"

## Get default branch
DEFAULT_BRANCH=$(git remote show upstream | awk '/HEAD branch/ {print $NF}')
echo "> Default branch: $DEFAULT_BRANCH"

echo "> Stash changes if needed"
stash=0
git status --porcelain | grep "^." | grep -v "^?" >/dev/null
if [ $? -eq 0 ]; then
  git stash
  stash=1
fi

echo "> Checkout default branch"
git switch $DEFAULT_BRANCH

git fetch --all

echo "> Rebase default branch on upstream"
git rebase upstream/$DEFAULT_BRANCH

echo "> Printing status"
git status

echo "> Push default branch to origin"
git push

echo "> Checkout previous branch"
git switch -

echo "> Pop stashed changes, if needed"
if [ $stash -eq 1 ]; then
  git stash pop
fi

echo "> Done syncing fork"


#echo $PWD
