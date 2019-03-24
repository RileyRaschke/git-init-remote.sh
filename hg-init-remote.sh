#!/bin/bash

DEFAULT_HOST='scm'
DEFAULT_BASE="/var/hg/$USER"
DEFAULT_REMOTE_ENV='/some/env/file' # probably needs full path... maybe has home context.. maybe not.

# user config
rc=~/.hg-init-remote.sh.conf

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

echo "Resolved config:"
echo -e "\tscmHost=$scmHost"
echo -e "\trepoBase=$repoBase"
echo -e "\trepoName=$repoName"
echo -e "\trepoPath=$repoPath"
echo -e "\trepo=$repo\n"

remoteCmd=$(echo -e "/bin/bash -c \
   \"test -r '${remoteEnvFile}' && . '${remoteEnvFile}' ; \
  test -d '${repo}' && { echo 'WARN: Remote repo: ${repo} already exists!' >&2 ; exit 1; } \
  || test -d '${repoPath}' \
  || { mkdir -p '${repoPath}' && hg init '${repo}' ; } \
  && { test  -d '${repo}' || hg init '${repo}' ; }\" "\
)
#echo -e "$remoteCmd"

if [ ! -z "$repoName" ]
then
  echo "Trying to initialize: ssh://${scmHost}/${repo}"
  ssh $scmHost "${remoteCmd}" || { test -z "${continueOnError}" && { echo "Errors Occured... Exiting." >&2 ; exit 1; } ; }

  test -d "$repo" && { echo "WARN: Local repostiory already exists! $repo" >&2 ; exit 1; } \
    || echo "Trying clone from: ssh://${scmHost}/${repo}" \
    && echo "in to: ${repo}"  \
    && test -d "${repoPath}" || mkdir -p "${repoPath}" \
    && { test -d "${repo}" || hg clone "ssh://${scmHost}/${repo}" "${repo}" ; }

else
  echo -e "^^ I didn't run! ^^\nUsage: $0 repositoryName"
fi

