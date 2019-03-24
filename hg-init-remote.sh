#!/bin/bash

DEFAULT_HOST='scm'
DEFAULT_BASE="/var/hg/$USER"
DEFAULT_REMOTE_ENV='/site/etc/siterc'

# user config
rc=~/.hg-init-remote.sh.rc

# load it if theyy got it
test -f "$rc" && . "$rc"

# Or default...
scmHost="${scmHost:-$DEFAULT_HOST}"
repoBase="${repoBase:-$DEFAULT_BASE}"
remoteEnvFile="${remoteEnvFile:-$DEFAULT_REMOTE_ENV}"

##
# No configuration? Here's wheat i'll do on STDERR
# (write it for you!)
##
if [ -z "$HG_INIT_REMOTE_CONFIGED" ]
then

  echo "##" >&2
  test -f "$rc"  \
    && { . "$rc" && echo "# Using $rc" >&2 ; } \
    || echo -e "# no $rc was found!\n# run '$0 2> $rc' to fix and suppres this warning!" >&2

  echo "# resolved config:
scmHost=${scmHost}
repoBase=${repoBase}
remoteEnvFile=${remoteEnvFile}
HG_INIT_REMOTE_CONFIGED=1
##" >&2
fi

repoPath=$(echo "${repoBase}/$1" | sed "s/\/$(basename "$1")\$//")
repoName=$(basename "$1")
repo="${repoPath}/${repoName}"

echo "scmHost=$scmHost"
echo "repoBase=$repoBase"
echo "repoName=$repoName"
echo "repoPath=$repoPath"
echo "repo=$repo"

remoteCmd=$(echo "/bin/bash . $remoteEnvFile ; test -d \"${repoPath}\" || mkdir -p "${repoPath}" && { test -d \"${repo}\" || hg init \"${repo}\"; }")
echo $remoteCmd

if [ ! -z "$repoName" ]
then
  echo "Trying to init ssh://${scmHost}/${repo}"
  ssh $scmHost "${remoteCmd}"

  echo "Cloning from: ssh://${scmHost}/${repo}"
  echo " into: ${repo}"
  test -d "${repoPath}" || mkdir -p "${repoPath}" && { test -d "${repo}" || hg clone "ssh://${scmHost}/${repo}" "${repo}" ; }
else
  echo -e "\nUsage: $0 repositoryName"
fi

