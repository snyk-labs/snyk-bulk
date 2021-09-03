#!/bin/bash


usage() {
  echo "help: create usage"
}


function cmdline()
{
  # declare -A INPUT_ARGS

  # INPUT_ARGS="$@"

  # if [[ ${INPUT_ARGS[*]} =~ ' -- ' ]]; then
  #   echo 'yes'
  #   IFS=' -- ' read -r id INPUT_ARGS <<< "${INPUT_ARGS[*]}"
  # fi

  # SNYK_ARGUMENTS=$(getopt -a -n snyk-bulk --long monitor,test,test-count,help,debug,json-std-out \
  # --long policy-path:,remote-repo-url:,target:,json-file-output:,fail-on:,severity-threshold: -- "${INPUT_ARGS[@]}")
  # echo "arguments = $SNYK_ARGUMENTS"
  # [ $? -eq 0 ] || {
  #     echo "Incorrect option provided"
  #     exit 1
  # }
  # eval set -- "$SNYK_ARGUMENTS"
  #echo $1
  while [[ "$1" == -* ]]; do
    case "$1" in
      --monitor)
        # monitor the project
        declare -gx SNYK_MONITOR=1
        ;;
      --test)
        # test the project
        declare -gx SNYK_TEST=1
        ;;
      --test-count)
        declare -gx SNYK_TEST_COUNT=1
        ;;
      --help)
        echo "help: create usage"
        exit 2;;
      --debug)
        declare -gx SNYK_BULK_DEBUG=1
        ;;
      --json-std-out)
        # enable --json
        declare -gx SNYK_JSON_STDOUT=1
        ;;
      --remote-repo-url)
        shift
        declare -gx SNYK_REMOTE_REPO_URL="${1}"
        ;;
      --target)
        shift
        declare -gx SNYK_TARGET="${1}"
        ;;
      --json-file-output)
        shift
        declare -gx SNYK_JSON_DIR="${1}"
        ;;
      --fail-on)
        shift
        declare -gx SNYK_FAIL="${1}"
        ;;
      --severity-threshold)
        shift
        declare -gx SNYK_SEVERITY="${1}"
        ;;
      --)
        # everything after this we pass to snyk
        shift
        break;;
      *) echo "Unexpected option: $1 "
        usage
        exit 2
        break;;
    esac
    shift
  done
  #shift $((OPTIND -1))

  remaining_args=("$@")

  if [[ ${#remaining_args[@]} -gt 0 ]]; then
    declare -gx SNYK_EXTRA_OPTIONS=("${remaining_args[@]}")
    #echo "SNYK_EXTRA_OPTIONS=$SNYK_EXTRA_OPTIONS"
  fi

  declare -gx JSON_TMP
  SNYK_JSON_TMP="${SNYK_JSON_DIR:=$(mktemp -d)}"
  readonly SNYK_JSON_TMP

  ISO8601=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  SNYK_LOG_FILE="${SNYK_JSON_TMP}/$(basename "${0}")-${ISO8601}-log.txt"

  if [[ ! -d  "${SNYK_JSON_TMP}" ]] ; then
    mkdir -p "${SNYK_JSON_TMP}"
  fi

  # we always want these env settings to exist in their default states
  declare -gx SNYK_BULK_DEBUG="${SNYK_BULK_DEBUG:=0}"
  declare -gx SNYK_FAIL="${SNYK_FAIL:="all"}"
  declare -gx SNYK_SEVERITY="${SNYK_SEVERITY:="low"}"
  declare -gx SNYK_REMOTE_REPO_URL="${SNYK_REMOTE_REPO_URL:=0}"
  declare -gx SNYK_MONITOR="${SNYK_MONITOR:=0}"
  declare -gx SNYK_TEST="${SNYK_TEST:=0}"
  declare -gx SNYK_JSON_STDOUT="${SNYK_JSON_STDOUT:=0}"
  declare -gx SNYK_TEST_COUNT="${SNYK_TEST_COUNT:=0}"
  declare -gx SNYK_EXTRA_OPTIONS="${SNYK_EXTRA_OPTIONS:=()}"
  
  if ! [[ -z $SNYK_TARGET ]] && [[ -d "${SNYK_TARGET}" ]]; then
    declare -gx SNYK_TARGET="${SNYK_TARGET}"
  else
    set -e
    echo "Snyk-Bulk ERROR: --target not provided, SNYK_TARGET is empty, or does not exist on the filesystem"
    exit 1
  fi

  if [[ "${SNYK_BULK_DEBUG}" == '1' ]]; then
    #set -euo pipefail
    set -x
  fi

  declare -gx SNYK_HAS_GIT=0

  if command -v git &> /dev/null; then
    SNYK_HAS_GIT=1
  fi

  local snyk_raw_basename snyk_cwd

  if [[ "${SNYK_REMOTE_REPO_URL}" != 0 ]]; then
    snyk_raw_basename="${SNYK_REMOTE_REPO_URL}"
  elif [[ "${SNYK_HAS_GIT}" != 0 ]]; then
    snyk_cwd=${PWD}
    cd "${SNYK_TARGET}"
    snyk_raw_basename="$(git config --get remote.origin.url)"
    cd "${snyk_cwd}"
  else
    set -e
    echo "Snyk-Bulk ERROR: -r / --remote-repo-url not provided and/or git isn't in the path"
    exit 1
  fi

  snyk_raw_basename_ssh="$(echo ${snyk_raw_basename} | grep -v "http" | cut -d: -f2- | cut -d. -f1)"
  snyk_raw_basename_http="$(echo ${snyk_raw_basename} | cut -d/ -f4-)"

  if [[ ${#snyk_raw_basename_ssh} -ge 1 ]]; then
    declare -gx SNYK_BASENAME="${snyk_raw_basename_ssh}"
  elif [[ ${#snyk_raw_basename_http} -ge 1 ]]; then
    declare -gx SNYK_BASENAME="${snyk_raw_basename_http}"
  else
    set -e
    echo "Snyk-Bulk ERROR: Unable to determine the right repository this project is from"
    exit 1
  fi


  # shellcheck disable=SC2034
  readonly SNYK_LOG_FILE SNYK_FAIL SNYK_SEVERITY SNYK_REMOTE_REPO_URL SNYK_MONITOR SNYK_TEST SNYK_BULK_DEBUG SNYK_TEST_COUNT SNYK_BASENAME SNYK_EXTRA_OPTIONS

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