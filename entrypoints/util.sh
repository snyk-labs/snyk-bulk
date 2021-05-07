#!/bin/bash

# shellcheck disable=SC1091
# shellcheck source=cmdline.sh
source "${SOURCEDIR}/cmdline.sh"

set_debug(){
  if [[ "${SNYK_BULK_DEBUG}" == '1' ]]; then
    set -x
  fi
}

echo_file() {
  #setDebug

  echo "$1"
  #echo "$BASE"
  #echo "$SOURCEDIR"
}

run_snyk() {
  local manifest pkg_manager project
  manifest="${1}"
  pkg_manager="${2}"
  project="${3}"

  if [[ "${SNYK_TEST}" == 1 ]]; then
    snyk_cmd 'test' "${manifest}" "${pkg_manager}" "${project}"
  fi

  if [[ "${SNYK_MONITOR}" == 1 ]]; then
    snyk_cmd 'monitor' "${manifest}" "${pkg_manager}" "${project}"
  fi

}

snyk_cmd(){
  set_debug
  if [[ "${SNYK_BULK_DEBUG}" == '1' ]]; then
    SNYK_DEBUG="--debug"
  else
    SNYK_DEBUG=""
    declare -xg CI=1
  fi
  local snyk_action manifest pkg_manager project
  snyk_action="${1}"
  manifest="${2}"
  pkg_manager="${3}"
  project="${4}"

  local severity_level fail_on remote_repo

  severity_level="${SNYK_SEVERITY}"  
  fail_on="${SNYK_FAIL}"


  if [[ "${SNYK_REMOTE_REPO_URL}" != '0' ]]; then
    remote_repo="--remote-repo-url=${SNYK_REMOTE_REPO_URL}"
  else
    remote_repo=''
  fi

  mkdir -p "${SNYK_JSON_TMP}/${snyk_action}/pass"
  mkdir -p "${SNYK_JSON_TMP}/${snyk_action}/fail"

  # shellcheck disable=SC2086
  project_clean="$(echo ${project} | tr '/' '-' | tr ' ' '-' )"
  
  project_json_fail="${SNYK_JSON_TMP}/${snyk_action}/fail/$(basename "${0}")-${project_clean}.json"
  project_json_pass="${SNYK_JSON_TMP}/${snyk_action}/pass/$(basename "${0}")-${project_clean}.json"


  if [[ ${snyk_action} == "monitor" ]]; then
    snyk monitor --file="${manifest}" \
      --project-name="${project}" \
      --package-manager="${pkg_manager}" \
      --severity-threshold="${severity_level}" --fail-on="${fail_on}" ${SNYK_DEBUG} ${remote_repo} \
      --json > "${project_json_fail}"
    if [ "${PIPESTATUS[0]}" == '0' ]; then
      mv "${project_json_fail}" "${project_json_pass}"
    fi

  else
    snyk test --file="${manifest}" \
      --project-name="${project}" \
      --package-manager="${pkg_manager}" \
      --severity-threshold="${severity_level}" --fail-on="${fail_on}" \
      --json-file-output="${project_json_fail}" ${SNYK_DEBUG} ${remote_repo}
    if [ $? == '0' ]; then
      mv "${project_json_fail}" "${project_json_pass}"
    fi
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

  local timestamp

  readarray -t jsonfiles < <(find "${SNYK_JSON_TMP}" -type f -name "*.json")

  for jfile in "${jsonfiles[@]}"; do
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ( echo "${timestamp}|  ${jfile}" >> "${SNYK_LOG_FILE}" ) 2>&1 | tee -a "${SNYK_LOG_FILE}"
  done
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  ( echo "${timestamp}|  Total Projects Tested/Monitored: ${#jsonfiles[@]}" >> "${SNYK_LOG_FILE}" ) 2>&1 | tee -a "${SNYK_LOG_FILE}"

}

stdout_json(){
  local entrypoint
  entrypoint=$(basename "${0}")

  local -a jsonfiles
  readarray -t jsonfiles < <(find "${SNYK_JSON_TMP}" -type f -name "${entrypoint}*.json")
  
  json_file="["
  json_delim=""
  for jfile in "${jsonfiles[@]}"; do
    file_contents=$(cat ${jfile})
    if [[ -n $file_contents ]]; then
      json_file+="${json_delim}${file_contents}"
      json_delim=","
    fi
  done
  json_file+="]"

  printf '%s' "${json_file}"

}

use_custom(){
  # this is a stub function for now

  if [ -f .snyk.d/prep.sh ]; then
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ( echo "${timestamp}|  Custom Script found and starting execution for : $${project_path}" >> "${SNYK_LOG_FILE}" ) 2>&1 | tee -a "${SNYK_LOG_FILE}" 
    /bin/bash .snyk.d/prep.sh
    return 0
  else
    return 1
  fi
}