#!/bin/sh

set -u
##################################################################

branch="+refs/heads/*:refs/heads/* +refs/tags/*:refs/tags/* +refs/pull/*:refs/heads/pull/*"

echo "adding gitlab-repo as remote"
git remote add gitlab "https://TOKENUSER:${GITLAB_TOKEN}@${GITLAB_REPO_URL}"
sh -c "git fetch --force origin +refs/heads/*:refs/heads/* +refs/tags/*:refs/tags/* +refs/pull/*:refs/heads/pull/*"

if [ "${FORCE_PUSH:-}" = "true" ]
then
  sh -c "git push --prune --force gitlab $branch"
else
  sh -c "git push --prune gitlab $branch"
fi
