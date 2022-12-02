#!/bin/sh

# SPDX-FileCopyrightText: 2022 Jakob Fritz <j.fritz@fz-juelich.de>
#
# SPDX-License-Identifier: MIT

set -u

# Set a default waiting-time in seconds between queries,
# if the pipeline finished
DEFAULT_POLL_TIMEOUT=10
POLL_TIMEOUT=${POLL_TIMEOUT:-$DEFAULT_POLL_TIMEOUT}

# Get the id of the last pipeline that run for a given commit (GITHUB_SHA)
pipeline_id=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/commits/${GITHUB_SHA}" | jq '.last_pipeline.id')

echo "Triggered CI for branch ${GITHUB_REF}"
echo "Working with pipeline id #${pipeline_id}"
echo "Poll timeout set to ${POLL_TIMEOUT} s"

ci_status="pending"

# Repeat until the pipeline is neither pending nor running
until [ "$ci_status" != "pending" ] && [ "$ci_status" != "running" ]
do
  # Wait some seconds
   sleep "$POLL_TIMEOUT"
   # Get the current state of the pipeline and the url of the website
   ci_output=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/pipelines/${pipeline_id}")
   ci_status=$(jq -n "$ci_output" | jq -r .status)
   ci_web_url=$(jq -n "$ci_output" | jq -r .web_url)

   echo "Current pipeline status: ${ci_status}"
   # If the pipeline is running, print the current state (to end loop)
   if [ "$ci_status" = "running" ]
   then
     echo "Checking pipeline status..."
     curl -d '{"state":"pending", "target_url": "'"${ci_web_url}"'", "context": "gitlab-ci"}' -H "Authorization: token ${GITHUB_TOKEN}"  -H "Accept: application/vnd.github+json" -X POST --silent "https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}"  > /dev/null
   fi
done
# Pipeline is done

# Show status of the pipeline
echo "Pipeline finished with status ${ci_status}"
echo "Fetching all GitLab pipeline jobs involved"
# And get jobs that ran in this pipeline
ci_jobs=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/pipelines/${pipeline_id}/jobs" | jq -r '.[] | { id, name, stage }')
# Give information on each job, but collapse this to not clutter the report
echo "Posting output from all GitLab pipeline jobs"
for JOB_ID in $(echo "$ci_jobs" | jq -r .id); do
  echo "##[group]Stage $( echo "$ci_jobs" | jq -r "select(.id==$JOB_ID) | .stage" ) / Job $( echo "$ci_jobs" | jq -r "select(.id==$JOB_ID) | .name" )"
  curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/jobs/${JOB_ID}/trace"
  echo "##[endgroup]"
done
echo "Debug problems by unfolding stages/jobs above"
# Give the URL of the pipeline to make it easier to find and remove errors
echo "For more details on the Jobs see: ${ci_web_url}"

# Set result of the pipeline (success or failure) to own job (via curl)
# and return that as a return-code (0 for success; 1 for failure)
if [ "$ci_status" = "success" ]
then
  curl -d '{"state":"success", "target_url": "'"${ci_web_url}"'", "context": "gitlab-ci"}' -H "Authorization: token ${GITHUB_TOKEN}"  -H "Accept: application/vnd.github+json" -X POST --silent "https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}"  > /dev/null
  exit 0
elif [ "$ci_status" = "failed" ]
then
  curl -d '{"state":"failure", "target_url": "'"${ci_web_url}"'", "context": "gitlab-ci"}' -H "Authorization: token ${GITHUB_TOKEN}"  -H "Accept: application/vnd.github+json" -X POST --silent "https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}"  > /dev/null
  exit 1
fi
