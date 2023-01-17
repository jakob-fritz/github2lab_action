#!/bin/sh

# SPDX-FileCopyrightText: 2023 Jakob Fritz <j.fritz@fz-juelich.de>
#
# SPDX-License-Identifier: MIT

set -u -e

# Get the id of the last pipeline that run for a given commit (GITHUB_SHA) and get all jobs of that pipeline
pipeline_id=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/commits/${GITHUB_SHA}" | jq '.last_pipeline.id')
jobs=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/pipelines/${pipeline_id}/jobs?per_page=100")

mkdir -p "artifacts"
# cd "artifacts"

# pagination is needed if pipeline has more than 100 jobs
echo "starting to iterate through jobs"
echo "$jobs"
for job in $jobs
do
    echo "$job"
    if echo "$job" | jq --exit-status 'has("artifacts_file")' ; then
        echo "found job with artifact"
        # Extract job-id and name of the job (to get the artifact later)
        job_id=$( echo "${job}" | jq '.id')
        job_name=$( echo "${job}" | jq '.name')
        echo "Job $job_id with name $job_name seems to have an artifact. Downloading it..."
        # Download artifact of this single job into file with the job-name
        # curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent --output "${job_name}.zip" "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/jobs/${job_id}/artifacts"
        echo "Done dowloading the file from job $job_id $job_name"
    fi
done
