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

snyk_nuget(){
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
  elif [[ -f "project.json" ]]; then

    (dotnet restore ) &>> "${SNYK_LOG_FILE}"
    run_snyk "${manifest}" "nuget" "${prefix}/${manifest}"

  elif [[ -f "packages.config" ]]; then

    (dotnet restore ) &>> "${SNYK_LOG_FILE}"
    run_snyk "${manifest}" "nuget" "${prefix}/${manifest}"

  elif  [[ -f "project.assets.json" ]]; then

    (dotnet restore ) &>> "${SNYK_LOG_FILE}"
    run_snyk "${manifest}" "nuget" "${prefix}/${manifest}"

  fi

  cd "${BASE}" || exit
}

snyk_paket(){
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
    if ! [ -f "paket.lock" ]; then
      (dotnet paket install) &>> "${SNYK_LOG_FILE}"
  fi

  run_snyk "${manifest}" "nuget" "${prefix}/${manifest}"
  fi

  cd "${BASE}" || exit
}

dotnet::main() {
  declare -x SNYK_LOG_FILE

  cmdline "$@"

  set_debug

  SNYK_IGNORES=""
  snyk_excludes "${SNYK_TARGET}" SNYK_IGNORES
  readonly SNYK_IGNORES

  local projectfiles
  local packagesfiles
  local assetsfiles
  local paketfiles

  set -o noglob
  readarray -t projectfiles < <(find "${SNYK_TARGET}" -type f -name "project.json" $SNYK_IGNORES )
  readarray -t packagesfiles < <(find "${SNYK_TARGET}" -type f -name "packages.config" $SNYK_IGNORES )
  readarray -t assetsfiles < <(find "${SNYK_TARGET}" -type f -name "project.assets.json" $SNYK_IGNORES )
  readarray -t paketfiles < <(find "${SNYK_TARGET}" -type f -name "paket.dependencies" $SNYK_IGNORES )
  set +o noglob

  for projectfile in "${projectfiles[@]}"; do
    snyk_nuget "${projectfile}"
  done

  for packagesfile in "${packagesfiles[@]}"; do
    snyk_nuget "${packagesfile}"
  done

  for assetsfile in "${assetsfiles[@]}"; do
    snyk_nuget "${assetsfile}"
  done

  for paketfile in "${paketfiles[@]}"; do
    snyk_paket "${paketfile}"
  done

  output_json

  if [[ "${SNYK_JSON_STDOUT}" == 1 ]]; then
    stdout_json
  fi

}

dotnet::main "$@"

