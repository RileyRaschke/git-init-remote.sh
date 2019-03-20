#!/bin/bash

DEFAULT_HOST='scm'
DEFAULT_BASE="/var/git/$USER"
DEFAULT_REMOTE_ENV='/site/etc/siterc'

rc=~/.git-init-remote.sh.rc

test -f "$rc" && . "$rc"

scmHost="${scmHost:-$DEFAULT_HOST}"
repoBase="${repoBase:-$DEFAULT_BASE}"
remoteEnvFile="${remoteEnvFile:-$DEFAULT_REMOTE_ENV}"

if [ -z "$GIT_INIT_REMOTE_CONFIGED" ]
then
  echo "##" >&2
  test -f "$rc"  \
    && { . "$rc" && echo "# Using $rc" >&2 ; } \
    || echo -e "# no $rc was found!\n# run '$0 2> $rc' to fix and suppres this warning!" >&2

  echo "# resolved config:
scmHost=${scmHost}
repoBase=${repoBase}
remoteEnvFile=${remoteEnvFile}
GIT_INIT_REMOTE_CONFIGED=1
##" >&2
fi

repoPath=$(echo "${repoBase}/$1" | sed "s/\/$(basename "$1")\$//")
repoName=$(basename "$1")
repo="${repoPath}/${repoName}"

echo "scmHost=$scmHost"
echo "repoBase=$repoBase"
echo "repoName=$repoName"
echo "repoPath=$repo"

if [ ! -z "$repoName" ]
then
  remoteCmd=$(echo "/bin/bash . $remoteEnvFile ; test -d \"${repoPath}\" && { test -d \"${repo}.git\" || git init --bare \"${repo}.git\"; }")

  echo $remoteCmd

  echo "Trying to init ssh://${scmHost}${repo}.git"
  ssh $scmHost "${remoteCmd}"

  echo "Cloning from: ssh://${scmHost}${repo}.git"
  echo " into: ${repo}"
  test -d "${repoPath}" && { test -d "${repo}" || git clone "ssh://${scmHost}${repo}.git" "${repo}" ; }

else

  echo -e "\nUsage: $0 repositoryName"

fi

