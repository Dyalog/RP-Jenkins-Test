#!/bin/bash
set -e

WORKSPACE=${WORKSPACE-$PWD}
cd ${WORKSPACE}

PROJECT=RP
REPO_URL=`git ls-remote --get-url origin`
REPO=`echo ${REPO_URL} | grep -o "Dyalog/.*.git$" | rev | cut -c 5- | rev`
echo ${REPO} > ___repo___

echo "Running from ${REPO_URL}"

GIT_BRANCH=${JOB_NAME#*/*/}
MAIN_BRANCH=`git remote show ${REPO_URL} | grep "HEAD branch" | sed "s/  HEAD branch: //"`
GIT_COMMIT=$(git rev-parse HEAD)

if ! [ "${GIT_BRANCH}" = "${MAIN_BRANCH}" ]; then # Should be able to get "default" branch via git
	echo "Skipping creating release for ${GIT_BRANCH}"
	exit 0
else
	echo "Creating ${GIT_BRANCH} release"
fi

# --- Create JSON release notes ---
TMP_JSON=/tmp/GH-Publish.${PROJECT}.$$.json
GH_RELEASES=/tmp/GH-Releases.${PROJECT}.$$.json

# --- Inject full version number, has side effects in copied source ---
RAW_VERSION=`cat HttpCommand.dyalog | grep "__version←'HttpCommand' '[0-9]\+\.[0-9]\+\.0-\?\w\+\?" | grep -o "[0-9]\+\.[0-9]\+\.0-\?\w\+\?"`
VERSION_AB=`echo ${RAW_VERSION} | grep -o "[0-9]\+\.[0-9]\+"`
VERSION=$(./CI/inject_version.sh)
echo ${VERSION} > ___version___
echo "Creating draft release for ${VERSION}"

if ! [ "$GHTOKEN" ]; then
  echo 'Please put your GitHub API Token in an environment variable named GHTOKEN'
  exit 1
fi

# Delete all the old draft releases, otherwise this gets filled up pretty fast as we create for every commit:
# but only if jq is available
if which jq >/dev/null 2>&1; then
        DRAFT=true
        C=0
	# Get the json from Github API
        curl -o $GH_RELEASES \
          --silent -H "Authorization: token $GHTOKEN" \
          https://api.github.com/repos/${REPO}/releases

	RELEASE_COUNT=`cat $GH_RELEASES | jq ". | length"`
	echo "Release Count: ${RELEASE_COUNT}"

	GH_VERSION_ND_LAST=0
	while [ $C -le $RELEASE_COUNT ] ; do

		DRAFT=`cat $GH_RELEASES | jq -r ".[$C].draft"`
		
		ID=`cat $GH_RELEASES | jq -r ".[$C].id"`
		
		GH_VERSION=$(cat $GH_RELEASES | jq -r ".[$C].name" | sed 's/^v//' | sed 's/-.*//')
		GH_VERSION_ND=$(cat $GH_RELEASES | jq -r ".[$C].name" | sed 's/^v//;s/\.//g' | sed 's/-.*//')
		GH_VERSION_AB=${GH_VERSION%.*}
		
		if [ "${GH_VERSION_AB}" = "${VERSION_AB}" ]; then
			if [ "$DRAFT" = "true" ]; then
				echo -e -n "*** $(cat $GH_RELEASES | jq -r ".[$C].name") with id: $(cat $GH_RELEASES | jq -r ".[$C].id") is a draft - Deleting.\n"
				curl -X "DELETE" -H "Authorization: token $GHTOKEN" https://api.github.com/repos/${REPO}/releases/${ID}
			else
				if [ $GH_VERSION_ND -gt $GH_VERSION_ND_LAST ]; then
					echo getting sha for latest release
					COMMIT_SHA=`cat $GH_RELEASES | jq -r ".[$C].target_commitish"`
					GH_VERSION_ND_LAST=$GH_VERSION_ND
				fi
			fi
		fi

		let C=$C+1
	done
	rm -f $GH_RELEASES

else
        echo jq not found, not removing draft releases
fi


echo "SHA: ${COMMIT_SHA}"

if [ $GH_VERSION_ND_LAST = 0 ]; then
	echo using log from $COMMIT_SHA from $GH_VERSION_ND_LAST
	JSON_BODY=$( ( echo -e "HttpCommand $VERSION_AB\n\nChangelog:"; git log --format='%s') | python -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
else
	echo using log from $COMMIT_SHA from $GH_VERSION_ND_LAST
	JSON_BODY=$( ( echo -e "HttpCommand $VERSION_AB\n\nChangelog:"; git log --format='%s' ${COMMIT_SHA}.. ) | python -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
	
fi

cat >$TMP_JSON <<.
{
  "tag_name": "v$VERSION",
  "target_commitish": "${GIT_COMMIT}",
  "name": "v$VERSION",
  "body": $JSON_BODY,
  "draft": true,
  "prerelease": true
}
.

cat $TMP_JSON

# --- Copy file to Dyalog Devt ---
# r=/devt/builds/${PROJECT}/${GIT_BRANCH}
# d=/${BUILD_NUMBER}

# mkdir -p $r/$d
# cp ./HttpCommand.dyalog $r/$d

# echo 'Updating "latest" symlink'; l=$r/latest; rm -f $l; ln -s $r/$d $l

TMP_RESPONSE=/tmp/GH-Response.${PROJECT}.$$.json
curl -o $TMP_RESPONSE --data @$TMP_JSON -H "Authorization: token $GHTOKEN" -i https://api.github.com/repos/$REPO/releases

RELEASE_ID=`grep '"id"' $TMP_RESPONSE | head -1 | sed 's/.*: //;s/,//'`

echo "Created release with id: $RELEASE_ID"

F=HttpCommand.dyalog
echo "Uploading $F to GitHub"
curl -i /dev/null -H "Authorization: token $GHTOKEN" \
	-H 'Accept: application/vnd.github.manifold-preview' \
	-H 'Content-Type: text/json' \
	--data-binary @"./$F" \
	https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets?name=$F
rm -f $TMP_RESPONSE $TMP_JSON
