#!/bin/sh

set -u

# Define what branches and tags, etc to fetch and to push
branch="+refs/heads/*:refs/heads/* +refs/tags/*:refs/tags/* +refs/pull/*:refs/heads/pull/*"

# Add the remote Gitlab-Repo to the local git
echo "adding gitlab-repo as remote"
git remote add gitlab "https://TOKENUSER:${GITLAB_TOKEN}@${GITLAB_REPO_URL}"
# Get the current state of the GitHub-Repo
sh -c "git fetch --force origin $branch"

# Push the current state of the repo to GitLab
if [ "${FORCE_PUSH:-}" = "true" ]
then
  # Force push is used to make sure the gitlab-repo is the same as github
  # If gitlab diverges, all changes from github are mirrored to GitLab
  # even if that overwrites changes
  sh -c "git push --prune --force gitlab $branch"
else
  # If pushing without "force" creates merge-conflicts, the push is aborted
  sh -c "git push --prune gitlab $branch"
fi
