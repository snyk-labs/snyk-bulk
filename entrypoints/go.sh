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

snyk_gomod(){
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
  elif [ ! -f "go.sum" ]; then

    (go mod tidy) &>> "${SNYK_LOG_FILE}"

  fi

  run_snyk "${manifest}" "gomodules" "${prefix}/${manifest}"

  cd "${BASE}" || exit
}

snyk_dep(){
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
  elif [ ! -f "Gopkg.lock" ]; then

    (dep ensure) &>> "${SNYK_LOG_FILE}"

  fi

  (dep ensure --update) &>> "${SNYK_LOG_FILE}"

  run_snyk "${manifest}" "golangdep" "${prefix}/${manifest}"

  cd "${BASE}" || exit
}

go::main() {
  declare -x SNYK_LOG_FILE

  cmdline "$@"

  set_debug

  SNYK_IGNORES=""
  snyk_excludes "${SNYK_TARGET}" SNYK_IGNORES
  readonly SNYK_IGNORES

  local gomodfile
#  local godepfile

  readarray -t gomodfile < <(find "${SNYK_TARGET}" -type f -name "go.mod" $SNYK_IGNORES )
#  readarray -t godepfile < <(find "${SNYK_TARGET}" -type f -name "Gopkg.lock" $SNYK_IGNORES )

  for gomodfile in "${gomodfile[@]}"; do
    snyk_gomod "${gomodfile}"
  done

#  for godepfile in "${godepfile[@]}"; do
#    snyk_dep "${godepfile}"
#  done

  output_json

  if [[ "${SNYK_JSON_STDOUT}" == 1 ]]; then
    stdout_json
  fi

}

go::main "$@"

