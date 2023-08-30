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
  
  if [ -f ".snyk.d/prep.sh" ]; then
    use_custom
    
  elif [ ! -f "Gemfile.lock" ]; then

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    # set ruby version to the system default for RVM
    ruby_version="system"

    ruby_gemfile_version_string=$(cat Gemfile | egrep "^ruby")
    echo "${timestamp}| ruby gemfile version string: ${ruby_gemfile_version_string}" >> "${SNYK_LOG_FILE}"

    if [[ $ruby_gemfile_version_string =~ ruby[[:space:]][\"|\'][^(0-9|\.)]*(.*)[\"|\'] ]]; then
      ruby_version=${BASH_REMATCH[1]}
      echo "${timestamp}| ruby gemfile version number: ${ruby_version}" >> "${SNYK_LOG_FILE}"
    fi

    ( 
      echo "${timestamp}| setting ENV for RVM" >> "${SNYK_LOG_FILE}"
      source /usr/local/rvm/scripts/rvm;

      if [[ "${ruby_version}" == "system" ]]; then # this means no ruby version was detected in Gemfile, so generate lockfile with system version
        echo "${timestamp}| rubygems install for ${prefix}/${manifest}: $(rvm use system && bundle install --quiet)" >> "${SNYK_LOG_FILE}"
      else
        echo "${timestamp}| rubygems install for ${prefix}/${manifest}: $(rvm install ${ruby_version} && rvm use ${ruby_version} && bundle install --quiet)" >> "${SNYK_LOG_FILE}"
      fi
    ) 2>&1 | tee -a "${SNYK_LOG_FILE}"


  fi

  run_snyk "Gemfile.lock" "rubygems" "${prefix}/${manifest}" 
  
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
  
  if [[ "${SNYK_TEST_COUNT}" == 1 ]]; then
    stdout_test_count
  fi
}

ruby::main "$@"

