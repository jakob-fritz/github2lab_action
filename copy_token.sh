#!/bin/sh

# SPDX-FileCopyrightText: 2022 Jakob Fritz <j.fritz@fz-juelich.de>
#
# SPDX-License-Identifier: MIT

set -u

variable_name="GITHUB_TOKEN"

# Copy the current token to gitlab
# This token is used later to push the pipeline-result back to Github
curl --request PUT --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/variables/${variable_name}" --form "value=${GITHUB_TOKEN}"

# Create a status for the gitlab-pipeline and set the status to pending
# This shall highlight in Github that another result is still missing.
curl -d '{"state":"pending", "context": "gitlab-ci"}' -H "Authorization: token ${GITHUB_TOKEN}"  -H "Accept: application/vnd.github+json" -X POST --silent "https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}"  > /dev/null

# Print something, so that it is clear in the logs, that this job ran.
echo""
echo "Done synchronizing the current Github-Token to Gitlab (used for later reporting of the pipeline-status)"
echo ""

echo "now waiting for 1 minute (for testing purposes)"
sleep "60"
echo ""
