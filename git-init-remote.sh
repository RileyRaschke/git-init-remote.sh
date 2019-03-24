#!/bin/bash

DEFAULT_HOST='scm'
DEFAULT_BASE="/var/git/$USER"
DEFAULT_REMOTE_ENV='/some/env/file' # probably needs full path... maybe has home context.. maybe not.

# user config
rc=~/.git-init-remote.sh.conf

# load it if theyy got it
test -f "$rc" && . "$rc"

# Or default...
scmHost="${scmHost:-$DEFAULT_HOST}"
repoBase="${repoBase:-$DEFAULT_BASE}"
remoteEnvFile="${remoteEnvFile:-$DEFAULT_REMOTE_ENV}"

##
# No configuration? Here's what i'll do on STDERR...
# (write a template just for you!)
##
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
echo "repoPath=$repoPath"
echo "repo=$repo"

remoteCmd=$(echo "/bin/bash \
  test -f "${remoteEnvFile}" && . "${remoteEnvFile}" ; \
  test -d "${repoPath}" \
  || mkdir -p "${repoPath}" \
  && { test -d \"${repo}.git\" || git init --bare \"${repo}.git\"; }" \
)
echo $remoteCmd

if [ ! -z "$repoName" ]
then
  echo "Trying to init ssh://${scmHost}${repo}.git"
  ssh $scmHost "${remoteCmd}"

  echo "Cloning from: ssh://${scmHost}${repo}.git"
  echo " into: ${repo}"
  test -d "${repoPath}" || mkdir -p "${repoPath}" \
    && { test -d "${repo}" || git clone "ssh://${scmHost}${repo}.git" "${repo}" ; }

else
  echo -e "^^ I didn't run! ^^\nUsage: $0 repositoryName"
fi

