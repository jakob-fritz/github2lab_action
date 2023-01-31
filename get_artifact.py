# SPDX-FileCopyrightText: 2023 Jakob Fritz <j.fritz@fz-juelich.de>
#
# SPDX-License-Identifier: MIT

from os import environ as env
import requests

def get_job_list():
    pipeline_url = f"https://{env['GITLAB_HOSTNAME']}/api/v4/projects/" + \
        f"{env['GITLAB_PROJECT_ID']}/repository/commits/{env['GITHUB_SHA']}"
    print(pipeline_url)
    headers = {'PRIVATE-TOKEN': env['GITLAB_TOKEN']}
    response = requests.get(pipeline_url, headers=headers)
    response.raise_for_status()
    pipeline_id = response.json()['last_pipeline']['id']
    print(f'Pipeline-ID is {pipeline_id}')
    jobs_url = f"https://{env['GITLAB_HOSTNAME']}/api/v4/projects/" + \
        f"{env['GITLAB_PROJECT_ID']}/pipelines/{pipeline_id}/jobs"
    response = requests.get(jobs_url, headers=headers)
    response.raise_for_status()
    job_list = response.json()
    return job_list


def download_artifacts(job_list):
    for job in job_list:
        if any([e['file_type'] == "archive" for e in job['artifacts']]):
            download_single_artifact(job)
        else:
            print(f"Job {job['name']} does not exhibit an artifact for download.")


def get_artifact_info(job):
    for artifact in job['artifacts']:
        if artifact['file_type'] == "archive":
            return artifact
    raise KeyError(f"No artifact found for job {job['name']}")

def download_single_artifact(job):
    artifact = get_artifact_info(job)
    job_id = job['id']
    headers = {'PRIVATE-TOKEN': env['GITLAB_TOKEN']}
    file_url = f"https://{env['GITLAB_HOSTNAME']}/api/v4/projects/" + \
        f"{env['GITLAB_PROJECT_ID']}/jobs/{job_id}/artifacts"
    response = requests.get(file_url, headers=headers)
    response.raise_for_status()
    with open(f"{job['name']}.{artifact['file_format']}", 'wb') as file:
        response = requests.get(file_url, headers=headers)
        response.raise_for_status()
        file.write(response.content)
    print(f"Downloaded file from job {job['name']}.")

if __name__=='__main__':
    jobs = get_job_list()
    download_artifacts(jobs)
