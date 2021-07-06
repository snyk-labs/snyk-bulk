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

snyk_pomfile(){
  set_debug

  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")
  
  local prefix
  prefix=${project_path#"${SNYK_TARGET}"}

  cd "${project_path}" || exit
  
  if [[ -f ".snyk.d/prep.sh" ]]; then
    use_custom
  else
    # something there
    
    (mvn install) &>> "${SNYK_LOG_FILE}"

  fi

  run_snyk "${manifest}" "maven" "${prefix}/${manifest}"

  cd "${BASE}" || exit
}

maven::main() {
  declare -x SNYK_LOG_FILE

  cmdline "$@"

  set_debug
  
  SNYK_IGNORES=""
  snyk_excludes "${SNYK_TARGET}" SNYK_IGNORES
  readonly SNYK_IGNORES

  local pomfiles

  set -o noglob
  readarray -t pomfiles < <(find "${SNYK_TARGET}" -type f -name "pom.xml" $SNYK_IGNORES )
  set +o noglob

  for pomfile in "${pomfiles[@]}"; do
    snyk_pomfile "${pomfile}"
  done

  output_json

  if [[ "${SNYK_JSON_STDOUT}" == 1 ]]; then
    stdout_json
  fi

}

maven::main "$@"

