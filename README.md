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
Depending on the duration of the GitLab CI pipeline, the second part
(waiting for the GitLab CI pipeline) may take some time waiting.

![Structure of the Github2Lab action: The code is pushed, then a GH runner takes care of pushing and reporting](structure_image/structure_line.png)

This whole approach also works for pull-requests.
Then, the credentials of the maintainer are used.
These are stored in GitHub-Secrets.
Therefore, they are not directly accessible to others, but given enough intent,
they can be extracted when the code of the CI is adapted accordingly.

## How to use the GitLab-CI as a contributor

Nothing special. Just contribute to the project as you regularly do
(and as the project requests). When you create a pull-request,
your contributions can be tested in the GitLab-Repo
(once the maintainer approved it). The required setup is explained [below](#how-to-use-with-pull-requests).

### How to run the GitLab-CI in a forked repository (prior to the Pull-Request)

In case the GitLab-CI in a forked repo shall be run prior to the pull-request,
a few steps are necessary to be taken.
It is helpful, if the forked repo does not copy names of branches
in the main repo, as both repos are mirrored to the same GitLab-Repo for testing.
Assuming the maintainer already set up the GitLab-CI as explained below,
two more steps are needed.

- First, the maintainer of the main repository needs to create
  a separate Project-Access-Token (as explained below) and provide it to the
  user that forked the repo. It is advisable to not reuse an existing token!
  By creating a new token, the permissions are easier to manage in case of
  leaked (or otherwise compromised) tokens.
- Then, the user needs to store it as a repository-secret named `GITLAB_TOKEN`.
  For more information on how to store it, see the section
  [Set the token in GitHub as a secret](#preparation) below.
  After this, the GitHub-CI is able to mirror to GitLab.

## How to set up a GitLab-CI with a GitHub-Repo (as a maintainer)

Steps to be done:

### Preparation

- Create a new empty repository in a GitLab-Instance.
- Allow Force-Push on remote protected branches in remote repository.
  - This can be found in GitLab in
    `Settings -> Repository -> Protected branches`
- Create an Access Token in GitLab,
  so that the GitHub-CI can push to GitLab.
  The Access Token can be a Project Access Token or a Personal Access Token.
  If Jacamar is used, a Personal Access Token is needed.
  Otherwise, a Project Access Token is recommended.
  
  Creation of a Personal Access Token:
  - This can be found in GitLab after clicking on the own user-avatar:
    `Preferences -> Access Tokens -> Add new token`
  - Give the token a suited name.
  - This token needs the necessary permissions:
    - API (Read & Write)
    - read_repository
    - write_repository
  - Click `Create personal access token`
  - Copy the generated token to the clipboard

  Creation of a Project Access Token:
  - This can be found in GitLab in
    `Settings -> Access Tokens -> Project Access Tokens`
  - Give the token a suited name. This name is publicly readable.
  - Set a role of this token (probably `maintainer`,
                              as force-push needs to be possible)
  - This token needs the necessary permissions:
    - API (Read & Write)
    - read_repository
    - write_repository
  - Click `Create project access token`
  - Copy the generated token to the clipboard
- Set the token in GitHub as a secret
  - In GitHub `Settings -> Secrets -> Actions -> New repository secret`
  - Set the name as `GITLAB_TOKEN`
  - Paste the token as `secret`
  - Click `Add Secret` to create the new secret

### GitLab-CI

Add a GitLab-CI-File called `.gitlab-ci.yml`.
This file is automatically detected by GitLab
and run when a new commit is done.
This file contains jobs for the GitLab-CI-Pipeline.

An example for such a file can be found in `examples/.gitlab-ci.yml`.

### GitHub-Actions

- To use the action, simply check out your code
and include the action in your current GitHub workflows.
See [Example of key YAML components](#example-of-key-yaml-components)
below for a snippet on how to include the action.
Full examples on how to include it can be found in `examples/.github/workflows`.
- Use `on: pull_request_target` instead of `on: pull_request`. This is
needed so that the CI triggered by the pull-request can access secrets from
the target repository. However, given enough malicious intend, contributors
could use this to extract secrets of the target repository. This could be done
by inserting commands in the CI, that extract (e.g. print) the secrets,
or parts thereof. So be careful what code is executed in the CI.
- The environment-variables are mostly found in two jobs in the CI.
You can also declare them in the upper part to make them available to all jobs.
Then, both jobs have access to those variables
and use have to declare them only once.
However, also all other jobs (e.g. the ones in between) have access to those
variables. This is why in the examples, the variables are declared directly
in the jobs. By this, only those jobs can access the variables.
- Edit the environment-variables in the file to match your project
  - `GITLAB_HOSTNAME` needs to be the base of the GitLab-Instance.
  E.g. `codebase.helmholtz.cloud` without <https://> in front
  - Set `GITLAB_PROJECT_ID` to the repository-id
  that can be found in the main page of the repository (named "Project ID")
  - Set `MODE` to one of the following: `mirror`, `get_status`, `get_artifact`,
  or `all`.
  This defines, what action is taken by the job.
    - The first (`mirror`) only synchronizes the local git to GitLab.
    - The second (`get_status`) gets the state of the last CI-pipeline
  for the current commit. It waits (the job runs) until the GitLab CI pipeline
  is finished. Depending on the pipeline, this may take some time.
  Therefore, it might be helpful, to run this job towards the end
  of the GitHub pipeline.
    - The third (`get_artifact`) should be run only after `get_status`.
    It looks for artifacts from the GitLab-Code and uploads them as
    GitHub-Artifacts.
    - The last possibility (`all`) does both of them
  (first synchronization and afterwards getting the status of the pipeline).
  As mentioned directly above, this may take some time (and by this block a
  GitHub-runner) depending on how much is done in the GitLab pipeline.
    - It can be useful to split the two parts if there are jobs,
  that shall be done in parallel.
  Then, it can first be synchronized to GitLab (using `mirror`),
  then doing some local CI-jobs and afterwards, the `get_status` is used
  to also query the result from the GitLab-CI-Pipeline.
  The last job can be `get_artifact`. This job looks for artifacts in the
  GitLab-CI-Jobs and downloads them to upload them as GitHub-Artifacts.
  If no other jobs are run in GitHub in parallel,
  the option `all` can be used for simplicity.
- The following environment-variables can be kept as they are:
  - `FORCE_PUSH` is set to force-push to the GitLab-Repo, to make sure,
  the GitLab-Repo stays in sync with the main GitHub-repository.
  - `GITHUB_TOKEN` is used to authorize internal actions.
  The secret is set automatically by GitHub.
  - `GITLAB_TOKEN` is used to authorize actions with the GitLab-repo.
  It uses the secret, that was set above.

### Example of key YAML components

``` yaml
- name: Checkout
  uses: actions/checkout@v4
- name: Mirror and get status
  uses: jakob-fritz/github2lab_action@main
  env:
    MODE: 'all' # Either 'mirror', 'get_status', 'get_artifact', or 'all'
    GITLAB_TOKEN: ${{ secrets.GITLAB_TOKEN }}
    FORCE_PUSH: "true"
    GITLAB_HOSTNAME: "codebase.helmholtz.cloud"
    GITLAB_PROJECT_ID: "6627"
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

This adds the job to mirror to GitLab and wait for the GitLab-pipeline
to finish. If the two parts shall be split, so that other jobs can be performed
in GitHub in between, the following example may be more suited.

``` yaml
- name: Checkout
  uses: actions/checkout@v4
- name: Mirror
  uses: jakob-fritz/github2lab_action@main
  env:
    MODE: 'mirror' # Either 'mirror', 'get_status', 'get_artifact', or 'all'
    GITLAB_TOKEN: ${{ secrets.GITLAB_TOKEN }}
    FORCE_PUSH: "true"
    GITLAB_HOSTNAME: "codebase.helmholtz.cloud"
    GITLAB_PROJECT_ID: "6627"
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
# Add additional jobs here
# These take place after mirroring to GitLab (and starting the CI there)
# and retrieving the results from the CI at GitLab.
- name: Additional local job
  run: |
    echo "This can be a single or many jobs before querying the result from GitLab-CI"
- name: Get status
  uses: jakob-fritz/github2lab_action@main
  env:
    MODE: 'get_status' # Either 'mirror', 'get_status', 'get_artifact', or 'all'
    GITLAB_TOKEN: ${{ secrets.GITLAB_TOKEN }}
    GITLAB_HOSTNAME: "codebase.helmholtz.cloud"
    GITLAB_PROJECT_ID: "6627"
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
- name: Get artifacts
  uses: jakob-fritz/github2lab_action@main
  env:
    MODE: 'get_artifact' # Either 'mirror', 'get_status', 'get_artifact', or 'all'
    GITLAB_TOKEN: ${{ secrets.GITLAB_TOKEN }}
    GITLAB_HOSTNAME: "codebase.helmholtz.cloud"
    GITLAB_PROJECT_ID: "6627"
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

For full examples see also the files in `examples/.github/workflows`.

### How to use with Pull-Requests

To use the action in Pull-Requests, some additional setup is needed.
The reason for this additional setup is that external code cannot access
a token with write access (for security reasons).

Therefore, a two-step approach should be used.
The first step is to decide on whether the synchronization shall be executed.
The second step is the synchronization itself.
It is recommended to create a new, separate workflow for the action
to not interfere with any other GitHub actions in use.

An example for such a workflow can be found in
`examples/.github/workflows/mirror_pull_request.yml`.
There, some differences can be seen compared to
`examples/.github/workflows/mirror_combined.yml`.
These differences shall be highlighted and explained in the following.

The `on: pull_request` in the workflow-file
needs to be changed to `on: pull_request_target` so that the CI triggered by
the pull-request can access the Project-Secrets of the target repository.
There, the access-tokens are stored, that are needed for execution.
Additionally, the workflow shall be executed on push and periodically
(done by `on: push` and `on: schedule`).
Furthermore, the whole workflow will only run for pull-requests,
if the pull-request has a certain label named `gitlab-mirror` (in this example).
The intention is to avoid numerous runs during the development of pull-requests,
where this is not necessary.
It does not serve as a security measure,
but rather as a switch to enable and disable the mirroring in pull-requests.

The workflow consists of two jobs. The first `check_permission` simply succeeds
or fails depending on whether the person who triggered the job has enough permissions.
For this, the action `check-user-permission` is used.
It has to be noted, that the permissions are checked for the user
who triggered the workflow, not for the user who committed the latest code.
This differs in cases of rerunning the workflow.
If the person has write permissions to the repository, the access is granted.
For this reason, all workflows triggered by `push` events are run as well,
as this event implies a write access to the repository.
If the job `check_permission` succeeds, another job `mirror_to_gitlab` is run.
In case of a failing job `check_permission`,
the second job would not be executed.

The reason for the two-step approach is to avoid automatic execution of code
in pull-requests, as this could contain malicious code.
Therefore, the pipeline will fail if an arbitrary user opens a pull-request.
Only, after a user with write permissions restarts the workflow, it will run.
It is strongly recommended checking the new code before restarting this workflow.

This second job consists of three steps. The first is to `set proper sha`.
The second checks out code and the third uses the `github2lab_action`
developed in this repository.

The first step is needed to always check out the latest commit.
For pushes and scheduled workflows, this is the same commit
as it would be checked out by default. For pull-requests this is different.
In pull-requests (not pull-request_target) the default commit is a version
of how a merge would look like. This version is a commit that is automatically
created for GitHub-Actions and not available in the Web GUI of GitHub.
For pull-request-target the default commit is the latest commit of the branch
where the fork started. Therefore, no code developed in the fork is accessible.
This makes sense from a security point of view.
But as we want to mirror the new code, we need to access it. Therefore,
the SHA of the checkout is set to the latest commit in the pull-request.

A workflow similar to the one described above can be found in the project
[pySDC](<https://github.com/Parallel-in-Time/pySDC>)
by the Parallel-in-Time community.

## Troubleshoot

### Action failing unexpectedly

When an action (e.g. for mirroring) fails unexpectedly, please double-check
if the GitLab-project offers a valid Project-Access-Token
(see [Preparation](#preparation) for details). If the token is invalid,
API-calls are rejected (even if API-calls without token succeed).

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

## License

Copyright © 2022 Jakob Fritz - Forschungszentrum Jülich GmbH, Germany (<https://www.fz-juelich.de/>)

This work is licensed under the following license(s):

- Insignificant files are licensed under [CC0-1.0](LICENSES/CC0-1.0.txt)
- Everything else is licensed under [MIT](LICENSES/MIT.txt)

Please see the individual files for more accurate information.

> **Hint:** We provided the copyright and license information in accordance
to the [REUSE Specification 3.0](<https://reuse.software/spec/>).
