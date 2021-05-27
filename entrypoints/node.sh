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
  prefix=${project_path#"${SNYK_TARGET}"}

  cd "${project_path}" || exit
  
  if [ -f ".snyk.d/prep.sh" ]; then
    use_custom
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
  prefix=${project_path#"${SNYK_TARGET}"}

  cd "${project_path}" || exit
  
  if [ -f ".snyk.d/prep.sh" ]; then
    use_custom
  elif [ -f "package-lock.json" ] && [ ! -f "yarn.lock" ]; then
  
    run_snyk "package-lock.json" "npm" "${prefix}/${manifest}" 2> /dev/null
  
  elif [ ! -f "package-lock.json" ] && [ ! -f "yarn.lock" ] && [ -d "node_modules" ]; then

    run_snyk "${manifest}" "npm" "${prefix}/${manifest}" 2> /dev/null

  elif [ ! -f "package-lock.json" ] && [ ! -f "yarn.lock" ] && [ ! -d "node_modules" ]; then

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ( echo "${timestamp}| npm install for ${prefix}/${manifest}: $(npm install --silent --package-lock-only --no-audit)" >> "${SNYK_LOG_FILE}" ) 2>&1 | tee -a "${SNYK_LOG_FILE}"

    run_snyk "package-lock.json" "npm" "${prefix}/${manifest}"    

  fi
  
  cd "${BASE}" || exit
}

node::main() {
  declare -x SNYK_LOG_FILE

  cmdline "$@"

  set_debug
  
  SNYK_IGNORES=""
  snyk_excludes "${SNYK_TARGET}" SNYK_IGNORES
  readonly SNYK_IGNORES

  local yarnfiles
  local packages

  readarray -t yarnfiles < <(find "${SNYK_TARGET}" -type f -name "yarn.lock" $SNYK_IGNORES )
  readarray -t packages < <(find "${SNYK_TARGET}" -type f -name "package.json" $SNYK_IGNORES )
  
  for yarnfile in "${yarnfiles[@]}"; do
    snyk_yarnfile "${yarnfile}"
  done

  for packagefile in "${packages[@]}"; do
    snyk_packagefile "${packagefile}"
  done

  output_json

  if [[ "${SNYK_JSON_STDOUT}" == 1 ]]; then
    stdout_json
  fi

}

node::main "$@"

