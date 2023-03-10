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
  elif [ -f "package-lock.json" ] && [ ! -e "yarn.lock" ]; then
  
    run_snyk "package-lock.json" "npm" "${prefix}/${manifest}"
  
  elif [ ! -f "package-lock.json" ] && [ ! -e "yarn.lock" ] && [ -d "node_modules" ]; then

    run_snyk "${manifest}" "npm" "${prefix}/${manifest}"

  elif [ ! -f "package-lock.json" ] && [ ! -e "yarn.lock" ] && [ ! -d "node_modules" ]; then

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ( echo "${timestamp}| npm install for ${prefix}/${manifest}: $(npm install --silent --no-audit)" >> "${SNYK_LOG_FILE}" ) 2>&1 | tee -a "${SNYK_LOG_FILE}"

    run_snyk "package-lock.json" "npm" "${prefix}/${manifest}"    

  fi
  
  cd "${BASE}" || exit
}

prep_for_yarn_workspaces() {
  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")

  cd "${project_path}" || exit
  #readarray -t yarn_workspaces_result < <(set -o pipefail; yarn workspaces list --json | tail -n+2 | cut -f4 -d\")
  yarn_workspaces_result=$(yarn workspaces list --json)
  yarn_workspaces_return_code=$?

  if [[ $yarn_workspaces_return_code -gt 0 ]]; then
    # probably not a yarn workspace project
    # let's go back to the root directory
    break
  else # this is yarn workspace project
    #results will be relative paths
    readarray -t yarn_workspaces_result < <(echo "${yarn_workspaces_result}" | tail -n+2 | cut -f4 -d\")
    for packagedir in "${yarn_workspaces_result[@]}"; do
      ln $manifest $packagedir/$manifest
    done
  fi
}

prep_for_node_workspaces() {
  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")

  cd "${project_path}" || exit

  node_workspaces_result=$(npm --workspaces list --json)
  node_workspaces_return_code=$?

  if [[ $node_workspaces_return_code -gt 0 ]]; then
    # probably not a node workspace project
    # let's go back to the root directory
    break
  else # this is node workspace project
    #create an empty node_modules folder

    readarray -t node_workspaces_result < <(echo "${node_workspaces_result}" | jq -r '.dependencies | keys | .[]')
    for packagedir in "${node_workspaces_result[@]}"; do
      [ -d $packagedir ] && mkdir $packagedir/node_modules
    done
  fi
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

  local targetdir=$(pwd)

  set -o noglob
  readarray -t yarnfiles < <(find "${SNYK_TARGET}" -type f -name "yarn.lock" $SNYK_IGNORES )
  readarray -t packages < <(find "${SNYK_TARGET}" -type f -name "package.json" $SNYK_IGNORES )
  set +o noglob

  # check if any yarn projects are workspaces and prep with hard links
  for yarnfile in "${yarnfiles[@]}"; do
    prep_for_yarn_workspaces "${yarnfile}"
      cd "${targetdir}"
  done

  # check if any yarn projects are workspaces and prep with hard links
  for packagefile in "${packages[@]}"; do
    prep_for_node_workspaces "${packagefile}"
      cd "${targetdir}"
  done

  cd "${targetdir}"

  # check for yarn.lock files again after hard links created
  set -o noglob
  readarray -t yarnfiles < <(find "${SNYK_TARGET}" -type f -name "yarn.lock" $SNYK_IGNORES )
  set +o noglob
  
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

  if [[ "${SNYK_TEST_COUNT}" == 1 ]]; then
    stdout_test_count
  fi

}

node::main "$@"

