#!/bin/bash

# basic script to debug the cmdline parsing function in util

declare -rgx SOURCEDIR=$(dirname "$0")
source "$SOURCEDIR/util.sh"

python::main() {

  declare -g POLICY_FILE_PATH REMOTE_REPO_URL SNYK_MONITOR SNYK_TEST SNYK_BULK_VERBOSE TARGET SNYK_BULK_DEBUG

  cmdline "$@"

  echo $SNYK_TEST

}

python::main "$@"