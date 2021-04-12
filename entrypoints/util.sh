#!/bin/bash

setDebug(){
    if ! [[ -z "${BULK_DEBUG}" ]]; then
        set -x
    fi
}
export -f setDebug

echoFile() {
    #setDebug

    echo "$1"
    #echo "$BASE"
    #echo "$SOURCEDIR"
}

export -f echoFile

snyk_monitor(){
    setDebug
    if ! [[ -z "${BULK_DEBUG}" ]]; then
        SNYK_DEBUG="--debug"
    else
        SNYK_DEBUG=""
    fi

    PACKAGES="$1"
    PKG_MANAGER="$2"
    PROJECT_NAME="$3"
    snyk monitor --file="$PACKAGES" --remote-repo-url="$CUSTOM_REPO" --project-name="$PROJECT_NAME" --package-manager=$PKG_MANAGER $SNYK_DEBUG
}

export -f snyk_monitor

snyk_excludes(){
    TARGET_DIR="${1}"
    local -n EXCLUDES=$2
    if [ -f "${TARGET_DIR}/.snyk.d/exclude" ]
    then
        declare -a EXCLUDE_SRC
        readarray -t EXCLUDE_SRC < "${TARGET_DIR}/.snyk.d/exclude"
        EXCLUDES='! -path */node_modules/* ! -path */snyktmp/*'
        for FPATH in "${EXCLUDE_SRC[@]}"
        do
            # very pedantic that we don't want to accidentally render this glob
            EXCLUDES+=' ! -path */'
            EXCLUDES+="${FPATH}"
            EXCLUDES+='/*'
        done
    else
        EXCLUDES='! -path */snyktmp/* ! -path */node_modules/* ! -path */vendor/* ! -path */submodules/*'
    fi
    echo $C
}

export -f snyk_excludes