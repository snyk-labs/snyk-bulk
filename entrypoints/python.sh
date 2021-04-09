#!/bin/bash

declare -x SOURCEDIR=$(dirname "$0")
source "$SOURCEDIR/util.sh"

setDebug

# source common functions

#source 'snyk-scan/common.sh'

declare -x CUSTOM_REPO='https://gitlab.com/cmbarker/pythonfiles'
declare -x JSON_STASH="/tmp/json"
declare -x TARGET="$1"
declare -x BASE="$(pwd)"


customPrep(){
    /bin/bash .snyk.d/prep.sh
}

PipfilePrep(){
    setDebug

    FILENAME=$(basename "$1")
    DIRECTORY=$(dirname "$1")
    PROJECT_PREFIX=${DIRECTORY#"$TARGET"}

    cd "$DIRECTORY"
    if [ -f ".snyk.d/prep.sh" ]
    then
        customPrep
    else
        if [ -f "Pipfile.lock" ]
        then
            pipenv sync
        else
            pipenv update
        fi
    fi
    snyk_monitor "$FILENAME" "pip" "$PROJECT_PREFIX/$FILENAME"
    cd "$BASE"
}

# exporting this function lets us call it in a find command, instead of trying to parse an array
export -f PipfilePrep

# poetryPrep(){

# }

# setupPrep(){

# }

# reqPrep(){

# }

# PY_PIPFILES=($(find $TARGET -type f -name "Pipfile" ! -path "*/node_modules/*" ! -path "*/vendor/*" ! -path "*/submodules/*"))
# PY_POETRYFILES=($(find . -type f \( -name "poetry.lock" -o -name "pyproject.toml" \) ! -path "*/node_modules/*" ! -path "*/vendor/*" ! -path "*/submodules/*"))
# PY_SETUPFILES=($(find . -type f -name "setup.py" ! -path "*/node_modules/*" ! -path "*/vendor/*" ! -path "*/submodules/*"))
# PY_REQFILES=($(find . -type f -name "requirements.txt" ! -path "*/node_modules/*" ! -path "*/vendor/*" ! -path "*/submodules/*"))


findPipfile(){
    pip install pipenv
    find "$TARGET" -type f -name "Pipfile" ! -path "*/node_modules/*" ! -path "*/vendor/*" ! -path "*/submodules/*" -exec bash -c 'PipfilePrep "$0"' {} \;
}

findPipfile
