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

pipenvInstall(){
    setDebug
    if ! command -v pipenv 2&>1 /dev/null
    then
        pip -install pipenv
    fi
}
export -f pipenvInstall

poetryInstall(){
    setDebug
    if ! command -v poetry 2&>1 /dev/null
    then
        curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
    fi
}
export -f poetryInstall

PipfilePrep(){
    set +o noglob
    setDebug
    pipenvInstall

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

poetryPrep(){
    set +o noglob
    setDebug
    pipenvInstall

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

# setupPrep(){

# }

# reqPrep(){

# }


findPipfile(){
    # we don't want bash expansion of * to happen in our find string, we reset noglob at the start of our functions
    set -o noglob
    find "${TARGET}" -type f -name "Pipfile" $IGNORES -exec bash -c 'echoFile "$0"' {} \;
    set +o noglob
}

findPoetry(){
    # we don't want bash expansion of * to happen in our find string, we reset noglob at the start of our functions
    set -o noglob
    find "${TARGET}" -type f -name "pyproject.toml" $IGNORES -exec bash -c 'echoFile "$0"' {} \;
    set +o noglob
}

# we check for .snyk.d/exclude folder in the root of the target
# this is the ignore for all find requests and precludes the need for --exclude in snyk itself
IGNORES=""
snyk_excludes "${TARGET}" IGNORES

findPipfile
findPoetry