#!/bin/bash

set_debug(){
  if [[ "${SNYK_BULK_DEBUG}" ]]; then
    set -x
  fi
}

echo_file() {
  #setDebug

  echo "$1"
  #echo "$BASE"
  #echo "$SOURCEDIR"
}

snyk_cmd(){
  set_debug
  if ! [[ -z "${SNYK_BULK_DEBUG}" ]]; then
    SNYK_DEBUG="--debug --quiet"
  else
    SNYK_DEBUG="--quiet"
    declare -x PIP_QUIET="true"
    declare -x PIPENV_BARE="true"
  fi
  
  local snyk_cmd="${1}"
  local manifest="${2}"
  local pkg_manager="${3}"
  local project="${4}"

  mkdir -p "${JSON_TMP}/${snyk_cmd}/pass"
  mkdir -p "${JSON_TMP}/${snyk_cmd}/fail"
  
  project_clean="$(echo ${project} | tr '/' '-' | tr ' ' '-' )"
  
  project_json_fail="${JSON_TMP}/${snyk_cmd}/fail/${project_clean}.json"
  project_json_pass="${JSON_TMP}/${snyk_cmd}/pass/${project_clean}.json"

  snyk "${snyk_cmd}" --file="${manifest}" \
    --remote-repo-url="${REMOTE_REPO_URL}" \
    --project-name="${project}" \
    --package-manager=${pkg_manager} \
    --json-file-output="${project_json_fail}" ${SNYK_DEBUG}
  if [ $? == '0' ]; then
    mv "${project_json_fail}" "${project_json_pass}"
  fi
}

snyk_excludes(){
  set_debug
  local target="${1}"
  local -n EXCLUDES=$2

  if [ -f "${target}/.snyk.d/exclude" ]
  then
    local -a exclude_file
    local path
  
    readarray -t exclude_file < "${target}/.snyk.d/exclude"
    EXCLUDES='! -path */node_modules/* ! -path */snyktmp/*'
    for path in "${exclude_file[@]//#*/}"; do
      # very pedantic that we don't want to accidentally render this glob
      if [[ -n "${path}" ]]; then
        EXCLUDES+=' ! -path *'
        EXCLUDES+="${path}"
        EXCLUDES+='*'
      fi
    done
  else
    EXCLUDES='! -path */node_modules/* ! -path */snyktmp/* ! -path */vendor/* ! -path */submodules/*'
  fi
}

output_json(){
  set_debug

  local -a jsonfiles

  readarray -t jsonfiles < <(find "${JSON_TMP}" -type f -name "*.json")

  for jfile in "${jsonfiles[@]}"; do
    echo "${jfile}"
  done
  echo "${#jsonfiles[@]}"

}

cmdline() {
  local arg="$@"
  for arg; do
    local delim=""
    case "$arg" in
      #translate --gnu-long-options to -g (short options)
      --policy-path)    args="${args}-p ";;
      --remote-repo)    args="${args}-r ";;
      --monitor)        args="${args}-m ";;
      --test)           args="${args}-t ";;
      --help)           args="${args}-h ";;
      --verbose)        args="${args}-v ";;
      --debug)          args="${args}-d ";;
      --target)         args="${args}-f ";;
      --json)           args="${args}-j ";;
      #pass through anything else
      *) [[ "${arg:0:1}" == "-" ]] || delim="\""
        args="${args}${delim}${arg}${delim} ";;
    esac
  done

  #Reset the positional parameters to the short options
  eval set -- $args

  while getopts "mthvdp:r:f:j:" OPTION
  do
    case $OPTION in
      p)
        # set the policy file path
        POLICY_FILE_PATH="${OPTARG}"
        ;;
      r)
        # set the project name
        REMOTE_REPO_URL="${OPTARG}"
        ;;
      m)
        # monitor the project
        declare -g SNYK_MONITOR="1"
        ;;
      t)
        # test the project
        declare -g SNYK_TEST="1"
        ;;
      h)
        echo "help usage info here"
        exit
        ;;
      v)
        SNYK_BULK_VERBOSE="1"
        ;;
      d)
        SNYK_BULK_DEBUG="1"
        ;;
      j)
        declare -gx JSON_DIR
        JSON_DIR="${OPTARG}"
        ;;
      f)
        TARGET="${OPTARG}"
        ;;
    esac
  done

  return 0
}