#!/bin/bash

declare -gx SOURCEDIR
SOURCEDIR=$(dirname "$0")
readonly SOURCEDIR

# shellcheck disable=SC1091
# shellcheck source=util.sh
source "${SOURCEDIR}/util.sh"

declare -gx BASE
BASE="$(pwd)"
readonly BASE

snyk_yarnfile() {
  set_debug

  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")
  
  local prefix
  prefix=${project_path#"${TARGET}"}

  cd "${project_path}" || exit
  
  if use_custom; then
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ( echo "${timestamp}|  Custom Script was run for : $${project_path}" >> "${LOG_FILE}" ) 2>&1 | tee -a "${LOG_FILE}"
  
  else
    run_snyk "${manifest}" "yarn" "${prefix}/${manifest}"
  fi

  cd "${BASE}" || exit
}


snyk_packagefile() {
  set_debug

  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")
  
  local prefix
  prefix=${project_path#"${TARGET}"}

  cd "${project_path}" || exit
  
  if use_custom; then
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ( echo "${timestamp}|  Custom Script was run for : ${project_path}" >> "${LOG_FILE}" ) 2>&1 | tee -a "${LOG_FILE}"
  
  elif [ -f "package-lock.json" ] && [ ! -f "yarn.lock" ]; then
  
    run_snyk "package-lock.json" "npm" "${prefix}/${manifest}" 2> /dev/null
  
  elif [ ! -f "package-lock.json" ] && [ ! -f "yarn.lock" ] && [ -d "node_modules" ]; then

    run_snyk "${manifest}" "npm" "${prefix}/${manifest}" 2> /dev/null

  elif [ ! -f "package-lock.json" ] && [ ! -f "yarn.lock" ] && [ ! -d "node_modules" ]; then

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ( echo "${timestamp}| npm install for ${prefix}/${manifest}: $(npm install --silent --package-lock-only --no-audit)" >> "${LOG_FILE}" ) 2>&1 | tee -a "${LOG_FILE}"

    run_snyk "package-lock.json" "npm" "${prefix}/${manifest}"    

  fi
  
  cd "${BASE}" || exit
}

node::main() {
  declare -x LOG_FILE

  cmdline "$@"

  set_debug
  
  IGNORES=""
  snyk_excludes "${TARGET}" IGNORES
  readonly IGNORES

  local yarnfiles
  local packages

  readarray -t yarnfiles < <(find "${TARGET}" -type f -name "yarn.lock" $IGNORES )
  readarray -t packages < <(find "${TARGET}" -type f -name "package.json" $IGNORES )
  
  for yarnfile in "${yarnfiles[@]}"; do
    snyk_yarnfile "${yarnfile}"
  done

  for packagefile in "${packages[@]}"; do
    snyk_packagefile "${packagefile}"
  done

  output_json

  if [[ "${JSON_STDOUT}" == 1 ]]; then
    stdout_json
  fi

}

node::main "$@"

