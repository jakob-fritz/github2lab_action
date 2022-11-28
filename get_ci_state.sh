#!/bin/sh

set -u
##################################################################

DEFAULT_POLL_TIMEOUT=10
POLL_TIMEOUT=${POLL_TIMEOUT:-$DEFAULT_POLL_TIMEOUT}

pipeline_id=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/commits/${GITHUB_SHA}" | jq '.last_pipeline.id')

echo "Triggered CI for branch ${GITHUB_REF}"
echo "Working with pipeline id #${pipeline_id}"
echo "Poll timeout set to ${POLL_TIMEOUT} s"

ci_status="pending"

until [ "$ci_status" != "pending" ] && [ "$ci_status" != "running" ]
do
   sleep $POLL_TIMEOUT
   ci_output=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/pipelines/${pipeline_id}")
   ci_status=$(jq -n "$ci_output" | jq -r .status)
   ci_web_url=$(jq -n "$ci_output" | jq -r .web_url)

   echo "Current pipeline status: ${ci_status}"
   if [ "$ci_status" = "running" ]
   then
     echo "Checking pipeline status..."
     curl -d '{"state":"pending", "target_url": "'${ci_web_url}'", "context": "gitlab-ci"}' -H "Authorization: token ${GITHUB_TOKEN}"  -H "Accept: application/vnd.github.antiope-preview+json" -X POST --silent "https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}"  > /dev/null
   fi
done

echo "Pipeline finished with status ${ci_status}"

echo "Fetching all GitLab pipeline jobs involved"
ci_jobs=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/pipelines/${pipeline_id}/jobs" | jq -r '.[] | { id, name, stage }')
echo "Posting output from all GitLab pipeline jobs"
for JOB_ID in $(echo $ci_jobs | jq -r .id); do
  echo "##[group]Stage $( echo $ci_jobs | jq -r "select(.id=="$JOB_ID") | .stage" ) / Job $( echo $ci_jobs | jq -r "select(.id=="$JOB_ID") | .name" )"
  curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/jobs/${JOB_ID}/trace"
  echo "##[endgroup]"
done
echo "Debug problems by unfolding stages/jobs above"
echo "For more details on the Jobs see: ${ci_web_url}"

if [ "$ci_status" = "success" ]
then
  curl -d '{"state":"success", "target_url": "'${ci_web_url}'", "context": "gitlab-ci"}' -H "Authorization: token ${GITHUB_TOKEN}"  -H "Accept: application/vnd.github+json" -X POST --silent "https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}"  > /dev/null
  exit 0
elif [ "$ci_status" = "failed" ]
then
  curl -d '{"state":"failure", "target_url": "'${ci_web_url}'", "context": "gitlab-ci"}' -H "Authorization: token ${GITHUB_TOKEN}"  -H "Accept: application/vnd.github+json" -X POST --silent "https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}"  > /dev/null
  exit 1
fi
