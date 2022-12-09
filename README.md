<!--
SPDX-FileCopyrightText: 2022 Jakob Fritz <j.fritz@fz-juelich.de>

SPDX-License-Identifier: MIT
-->

# Mirror to GitLab and trigger GitLab CI

A GitHub Action that mirrors all commits to GitLab, triggers GitLab CI,
and returns the results back to GitHub.

Directly afterwards, a second action uses active polling to determine
whether the GitLab pipeline is finished. This means that GitHub Action
will only end after the GitLab CI pipeline finished.

This whole approach also works for pull-requests.
Then, the credentials of the maintainer are used.
These are stored in Github-Secrets.
Therefore, they are not directly accessible to others, but given enough intent,
they can be extracted when the code of the CI is adapted accordingly.

## How to use the Gitlab-CI as a contributor

Nothing special. Just contribute to the project as you regularly do
(and as the project requests). Your contributions are automatically
tested in the Gitlab-Repo (once the maintainer approved it).

## How to set up a Gitlab-CI with a Github-Repo (as a maintainer)

Steps to be done:

### Preparation

- Create a new empty repository in a Gitlab-Instance.
- Allow Force-Push on remote protected branches in remote repository.
  - This can be found in Gitlab in
    `Settings -> Repository -> Protected branches`
- Create Project Access Token in GitLab,
  so that the GitHub-CI can push to GitLab
  - This can be found in Gitlab in
    `Settings -> Access Tokens -> Project Access Tokens`
  - Give the token a suited name. This name is publicly readable.
  - Set a role of this token (probably `maintainer`,
                              as force-push needs to be possible)
  - This token needs the necessary permissions:
    - api (Read & Write)
    - read_repository
    - write_repository
  - Click `Create project access token`
  - Copy the generated token to the clipboard
- Set the token in Github as a secret
  - In Github `Settings -> Secrets -> Actions -> New repository secret`
  - Set the name as `GITLAB_TOKEN`
  - Paste the token as `secret`
  - Click `Add Secret` to create the new secret

### Gitlab-CI

Add a Gitlab-CI-File called `.gitlab-ci.yml`.
This file is automatically detected by Gitlab
and run when a new commit is done.
This file contains jobs for the Gitlab-CI-Pipeline.

An example for such a file can be found in `examples/.gitlab-ci.yml`.

### Github-CI

- Copy the file `mirror_wait.yml` in `examples/.github/workflows`
to your own repository (in a directory called `.github/workflows`).
This file adds a job that triggers a CI-Pipeline in Gitlab.
- The environment-variables are mostly found in two jobs in the CI.
You can also declare them in the upper part to make them available to all jobs.
Then, both jobs have access to those variables
and use have to declare them only once.
However, also all other jobs (e.g. ones in between) have access to those
variables. This is why in the examples, the variables are declared directly
in the jobs. By this, only those jobs can access the variables.
- Edit the environment-variables in the file to match your project
  - `GITLAB_HOSTNAME` needs to be the base of the Gitlab-Instance.
  E.g. `codebase.helmholtz.cloud` without https:// in front
  - Set `GITLAB_PROJECT_ID` to the repository-id
  that can be found in the main page of the repository (named "Project ID")
  - Set `MODE` to one of the following: `mirror`, `get_status`, or `both`.
  This defines, what action is taken by the job.
    - The first (`mirror`) only synchronizes the local git to gitlab.
    - The second (`get_status`) gets the state of the last CI-pipeline
  for the current commit.
    - The last possibility (`both`) does both of them
  (first synchronization and afterwards getting the status of the pipeline).
    - It can be usefull to split the two parts if there are jobs,
  that shall be done in parallel.
  Then, it can first be synchronized to Gitlab (using `mirror`),
  then doing some local CI-jobs and as last job, the `get_status` is used
  to also query the result from the Gitlab-CI-Pipeline.
  If no other jobs are run in Github in parallel,
  the option `both` can be used for simplicity.
- The following environment-variables can be kept as they are:
  - `FORCE_PUSH` is set to force-push to the Gitlab-Repo, to make sure,
  the Gitlab-Repo stays in sync with the main GitHub-repository.
  - `GITHUB_TOKEN` is used to authorize internal actions.
  The secret is set automatically by GitHub.
  - `GITLAB_TOKEN` is used to authorize actions with the Gitlab-repo.
  It uses the secret, that was set above.

### How to use with Pull-Requests

When external contributors hand in pull-requests, the CI has to be accepted
by a maintainer of the project. In case the Pull-Requests changes code
that is executed by the CI, check if the code may expose or transmit secrets
that have been set above.
If so, the change could be used to gain access to the secret tokens.

## How to contribute to this project supplying the action?

In case you find an error or a bug in this project,
feel free to open an issue.
If you want to fix this error/bug,
please open a Pull-Request with the code-change.

## Thanks to

- [SvanBoxel](<https://github.com/SvanBoxel>)
and his repo [gitlab-mirror-and-ci-action](<https://github.com/SvanBoxel/gitlab-mirror-and-ci-action>)
for the inspiration of this project.
- The "Helmholtz Platform for Research Software Engineering - Preparatory Study"
([HiRSE_PS](<https://www.helmholtz-hirse.de/>)),
funded by the [Innovation Fund](<https://www.helmholtz.de/en/transfer/helmholtz-association-transfer-instruments/innovation-fund-of-the-helmholtz-centers/>)
of the [Helmholtz Association](<https://www.helmholtz.de/en/>).
