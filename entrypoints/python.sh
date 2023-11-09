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

install_pipenv(){
  set_debug
  if ! command -v pipenv > /dev/null 2>&1 ; then
    pip --quiet -install pipenv
  fi
}

install_poetry(){
  set_debug
  if ! command -v poetry > /dev/null 2>&1 ; then
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python - > /dev/null 2>&1
  fi
}

snyk_pipfile(){
  set_debug

  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")
  
  local prefix
  prefix=${project_path#"${SNYK_TARGET}"}

  install_pipenv

  cd "${project_path}" || exit
  
  if [[ -f ".snyk.d/prep.sh" ]]; then
    use_custom
  else
  
    declare -xg PIPENV_NOSPIN=1 NO_COLOR=1 PIPENV_QUIET=1 PIP_QUIET=1 PIPENV_HIDE_EMOJIS=1
    
    sed -i '/python_version/d' Pipfile

    if [[ -f "Pipfile.lock" ]]; then
      (pipenv sync ) &>> "${SNYK_LOG_FILE}"
    else
      (pipenv update ) &>> "${SNYK_LOG_FILE}"
    fi

  fi

  run_snyk "${manifest}" "pip" "${prefix}/${manifest}"

  unset PIPENV_NOSPIN NO_COLOR PIPENV_QUIET PIP_QUIET PIPENV_HIDE_EMOJIS

  cd "${BASE}" || exit
}

snyk_poetry(){
  set_debug

  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")
  
  local prefix
  prefix=${project_path#"${SNYK_TARGET}"}

  install_poetry

  cd "${project_path}" || exit
  if [ -f ".snyk.d/prep.sh" ]; then
    use_custom
  else
    if ! grep -q -F "[tool.poetry]" pyproject.toml; then
      return
    fi
    if ! [ -f "poetry.lock" ]; then
      poetry lock --no-update --quiet --no-interaction
    fi
  fi

  run_snyk "poetry.lock" "poetry" "${prefix}/${manifest}"

  cd "${BASE}" || exit
}

snyk_reqfile(){
  set_debug

  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")
  
  local prefix
  prefix=${project_path#"${SNYK_TARGET}"}

  cd "${project_path}" || exit
  if ! [[ -d 'snyktmp' ]]; then
    virtualenv --quiet snyktmp 
  fi
  source snyktmp/bin/activate

  if [ -f ".snyk.d/prep.sh" ]; then
    use_custom
  else
    pip install --quiet -r requirements.txt
  fi

  run_snyk "${manifest}" "pip" "${prefix}/${manifest}"
  deactivate
  
  cd "${BASE}" || exit
}

snyk_setupfile(){
  set_debug

  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")
  
  local prefix
  prefix=${project_path#"${SNYK_TARGET}"}

  cd "${project_path}" || exit
  if ! [[ -d 'snyktmp' ]]; then
    virtualenv --quiet snyktmp
  fi
  source snyktmp/bin/activate

  if [ -f ".snyk.d/prep.sh" ]; then
    use_custom
  elif ! [[ -f "requirements.txt" ]]; then
    pip install --quiet -U -e ./ && pip --quiet freeze > requirements.txt

    # Only need to run Snyk if there was not requirements.txt file
    run_snyk "${manifest}" "pip" "${prefix}/${manifest}"
  fi

  deactivate
  
  cd "${BASE}" || exit
}

python::main() {
  declare -x SNYK_LOG_FILE

  # global python settings here
  declare -x PIP_DISABLE_PIP_VERSION_CHECK=1

  cmdline "$@"

  set_debug
  
  SNYK_IGNORES=""
  snyk_excludes "${SNYK_TARGET}" SNYK_IGNORES
  readonly SNYK_IGNORES

  local pipfiles
  local poetryfiles
  local reqfiles
  local setupfiles

  set -o noglob
  readarray -t pipfiles < <(sort_manifests "$(find "${SNYK_TARGET}" -type f -name "Pipfile" $SNYK_IGNORES)")
  readarray -t poetryfiles < <(sort_manifests "$(find "${SNYK_TARGET}" -type f -name "pyproject.toml" $SNYK_IGNORES)")
  readarray -t reqfiles < <(sort_manifests "$(find "${SNYK_TARGET}" -type f -name "requirements.txt" $SNYK_IGNORES)")
  readarray -t setupfiles < <(sort_manifests "$(find "${SNYK_TARGET}" -type f -name "setup.py" $SNYK_IGNORES)")
  set +o noglob
  
  for pipfile in "${pipfiles[@]}"; do
    snyk_pipfile "${pipfile}"
  done

  for poetryfile in "${poetryfiles[@]}"; do
    snyk_poetry "${poetryfile}"
  done

  for reqfile in "${reqfiles[@]}"; do
    snyk_reqfile "${reqfile}"
  done

  for setupfile in "${setupfiles[@]}"; do
    snyk_setupfile "${setupfile}"
  done

  output_json

  if [[ "${SNYK_JSON_STDOUT}" == 1 ]]; then
    stdout_json
  fi

  if [[ "${SNYK_TEST_COUNT}" == 1 ]]; then
    stdout_test_count
  fi

}

python::main "$@"

