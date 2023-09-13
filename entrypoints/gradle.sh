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

snyk_gradlefile(){
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
  #else
    # something there
    # nothing is required for gradle, cli will do it's thing

  fi

  run_snyk "${manifest}" "gradle" "${prefix}/${manifest}"

  cd "${BASE}" || exit
}

gradle::main() {
  declare -x SNYK_LOG_FILE

  cmdline "$@"

  set_debug
  
  SNYK_IGNORES=""
  snyk_excludes "${SNYK_TARGET}" SNYK_IGNORES
  readonly SNYK_IGNORES

  local gradlegroovyfiles
  local gradlekotlinfiles

  set -o noglob
  readarray -t gradlegroovyfiles < <(sort_manifests "$(find "${SNYK_TARGET}" -type f -name "build.gradle" $SNYK_IGNORES)")
  readarray -t gradlekotlinfiles < <(sort_manifests "$(find "${SNYK_TARGET}" -type f -name "build.gradle.kts" $SNYK_IGNORES)")
  set +o noglob

  for gradlefile in "${gradlegroovyfiles[@]}"; do
    snyk_gradlefile "${gradlefile}"
  done

  for gradlefile in "${gradlekotlinfiles[@]}"; do
    snyk_gradlefile "${gradlefile}"
  done

  output_json

  if [[ "${SNYK_JSON_STDOUT}" == 1 ]]; then
    stdout_json
  fi

  if [[ "${SNYK_TEST_COUNT}" == 1 ]]; then
    stdout_test_count
  fi

}

gradle::main "$@"

