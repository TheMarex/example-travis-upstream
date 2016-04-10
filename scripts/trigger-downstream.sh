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
ESCAPED_DOWNSTREAM_GITHUB_MSG_SUCCESS=$(echo ${DOWNSTREAM_GITHUB_MSG_SUCCESS} | sed "s/\"/\\\"/g" | sed "s/\\\\/\\\\\\\\/g")
ESCAPED_DOWNSTREAM_GITHUB_MSG_FAILURE=$(echo ${DOWNSTREAM_GITHUB_MSG_FAILURE} | sed "s/\"/\\\"/g" | sed "s/\\\\/\\\\\\\\/g")
ESCAPED_DOWNSTREAM_GITHUB_MSG_PENDING=$(echo ${DOWNSTREAM_GITHUB_MSG_PENDING} | sed "s/\"/\\\"/g" | sed "s/\\\\/\\\\\\\\/g")

PENDING_PAYLOAD="
echo \"Status [\${TRAVIS_BUILD_NUMBER}]: For ${TRAVIS_COMMIT} in ${UPSTREAM_REPO}\"; \
curl -s -X POST \
  -H \"Content-Type: application/json\" \
  -H \"Accept: application/json\" \
  -H \"Authorization: token \${GITHUB_TOKEN}\" \
  -d \"${ESCAPED_DOWNSTREAM_GITHUB_MSG_PENDING}\" \
  \"https://api.github.com/repos/${UPSTREAM_REPO}/statuses/${TRAVIS_COMMIT}\" > /dev/null
"
FAILURE_PAYLOAD="
echo \"Status [\${TRAVIS_BUILD_NUMBER}]: For ${TRAVIS_COMMIT} in ${UPSTREAM_REPO}\"; \
curl -s -X POST \
  -H \"Content-Type: application/json\" \
  -H \"Accept: application/json\" \
  -H \"Authorization: token \${GITHUB_TOKEN}\" \
  -d \"${ESCAPED_DOWNSTREAM_GITHUB_MSG_FAILURE}\" \
  \"https://api.github.com/repos/${UPSTREAM_REPO}/statuses/${TRAVIS_COMMIT}\" > /dev/null
"
SUCCESS_PAYLOAD="
echo \"Status [\${TRAVIS_BUILD_NUMBER}]: For ${TRAVIS_COMMIT} in ${UPSTREAM_REPO}\"; \
curl -s -X POST \
  -H \"Content-Type: application/json\" \
  -H \"Accept: application/json\" \
  -H \"Authorization: token \${GITHUB_TOKEN}\" \
  -d \"${ESCAPED_DOWNSTREAM_GITHUB_MSG_SUCCESS}\" \
  \"https://api.github.com/repos/${UPSTREAM_REPO}/statuses/${TRAVIS_COMMIT}\" > /dev/null
"
ESCAPED_SUCCESS_PAYLOAD=$(echo ${SUCCESS_PAYLOAD} | sed "s/\"/\\\"/g" | sed "s/\\\\/\\\\\\\\/g")
ESCAPED_FAILURE_PAYLOAD=$(echo ${FAILURE_PAYLOAD} | sed "s/\"/\\\"/g" | sed "s/\\\\/\\\\\\\\/g")
ESCAPED_PENDING_PAYLOAD=$(echo ${PENDING_PAYLOAD} | sed "s/\"/\\\"/g" | sed "s/\\\\/\\\\\\\\/g")

TRAVIS_MSG="
{
\"request\":
    {
        \"message\": \"Triggered build: ${UPSTREAM_REPO} : ${TRAVIS_COMMIT}\",
        \"branch\": \"${DOWNSTREAM_BRANCH}\",
        \"config\": {
            \"before_script\": "${ESCAPED_PENDING_PAYLOAD}"
            \"after_success\": "${ESCAPED_SUCCESS_PAYLOAD}"
            \"after_failure\": "${ESCAPED_FAILURE_PAYLOAD}"
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
