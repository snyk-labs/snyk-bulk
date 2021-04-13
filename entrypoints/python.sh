#!/bin/bash

declare -rgx SOURCEDIR=$(dirname "$0")
source "$SOURCEDIR/util.sh"

#declare -rgx CUSTOM_REPO='https://gitlab.com/cmbarker/pythonfiles'

# declare -rgx JSON_TMP="$(mktemp -d)"

#declare -rgx TARGET="$1"

declare -rgx BASE="$(pwd)"


use_custom(){
  /bin/bash .snyk.d/prep.sh
}

install_pipenv(){
  set_debug
  if ! command -v pipenv > /dev/null 2>&1 ; then
    pip -install pipenv
  fi
}

install_poetry(){
  set_debug
  if ! command -v poetry > /dev/null 2>&1 ; then
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
  fi
}

snyk_pipfile(){
  set_debug

  local manifest=$(basename "$1")
  local project_path=$(dirname "$1")
  
  local prefix=${project_path#"${TARGET}"}

  install_pipenv

  cd   "${project_path}"
  if [ -f ".snyk.d/prep.sh" ]; then
    customPrep
  else
    declare -x PIPENV_NOSPIN="true"
    declare -x PIPENV_COLORBLIND="true"
    declare -x PIPENV_BARE="true"
    declare -x PIP_QUIET="true"    

    if [ -f "Pipfile.lock" ]; then
      pipenv sync
    else
      pipenv update
    fi
  fi

  snyk_cmd "test" "${manifest}" "pip" "${prefix}/${manifest}"
  # snyk_cmd "monitor" "${manifest}" "pip" "${prefix}/${manifest}"

  unset PIPENV_NOSPIN PIPENV_COLORBLIND PIP_QUIET

  cd "${BASE}"
}

snyk_poetry(){
  set_debug

  local manifest=$(basename "$1")
  local project_path=$(dirname "$1")
  
  local prefix=${project_path#"${TARGET}"}

  install_poetry

  cd "${project_path}"
  if [ -f ".snyk.d/prep.sh" ]; then
    customPrep
  else
    if ! [ -f "poetry.lock" ]; then
      poetry lock --no-update --quiet --no-interaction
    fi
  fi
  snyk_cmd "test" "${manifest}" "pip" "${prefix}/${manifest}"
  # snyk_cmd "monitor" "${manifest}" "pip" "${prefix}/${manifest}"

  cd "${BASE}"
}

snyk_reqfile(){
  set_debug

  local manifest=$(basename "$1")
  local project_path=$(dirname "$1")
  
  local prefix=${project_path#"${TARGET}"}

  cd "${project_path}"
  if [ -f ".snyk.d/prep.sh" ]; then
    customPrep
  else
    if ! [[ -d 'snyktmp' ]]; then
      virtualenv snyktmp
    fi
    source snyktmp/bin/activate
    pip install --quiet -r requirements.txt
    snyk_cmd "test" "${manifest}" "pip" "${prefix}/${manifest}"
    # snyk_cmd "monitor" "${manifest}" "pip" "${prefix}/${manifest}"
    deactivate
  fi
  
  cd "${BASE}"
}

snyk_setupfile(){
  set_debug

  local manifest=$(basename "$1")
  local project_path=$(dirname "$1")
  
  local prefix=${project_path#"${TARGET}"}

  cd "${project_path}"
  if [ -f ".snyk.d/prep.sh" ]; then
    customPrep
  elif ! [[ -f "requirements.txt" ]]; then
    if ! [[ -d 'snyktmp' ]]; then
      virtualenv snyktmp
    fi
    source snyktmp/bin/activate
    pip install --quiet -U -e ./ && pip --quiet freeze > requirements.txt
    snyk_cmd "test" "${manifest}" "pip" "${prefix}/${manifest}"
    # snyk_cmd "monitor" "${manifest}" "pip" "${prefix}/${manifest}"
    deactivate
  fi
  
  cd "${BASE}"
}

python::main() {

  declare -gx POLICY_FILE_PATH REMOTE_REPO_URL SNYK_MONITOR SNYK_TEST SNYK_BULK_VERBOSE TARGET SNYK_BULK_DEBUG

  cmdline "$@"

  JSON_TMP="${JSON_DIR:=$(mktemp -d)}"

  declare -rgx POLICY_FILE_PATH REMOTE_REPO_URL SNYK_MONITOR SNYK_TEST SNYK_BULK_VERBOSE TARGET SNYK_BULK_DEBUG JSON_TMP

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

}

python::main "$@"

