#!/bin/bash
set -o errexit -o nounset
BASE_REPO=$PWD

update_website() {
  cd ..; mkdir gh-pages; cd gh-pages
  git init
  git config user.name "jn"
  git config user.email "tupiszakaczki@gmail.com"
  git config --global push.default simple
  git remote add upstream "https://$GH_TOKEN@github.com/Envirometrix/PredictiveSoilMapping.git"
  git fetch upstream 2>err.txt
  git checkout gh-pages
  
  cp -fvr $BASE_REPO/docs/* .
  # git add *.html; git add libs/; git add figures/; git add style.css; git add images/;
  # git add *.json; git add main.md;
  # git add *.pdf; git add *.epub
  git add --all;
  git commit -a -m "Updating book (${TRAVIS_BUILD_NUMBER})"
  git status
  git push 2>err.txt
  cd ..
}

update_website
