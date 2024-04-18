#!/usr/bin/env python

# SPDX-FileCopyrightText: 2023 Jakob Fritz <j.fritz@fz-juelich.de>
#
# SPDX-License-Identifier: MIT

"""
Group of functions to find and download artifacts from Gitlab-CI-jobs
in a pipeline to a given commit.
It is designed to be called from within Github-Actions
and uses environment-variables as input.
"""

from os import environ as env
import os
import subprocess
import requests


def get_job_list():
    """
    This function gets a list of jobs in the pipeline of a Gitlab-CI
    for a given commit.
    It does not take any arguments, but uses environment-variables.

    The following environment-variables are needed:
    GITLAB_HOSTNAME: The hostname of the gitlab-instance (e.g gitlab.com)
    GITLAB_PROJECT_ID: ID of the project (e.g. 1234)
    GITLAB_TOKEN: A secret token to access gitlab with more rights
    GITHUB_SHA: The SHA of the last commit that was pushed
    PR_HEAD_SHA: The SHA of the latest commit in a Pull Request
    """
    if os.getenv("MIRROR_BRANCH") not in [None, ""]:
        print(f"Used branch is: {os.getenv('MIRROR_BRANCH')}")
        used_sha = subprocess.run(["git", "rev-parse", f"{os.getenv('MIRROR_BRANCH')}"], capture_output=True, text=True).stdout
        # strip whitespaces (incl. newlines)
        used_sha = used_sha.strip()
    elif env["GITHUB_EVENT_NAME"] in ["pull_request", "pull_request_target"]:
        used_sha = env['PR_HEAD_SHA']
    else:
        used_sha = env['GITHUB_SHA']
    pipeline_url = (
        f"https://{env['GITLAB_HOSTNAME']}/api/v4/projects/"
        + f"{env['GITLAB_PROJECT_ID']}/repository/commits/{used_sha}"
    )
    headers = {"PRIVATE-TOKEN": env["GITLAB_TOKEN"]}
    # Get the pipeline for the commit
    response = requests.get(pipeline_url, headers=headers)
    # Raise an error if the request was not successfull
    response.raise_for_status()
    pipeline_id = response.json()["last_pipeline"]["id"]
    print(f"Pipeline-ID is {pipeline_id}")
    jobs_url = (
        f"https://{env['GITLAB_HOSTNAME']}/api/v4/projects/"
        + f"{env['GITLAB_PROJECT_ID']}/pipelines/{pipeline_id}/jobs"
    )
    # Get the list of jobs for the pipeline-id (determined above)
    response = requests.get(jobs_url, headers=headers)
    response.raise_for_status()
    job_list = response.json()
    return job_list


def download_artifacts(job_list):
    """
    Download all artifacts from a list of jobs
    (ususally the ones in a single pipeline).
    It takes only the list of jobs and returns nothing
    """
    # Create directory to store artifacts in
    os.makedirs("artifacts")
    for job in job_list:
        # If a job has an artifact (apart from the log), download it
        if any([e["file_type"] == "archive" for e in job["artifacts"]]):
            download_single_artifact(job)
        else:
            print(
                "The following job does not exhibit "
                + f"an artifact for download: {job['name']}"
            )


def get_artifact_info(job):
    """
    Extracts the artifact for a job from a list of artifacts
    The other (ignored) artifacts are the trace and logs

    Takes the job as input.
    returns a dict with info of the artifact to be downloaded.
    """
    for artifact in job["artifacts"]:
        # Return the correct artifact (i.e. not the log)
        if artifact["file_type"] == "archive":
            return artifact
    raise KeyError(f"No artifact found for job: {job['name']}")


def download_single_artifact(job):
    """
    Downloads a single artifact for a given job.
    Retrieves the url of the artifact and writes the content to a file
    with the name of the job.

    Takes the job as input and returns nothing.
    """
    artifact = get_artifact_info(job)
    job_id = job["id"]
    job_name = sanitize(job["name"])
    headers = {"PRIVATE-TOKEN": env["GITLAB_TOKEN"]}
    file_url = (
        f"https://{env['GITLAB_HOSTNAME']}/api/v4/projects/"
        + f"{env['GITLAB_PROJECT_ID']}/jobs/{job_id}/artifacts"
    )
    with open(f"artifacts/{job_name}.{artifact['file_format']}", "wb") as file:
        # Get the file (artifact)
        response = requests.get(file_url, headers=headers)
        # Raise an error if the request was unsuccessfull
        response.raise_for_status()
        # Acutally write the content of the response to a file
        file.write(response.content)
    print(f"Downloaded file from job: {job['name']} as {job_name}.")


def sanitize(job_name):
    # From the output of Github:
    # Invalid characters include:  Double quote ", Colon :, Less than <, Greater than >, Vertical bar |, Asterisk *, Question mark ?, Carriage return \r, Line feed \n
    sanitized_name = job_name.strip()
    sanitized_name = sanitized_name.replace('"','')
    sanitized_name = sanitized_name.replace(':','')
    sanitized_name = sanitized_name.replace('<','')
    sanitized_name = sanitized_name.replace('>','')
    sanitized_name = sanitized_name.replace('|','')
    sanitized_name = sanitized_name.replace('*','')
    sanitized_name = sanitized_name.replace('?','')
    sanitized_name = sanitized_name.replace('\r','')
    sanitized_name = sanitized_name.replace('\n','')
    # Officially not needed, but probably helpfull to exclude spaces
    sanitized_name = sanitized_name.replace(' ','_')
    return sanitized_name

if __name__ == "__main__":
    jobs = get_job_list()
    download_artifacts(jobs)
