#!/bin/sh

# SPDX-FileCopyrightText: 2022 Jakob Fritz <j.fritz@fz-juelich.de>
#
# SPDX-License-Identifier: MIT

set -u

# variable_name="GITHUB_TOKEN"

# Copy the current token to gitlab
# This token is used later to push the pipeline-result back to Github
# curl --request PUT --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/variables/${variable_name}" --form "value=${GITHUB_TOKEN}"

# Create a status for the gitlab-pipeline and set the status to pending
# This shall highlight in Github that another result is still missing.
# curl -d '{"state":"pending", "context": "gitlab-ci"}' -H "Authorization: token ${GITHUB_TOKEN}"  -H "Accept: application/vnd.github+json" -X POST --silent "https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}"  > /dev/null

check_reply=$(curl \
  -X POST \
  --silent \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: token ${GITHUB_TOKEN}"\
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${GITHUB_REPOSITORY}/check-runs \
  -d '{"name":"Gitlab-CI","head_sha":"'"${GITHUB_SHA}"'","status":"in_progress"}')
check_id=$(jq -n "$check_reply" | jq -r .id)

# Directly close it again, as otherwise it stays open and "in progress",
# without any updates
# and updates are not possible unless an allowed token is known.
curl \
  -X PATCH \
  --silent \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: token ${GITHUB_TOKEN}"\
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${GITHUB_REPOSITORY}/check-runs/${check_id} \
  -d '{"name":"Gitlab-CI","head_sha":"'"${GITHUB_SHA}"'","status":"completed", "conclusion":"neutral"}'


# Print something, so that it is clear in the logs, that this job ran.
echo ""
echo "Done creating and closing a check-run, that might be used for replies by Gitlab in a later stage of development."
echo ""
