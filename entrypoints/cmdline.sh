#!/bin/bash


usage() {
  echo "hello"
}


cmdline() {
  local arg=("$@")
  for arg; do
    local delim=""
    case "$arg" in
      #translate --gnu-long-options to -g (short options)
      --policy-path)        args="${args}-p ";;
      --remote-repo-url)    args="${args}-r ";;
      --monitor)            args="${args}-m ";;
      --test)               args="${args}-t ";;
      --help)               args="${args}-h ";;
      --verbose)            args="${args}-v ";;
      --debug)              args="${args}-d ";;
      --target)             args="${args}-f ";;
      --json-file-output)   args="${args}-j ";;
      --json-std-out)       args="${args}-q ";;
      --severity-threshold) args="${args}-s ";;
      --fail-on)            args="${args}-o ";;
      #pass through anything else
      *) [[ "${arg:0:1}" == "-" ]] || delim="\""
        args="${args}${delim}${arg}${delim} ";;
    esac
  done

  #Reset the positional parameters to the short options
  eval set -- $args

  while getopts "mthqdp:r:f:j:s:o:" OPTION
  do
    case $OPTION in
      p)
        # set the policy file path
        declare -gx POLICY_FILE_PATH="${OPTARG}"
        ;;
      r)
        # set the project name
        declare -gx REMOTE_REPO_URL="${OPTARG}"
        ;;
      m)
        # monitor the project
        declare -gx SNYK_MONITOR="1"
        ;;
      t)
        # test the project
        declare -gx SNYK_TEST="1"
        ;;
      h)
        usage
        exit 2
        ;;
      d)
        declare -gx SNYK_BULK_DEBUG="1"
        ;;
      j)
        declare -gx JSON_DIR="${OPTARG}"
        ;;
      f)
        declare -gx TARGET="${OPTARG}"
        ;;
      
      s)
        declare -gx SEVERITY="${OPTARG}"
        ;;
      o)
        declare -gx FAIL="${OPTARG}"
        ;;      
      q)
        declare -gx JSON_STDOUT="1"
        ;;
      :)
        echo "Missing option argument for -$OPTARG" >&2
        exit 1;;
      
      *)
        echo "Invalid Flags" >&2
        exit 1;;
    
    esac
  done
  shift $((OPTIND -1))

  remaining_args="$*"

  if ! [[ -z "${remaining_args}" ]]; then
    declare -gx SNYK_EXTRA_OPTIONS="${remaining_args}"
  fi

  declare -gx JSON_TMP
  JSON_TMP="${JSON_DIR:=$(mktemp -d)}"
  readonly JSON_TMP

  ISO8601=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  LOG_FILE="${JSON_TMP}/$(basename "${0}")-${ISO8601}-log.txt"

  if [[ ! -d  "${JSON_TMP}" ]] ; then
    mkdir -p "${JSON_TMP}"
  fi

  # shellcheck disable=SC2034
  readonly LOG_FILE

  return 0
}



cmdline::test() {

  set -x

  #declare -g POLICY_FILE_PATH REMOTE_REPO_URL SNYK_MONITOR SNYK_TEST SNYK_BULK_VERBOSE TARGET SNYK_BULK_DEBUG

  cmdline "$@"

  echo "SNYK_TEST = ${SNYK_TEST}"
  echo "SNYK_MONITOR = ${SNYK_MONITOR}"
  echo "TARGET = ${TARGET}"
  echo "SNYK_BULK_DEBUG = ${SNYK_BULK_DEBUG}"
  echo "REMOTE_REPO_URL = ${REMOTE_REPO_URL}"
  echo "SEVERITY=${SEVERITY}"
  echo "FAIL=${FAIL}"
  echo "echo SNYK_EXTRA_OPTIONS=${SNYK_EXTRA_OPTIONS}"
  echo "echo JSON_TMP=${JSON_TMP}"
  echo "echo JSON_STDOUT=${JSON_STDOUT}"

}

#cmdline::test "$@"