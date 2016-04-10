#!/bin/bash

set -eu
set -o pipefail

TRAVIS_COMMIT=${TRAVIS_COMMIT:-$(git log --format=%H --no-merges -n 1 | tr -d '\n')}
TRAVIS_BRANCH=${TRAVIS_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}
DOWNSTREAM_BRANCH=${DOWNSTREAM_BRANCH:-${TRAVIS_BRANCH}}
ESCAPED_DOWNSTREAM_REPO=$(echo ${DOWNSTREAM_REPO} | sed "s/\//%2F/g")
TRAVIS_MSG="
{
\"request\":
    {
        \"message\": \"Triggered build: ${UPSTREAM_REPO} : ${TRAVIS_COMMIT}\",
        \"branch\": \"${DOWNSTREAM_BRANCH}\",
        \"config\": {
            \"env\": \"TRIGGER_COMMIT=${TRAVIS_COMMIT}\"
        }
    }
}"
GITHUB_MSG="
{
    \"state\": \"pending\",
    \"target_url\": \"https://travis-ci.org/${ESCAPED_DOWNSTREAM_REPO}/builds\",
    \"description\": \"Running downstream build\",
    \"context\": \"continuous-integration/downstream/${DOWNSTREAM_REPO}/0\"
} "

trigger_downstream() {
    echo "Triggering: ${DOWNSTREAM_BRANCH} in ${DOWNSTREAM_REPO}"
    curl -s -X POST \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -H "Travis-API-Version: 3" \
      -H "Authorization: token ${TRAVIS_TOKEN}" \
      -d "${TRAVIS_MSG}" \
      "https://api.travis-ci.org/repo/${ESCAPED_DOWNSTREAM_REPO}/requests" > /dev/null
}

post_pending() {
    echo "Status [0]: For ${TRAVIS_COMMIT} in ${UPSTREAM_REPO}"
    curl -s -X POST \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      -d "${GITHUB_MSG}" \
      "https://api.github.com/repos/${UPSTREAM_REPO}/statuses/${TRAVIS_COMMIT}" > /dev/null
}

trigger_downstream
#post_pending
