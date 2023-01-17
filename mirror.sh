#!/bin/sh

# SPDX-FileCopyrightText: 2022 Jakob Fritz <j.fritz@fz-juelich.de>
#
# SPDX-License-Identifier: MIT

set -u -e

# Define what branches and tags, etc to fetch and to push
branch="+refs/heads/*:refs/heads/* +refs/tags/*:refs/tags/* +refs/pull/*:refs/heads/pull/*"

# Get the URL of the repo
echo "Getting the URL of the repo"
GITLAB_REPO_URL=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}" | jq '.http_url_to_repo' | sed -e 's/http:\/\///' -e 's/https:\/\///' -e 's/"//g')
echo "URL is https://${GITLAB_REPO_URL}"

# Add the remote Gitlab-Repo to the local git
echo "adding gitlab-repo as remote"
git remote add gitlab "https://TOKENUSER:${GITLAB_TOKEN}@${GITLAB_REPO_URL}"
# Get the current state of the GitHub-Repo
sh -c "git fetch --force origin $branch"

# Push the current state of the repo to GitLab
if [ "${FORCE_PUSH:-}" = "true" ]; then
  # Force push is used to make sure the gitlab-repo is the same as github
  # If gitlab diverges, all changes from github are mirrored to GitLab
  # even if that overwrites changes
  if [ "${PRUNE:-}" = "true" ]; then
    # Check if the remote repo shall be pruned. Pruning leads to fewer obsolete
    # and stale branches, but can lead to errors if multiple repos push there
    sh -c "git push --prune --force gitlab $branch"
  else
    sh -c "git push --force gitlab $branch"
  fi
else
  # If pushing without "force" creates merge-conflicts, the push is aborted
  if [ "${PRUNE:-}" = "true" ]; then
    sh -c "git push --prune gitlab $branch"
  else
    sh -c "git push gitlab $branch"
  fi
fi
# Get the return-code of pushing
ret_code=$?
if [ $ret_code = 0 ]
then
  # Report, that pushing is done and add newline afterwards for formatting
  echo "Done pushing git-repo to https://${GITLAB_REPO_URL}"
else
  # Report, that pushing resulted in an error
  echo "Seems as if an error occured while pushing to https://${GITLAB_REPO_URL}. See above for details"
fi
echo ""
exit $ret_code
