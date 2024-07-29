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

# First unshallow the git repository
if "$(git rev-parse --is-shallow-repository)"; then
  git fetch --unshallow
else
  git fetch
fi

if [ -n "${MIRROR_BRANCH:+1}" ]
then
  sh -c "git fetch --prune --no-tags --force origin"
  sh -c "git checkout ${MIRROR_BRANCH}"
  BRANCHNAME="${MIRROR_BRANCH}"
elif [ "${GITHUB_EVENT_NAME}" = 'pull_request' ] || [ "${GITHUB_EVENT_NAME}" = 'pull_request_target' ]
then
  sh -c "git fetch --prune --no-tags --force origin +${PR_HEAD_SHA}"
  sh -c "git checkout ${PR_HEAD_SHA}"
  BRANCHNAME="PullRequest_${PR_NUMBER}"
  sh -c "git branch $BRANCHNAME"
  sh -c "git checkout $BRANCHNAME"
else
  sh -c "git fetch --prune --no-tags --force origin"
  sh -c "git checkout ${GITHUB_REF_NAME}"
  sh -c "git pull --no-tags --force origin ${GITHUB_REF_NAME}"
  BRANCHNAME="${GITHUB_REF_NAME}"
fi

echo "git status is:"
git status
echo "Pushing to new gitlab remote"
# Push the current state of the repo to GitLab
if [ "${FORCE_PUSH:-}" = "true" ]; then
  # Force push is used to make sure the gitlab-repo is the same as github
  # If gitlab diverges, all changes from github are mirrored to GitLab
  # even if that overwrites changes
  git push --force gitlab "$BRANCHNAME" 1>push_stdout 2>push_stderr
else
  # If pushing without "force" creates merge-conflicts, the push is aborted
  git push gitlab "$BRANCHNAME" >push_out 2>&1
fi
# Get the return-code of pushing
ret_code=$?
push_out_var=$(cat push_out)
echo "$push_out_var"

if grep "Everything up-to-date" < push_out ; then
  echo "No changes occured, so no need to push again; triggering Pipeline instead."
  post_reply=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --silent --request POST -d "ref=$BRANCHNAME" "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/pipeline")
  web_url=$(echo "$post_reply" | jq '.web_url')
  echo "Triggered pipeline can be found here: $web_url"
  exit $ret_code
fi 

if [ $ret_code = 0 ]; then
  # Report, that pushing is done and add newline afterwards for formatting
  echo "Done pushing git-repo to https://${GITLAB_REPO_URL}"
else
  # Report, that pushing resulted in an error
  echo "Seems as if an error occured while pushing to https://${GITLAB_REPO_URL}. See above for details"
fi
echo ""
exit $ret_code
