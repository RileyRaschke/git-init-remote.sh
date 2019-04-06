#!/bin/bash

test -e $(which git) || { echo "No git executable found on your path, please install git!" >&2 ; exit 1; }

DEFAULT_HOST='scm'
DEFAULT_LOCAL_BASE="~/git"
DEFAULT_REMOTE_BASE="/var/git/$USER"
DEFAULT_REMOTE_EXT='.git'
DEFAULT_REMOTE_ENV='/some/env/file' # probably needs full path... maybe has home context.. maybe not.

# user config
rc=~/.git-init-remote.sh.conf

# load it if theyy got it
test -f "$rc" && . "$rc"

# Or default...
scmHost="${scmHost:-$DEFAULT_HOST}"
localRepoBase="${localRepoBase:-$DEFAULT_LOCAL_BASE}"
remoteRepoBase="${remoteRepoBase:-$DEFAULT_REMOTE_BASE}"
remoteEnvFile="${remoteEnvFile:-$DEFAULT_REMOTE_ENV}"
remoteExt="${remoteExt:-$DEFAULT_REMOTE_EXT}"

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
localRepoBase=${localRepoBase}
remoteRepoBase=${remoteRepoBase}
remoteEnvFile=${remoteEnvFile}
remoteExt=${remoteExt}
continueOnError=1 #leave null to die after remote errors occur
GIT_INIT_REMOTE_CONFIGED=1
##" >&2
fi

localRepoPath=$(echo "${localRepoBase}/$1" | sed "s/\/$(basename "$1")\$//")
remoteRepoPath=$(echo "${remoteRepoBase}/$1" | sed "s/\/$(basename "$1")\$//")
repoName=$(basename "$1")
localRepo="${localRepoPath}/${repoName}"
remoteRepo="${remoteRepoPath}/${repoName}${remoteExt}"

echo "Resolved config:"
echo -e "\tscmHost=$scmHost"
echo -e "\tlocalRepoBase=$localRepoBase"
echo -e "\tremoteRepoBase=$remoteRepoBase"
echo -e "\trepoName=$repoName"
echo -e "\tlocalRepoPath=$localRepoPath"
echo -e "\tremoteRepoPath=$remoteRepoPath"
echo -e "\tremoteRepo=$remoteRepo"

remoteCmd=$(echo -e "/bin/bash -c \
   \"test -r '${remoteEnvFile}' && . '${remoteEnvFile}' ; \
  test -d '${remoteRepo}' && { echo 'WARN: Remote repo: ${remoteRepo} already exists!' >&2 ; exit 1; } \
  || test -d '${remoteRepoPath}' \
  || { mkdir -p '${remoteRepoPath}' && git init --bare '${remoteRepo}' ; } \
  && { test  -d '${remoteRepo}' || git init --bare '${remoteRepo}' ; }\" "\
)
#echo -e "$remoteCmd"

if [ ! -z "$repoName" ]
then
  echo "Trying to initialize: ssh://${scmHost}${remoteRepo}"
  ssh $scmHost "${remoteCmd}" || { test -z "${continueOnError}" && { echo "Errors Occured... Exiting." >&2 ; exit 1; } ; }

  test -d "$localRepo" && { echo "WARN: Local repostiory already exists! $localRepo" >&2 ; exit 1; } \
    || echo "Trying clone from: ssh://${scmHost}${remoteRepo}" \
    && echo "in to: ${localRepo}"  \
    && test -d "${localRepoPath}" || mkdir -p "${localRepoPath}" \
    && { test -d "${localRepo}" || git clone "ssh://${scmHost}${remoteRepo}" "${localRepo}" ; }

else
  echo -e "Usage: $0 repositoryName\n"
fi

