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

snyk_gemfile() {
  set_debug

  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")
  
  local prefix
  prefix=${project_path#"${SNYK_TARGET}"}

  cd "${project_path}" || exit
  
  if use_custom; then
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ( echo "${timestamp}|  Custom Script was run for : ${project_path}" >> "${SNYK_LOG_FILE}" ) 2>&1 | tee -a "${SNYK_LOG_FILE}"
  
  elif [ -f "Gemfile.lock" ]; then
  
    run_snyk "Gemfile.lock" "rubygems" "${prefix}/${manifest}" 2> /dev/null
  
  elif [ ! -f "Gemfile.lock" ]; then

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ( echo "${timestamp}| rubygems install for ${prefix}/${manifest}: $(bundler install --quiet)" >> "${SNYK_LOG_FILE}" ) 2>&1 | tee -a "${SNYK_LOG_FILE}"

    run_snyk "Gemfile.lock" "rubygems" "${prefix}/${manifest}"    

  fi
  
  cd "${BASE}" || exit
}

ruby::main() {
  declare -x SNYK_LOG_FILE

  cmdline "$@"

  set_debug
  
  SNYK_IGNORES=""
  snyk_excludes "${SNYK_TARGET}" SNYK_IGNORES
  readonly SNYK_IGNORES

  # so RVM environment gets set
  #source /usr/local/rvm/scripts/rvm

  local gemfiles

  set -o noglob
  readarray -t gemfiles < <(find "${SNYK_TARGET}" -type f -name "Gemfile" $SNYK_IGNORES )
  set +o noglob


  for gemfile in "${gemfiles[@]}"; do
    snyk_gemfile "${gemfile}"
  done

  output_json

  if [[ "${SNYK_JSON_STDOUT}" == 1 ]]; then
    stdout_json
  fi

}

ruby::main "$@"

