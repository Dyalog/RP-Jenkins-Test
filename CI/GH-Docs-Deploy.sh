#!/bin/bash
set -e

WORKSPACE=${WORKSPACE-$PWD}
cd ${WORKSPACE}
VERSION=`cat ___version___ | grep -o "[0-9]\+\.[0-9]\+"`
REPO=`cat ___repo___`

echo "running mike deploy for ${VERSION}"

git config user.name "Jenkins CI Publisher"
git config user.email "RPJenkinsCI@github.com"

git remote set-url origin https://$GHTOKEN@github.com/${REPO}.git

mike build ${VERSION}
mike set-default ${VERSION}
mike alias --push ${VERSION} latest
