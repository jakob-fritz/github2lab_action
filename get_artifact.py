# SPDX-FileCopyrightText: 2023 Jakob Fritz <j.fritz@fz-juelich.de>
# 
# SPDX-License-Identifier: MIT

import requests
from os import environ as env

def get_job_list():
    pipeline_url = f'https://{env.GITLAB_HOSTNAME}/api/v4/projects/{env.GITLAB_PROJECT_ID}/repository/commits/{env.GITHUB_SHA}'
    print(pipeline_url)
    headers = {'PRIVATE-TOKEN': env.GITLAB_TOKEN}
    r = requests.get(pipeline_url, headers=headers)
    pipeline_id = r.json()['last_pipeline']['id']
    print(f'Pipeline-ID is {pipeline_id}')
    jobs_url = f'https://{env.GITLAB_HOSTNAME}/api/v4/projects/{env.GITLAB_PROJECT_ID}/pipelines/{pipeline_id}/jobs'
    job_list = requests.get(jobs_url, headers=headers).json()
    return job_list


def download_artifacts(job_list):
    for job in job_list:
        if any([e.file_type == "archive" for e in job.artifacts]):
            download_single_artifact(job)
        else:
            print(f'Job {job.name} does not exhibit an artifact for download.')


def get_artifact_info(job):
    for artifact in job.artifacts:
        if artifact.file_type == "archive":
            return artifact
    raise KeyError(f'No artifact found for job {job.name}')

def download_single_artifact(job):
    artifact = get_artifact_info(job)
    filename = artifact.filename
    job_id = job.id
    headers = {'PRIVATE-TOKEN': env.GITLAB_TOKEN}
    file_url = f"https://{env.GITLAB_HOSTNAME}/api/v4/projects/{env.GITLAB_PROJECT_ID}/jobs/{job_id}/artifacts"
    r = requests.get(file_url, headers=headers)
    with open(f'{job.name}.{artifact.file_format}', 'wb') as file:
        r = requests.get(file_url, headers=headers)
        file.write(r.content)
    print(f'Downloaded file from job {job.name}.')

if __name__=='__main__':
    job_list = get_job_list()
    download_artifacts(job_list)
