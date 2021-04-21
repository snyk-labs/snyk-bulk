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
  prefix=${project_path#"${TARGET}"}

  install_pipenv

  cd "${project_path}" || exit
  
  if [[ -f ".snyk.d/prep.sh" ]]; then
    use_custom
  else
    # something there

    if [[ "${CI}" == "1" ]]; then
      declare -xg PIPENV_NOSPIN=1 PIPENV_COLORBLIND=1 PIPENV_QUIET=1 PIP_QUIET=1 PIPENV_HIDE_EMOJIS=1
    fi
    
    if [[ -f "Pipfile.lock" ]]; then
      (pipenv sync ) &>> "${LOG_FILE}"
    else
      (pipenv update ) &>> "${LOG_FILE}"
    fi

  fi

  run_snyk "${manifest}" "pip" "${prefix}/${manifest}"

  if [ "${CI}" == "1" ]; then
    unset PIPENV_NOSPIN PIPENV_COLORBLIND PIPENV_QUIET PIP_QUIET PIPENV_HIDE_EMOJIS
  fi

  cd "${BASE}" || exit
}

snyk_poetry(){
  set_debug

  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")
  
  local prefix
  prefix=${project_path#"${TARGET}"}

  install_poetry

  cd "${project_path}" || exit
  if [ -f ".snyk.d/prep.sh" ]; then
    use_custom
  else
    if ! [ -f "poetry.lock" ]; then
      poetry lock --no-update --quiet --no-interaction
    fi
  fi

  run_snyk "${manifest}" "poetry" "${prefix}/${manifest}"

  cd "${BASE}" || exit
}

snyk_reqfile(){
  set_debug

  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")
  
  local prefix
  prefix=${project_path#"${TARGET}"}

  cd "${project_path}" || exit
  if [ -f ".snyk.d/prep.sh" ]; then
    use_custom
  else
    if ! [[ -d 'snyktmp' ]]; then
      virtualenv --quiet snyktmp 
    fi
    source snyktmp/bin/activate
    pip install --quiet -r requirements.txt
    run_snyk "${manifest}" "pip" "${prefix}/${manifest}"
    deactivate
  fi
  
  cd "${BASE}" || exit
}

snyk_setupfile(){
  set_debug

  local manifest
  manifest=$(basename "$1")
  local project_path
  project_path=$(dirname "$1")
  
  local prefix
  prefix=${project_path#"${TARGET}"}

  cd "${project_path}" || exit
  if [ -f ".snyk.d/prep.sh" ]; then
    use_custom
  elif ! [[ -f "requirements.txt" ]]; then
    if ! [[ -d 'snyktmp' ]]; then
      virtualenv --quiet snyktmp
    fi
    source snyktmp/bin/activate
    pip install --quiet -U -e ./ && pip --quiet freeze > requirements.txt
    run_snyk "${manifest}" "pip" "${prefix}/${manifest}"
    deactivate
  fi
  
  cd "${BASE}" || exit
}

python::main() {
  cmdline "$@"

  ISO8601=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  LOG_FILE="${JSON_TMP}/${ISO8601}-log.txt"

  readonly LOG_FILE

  set_debug
  
  IGNORES=""
  snyk_excludes "${TARGET}" IGNORES
  readonly IGNORES

  local pipfiles
  local poetryfiles
  local reqfiles
  local setupfiles

  readarray -t pipfiles < <(find "${TARGET}" -type f -name "Pipfile" $IGNORES )
  readarray -t poetryfiles < <(find "${TARGET}" -type f -name "pyproject.toml" $IGNORES )
  readarray -t reqfiles < <(find "${TARGET}" -type f -name "requirements.txt" $IGNORES )
  readarray -t setupfiles < <(find "${TARGET}" -type f -name "setup.py" $IGNORES )
  
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

  if [[ "${JSON_STDOUT}" == 1 ]]; then
    stdout_json
  fi

}

python::main "$@"

