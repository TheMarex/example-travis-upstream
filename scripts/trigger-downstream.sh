#!/bin/bash

set -eu
set -o pipefail

TRAVIS_COMMIT=${TRAVIS_COMMIT:-$(git log --format=%H --no-merges -n 1 | tr -d '\n')}
TRAVIS_BRANCH=${TRAVIS_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}
DOWNSTREAM_BRANCH=${DOWNSTREAM_BRANCH:-${TRAVIS_BRANCH}}
ESCAPED_DOWNSTREAM_REPO=$(echo ${DOWNSTREAM_REPO} | sed "s/\//%2F/g")
DOWNSTREAM_GITHUB_MSG_PENDING="
{
    \"state\": \"pending\",
    \"target_url\": \"https://travis-ci.org/${ESCAPED_DOWNSTREAM_REPO}/builds\",
    \"description\": \"Running downstream build\",
    \"context\": \"continuous-integration/downstream/${DOWNSTREAM_REPO}/0\"
}"
DOWNSTREAM_GITHUB_MSG_SUCCESS="
{
    \"state\": \"success\",
    \"target_url\": \"https://travis-ci.org/${ESCAPED_DOWNSTREAM_REPO}/builds\",
    \"description\": \"Running downstream build\",
    \"context\": \"continuous-integration/downstream/${DOWNSTREAM_REPO}/\${TRAVIS_BUILD_NUMBER}\"
}"
DOWNSTREAM_GITHUB_MSG_FAILURE="
{
    \"state\": \"failure\",
    \"target_url\": \"https://travis-ci.org/${ESCAPED_DOWNSTREAM_REPO}/builds\",
    \"description\": \"Running downstream build\",
    \"context\": \"continuous-integration/downstream/${DOWNSTREAM_REPO}/\${TRAVIS_BUILD_NUMBER}\"
}"

PENDING_PAYLOAD="
echo \"Status [\${TRAVIS_BUILD_NUMBER}]: For ${TRAVIS_COMMIT} in ${UPSTREAM_REPO}\"; \
curl -s -X POST \
  -H \"Content-Type: application/json\" \
  -H \"Accept: application/json\" \
  -H \"Authorization: token \${GITHUB_TOKEN}\" \
  -d \"${DOWNSTREAM_GITHUB_MSG_PENDING}\" \
  \"https://api.github.com/repos/${UPSTREAM_REPO}/statuses/${TRAVIS_COMMIT}\" > /dev/null
"
FAILURE_PAYLOAD="
echo \"Status [\${TRAVIS_BUILD_NUMBER}]: For ${TRAVIS_COMMIT} in ${UPSTREAM_REPO}\"; \
curl -s -X POST \
  -H \"Content-Type: application/json\" \
  -H \"Accept: application/json\" \
  -H \"Authorization: token \${GITHUB_TOKEN}\" \
  -d \"${DOWNSTREAM_GITHUB_MSG_FAILURE}\" \
  \"https://api.github.com/repos/${UPSTREAM_REPO}/statuses/${TRAVIS_COMMIT}\" > /dev/null
"
SUCCESS_PAYLOAD="
echo \"Status [\${TRAVIS_BUILD_NUMBER}]: For ${TRAVIS_COMMIT} in ${UPSTREAM_REPO}\"; \
curl -s -X POST \
  -H \"Content-Type: application/json\" \
  -H \"Accept: application/json\" \
  -H \"Authorization: token \${GITHUB_TOKEN}\" \
  -d \"${DOWNSTREAM_GITHUB_MSG_SUCCESS}\" \
  \"https://api.github.com/repos/${UPSTREAM_REPO}/statuses/${TRAVIS_COMMIT}\" > /dev/null
"

TRAVIS_MSG="
{
\"request\":
    {
        \"message\": \"Triggered build: ${UPSTREAM_REPO} : ${TRAVIS_COMMIT}\",
        \"branch\": \"${DOWNSTREAM_BRANCH}\",
        \"config\": {
            \"before_script\": "${PENDING_PAYLOAD}"
            \"after_success\": "${SUCCESS_PAYLOAD}"
            \"after_failure\": "${FAILURE_PAYLOAD}"
        }
    }
}"

trigger_downstream() {
    echo "Triggering: ${DOWNSTREAM_BRANCH} in ${DOWNSTREAM_REPO}"
    echo "${TRAVIS_MSG}"
    curl -s -X POST \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -H "Travis-API-Version: 3" \
      -H "Authorization: token ${TRAVIS_TOKEN}" \
      -d "${TRAVIS_MSG}" \
      "https://api.travis-ci.org/repo/${ESCAPED_DOWNSTREAM_REPO}/requests" > /dev/null
}

trigger_downstream
