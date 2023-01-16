#!/bin/sh

# SPDX-FileCopyrightText: 2023 Jakob Fritz <j.fritz@fz-juelich.de>
#
# SPDX-License-Identifier: MIT


set -u

# Get the id of the last pipeline that run for a given commit (GITHUB_SHA) and get all jobs of that pipeline
pipeline_id=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/commits/${GITHUB_SHA}" | jq '.last_pipeline.id')
jobs=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/pipelines/${pipeline_id}?per_page=100")

# pagination is needed if pipeline has more than 100 jobs
for job in $jobs
do
    if ( echo $job | jq 'has("artifact")' ); then
        # Extract job-id and name of the job (to get the artifact later)
        job_id=$( echo ${job} | jq '.id')
        job_name=$( echo ${job} | jq '.name')
        # Download artifact of this single job into dir with the job-name
        mkdir "${job_name}"
        # Creating a subshell to download into dir
        ("cd '${job_name}' || exit 1"
        curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/jobs/${job_id}/artifacts"
        )
    fi
done
