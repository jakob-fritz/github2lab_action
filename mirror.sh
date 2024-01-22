#!/bin/sh

# SPDX-FileCopyrightText: 2022 Jakob Fritz <j.fritz@fz-juelich.de>
#
# SPDX-License-Identifier: MIT

set -u -e

# Get the URL of the repo
echo "Getting the URL of the repo"
GITLAB_REPO_URL=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}" | jq '.http_url_to_repo' | sed -e 's/http:\/\///' -e 's/https:\/\///' -e 's/"//g')
echo "URL is https://${GITLAB_REPO_URL}"

# Add the remote Gitlab-Repo to the local git
echo "adding gitlab-repo as remote"
git remote add gitlab "https://TOKENUSER:${GITLAB_TOKEN}@${GITLAB_REPO_URL}"
# Get current state of local git
echo "Running git fetch, git checkout, git pull"
# Get the current state of the single branch from the GitHub-Repo
# In case this is a pull-request, add this to fetch
if [ "${GITHUB_EVENT_NAME}" = 'pull_request' ] || [ "${GITHUB_EVENT_NAME}" = 'pull_request_target' ]
  then
    sh -c "git fetch --unshallow --prune --no-tags --force origin +${GITHUB_EVENT_PULL_REQUEST_HEAD_SHA}"
    sh -c "git checkout ${GITHUB_EVENT_PULL_REQUEST_HEAD_SHA}"
    sh -c "git branch PullRequest_${GITHUB_EVENT_NUMBER}"
    sh -c "git checkout PullRequest_${GITHUB_EVENT_NUMBER}"
  else
    sh -c "git fetch --unshallow --prune --no-tags --force origin"
    sh -c "git checkout ${GITHUB_REF}"
    sh -c "git pull --no-tags --force origin ${GITHUB_REF}"
fi

echo "git status is:"
git status
echo "Pushing to new gitlab remote"
# Push the current state of the repo to GitLab
if [ "${FORCE_PUSH:-}" = "true" ]; then
  # Force push is used to make sure the gitlab-repo is the same as github
  # If gitlab diverges, all changes from github are mirrored to GitLab
  # even if that overwrites changes
  sh -c "git push --force gitlab ${GITHUB_REF}"
else
  # If pushing without "force" creates merge-conflicts, the push is aborted
  sh -c "git push gitlab ${GITHUB_REF}"
fi
# Get the return-code of pushing
ret_code=$?
if [ $ret_code = 0 ]; then
  # Report, that pushing is done and add newline afterwards for formatting
  echo "Done pushing git-repo to https://${GITLAB_REPO_URL}"
else
  # Report, that pushing resulted in an error
  echo "Seems as if an error occured while pushing to https://${GITLAB_REPO_URL}. See above for details"
fi
echo ""
exit $ret_code
