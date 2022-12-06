#!/bin/sh

# SPDX-FileCopyrightText: 2022 Jakob Fritz <j.fritz@fz-juelich.de>
#
# SPDX-License-Identifier: MIT

set -u

variable_name="GITHUB_TOKEN"

curl --request PUT --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/variables/${variable_name}" --form "value=${GITHUB_TOKEN}"
echo "Done synchronizing the current Github-Token to Gitlab (used for later reporting of the pipeline-status)"
echo ""
