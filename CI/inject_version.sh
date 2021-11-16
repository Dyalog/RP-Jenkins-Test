#!/bin/bash
# RP inject_version
raw_version=`cat HttpCommand.dyalog | grep "__version←'HttpCommand' '[0-9]\+\.[0-9]\+\.0-\?\w\+\?" | grep -o "[0-9]\+\.[0-9]\+\.0-\?\w\+\?"`
major_minor=`echo ${raw_version} | grep -o "[0-9]\+\.[0-9]\+"`
special=`echo ${raw_version} | grep -o "\-\w\+$"`
patch=`git rev-list --count HEAD`
hash=`git rev-parse --short HEAD`
date=`git show -s --format=%ci | cut -c -10`
full_version=${major_minor}.${patch}${special}-${hash}
echo ${full_version}
sed -i "s/__version←'HttpCommand' '[0-9]\+\.[0-9]\+\.0-\?\w\+\?' '\w\+-\w\+-\w\+'/__version←'HttpCommand' '${full_version}' '${date}'/" HttpCommand.dyalog
sed -i "s/∆MAJORMINOR∆/${major_minor}/" pdf_template/cover.html
year=$(date '+%Y')
docrev=$(date '+%Y%m%d')_$(sed "s/\.//" <<< $major_minor)
sed -i "s/∆YEAR∆/${year}/" pdf_template/cover.html
sed -i "s/∆DOCREVISION∆/${docrev}/" pdf_template/cover.html
exit 0
