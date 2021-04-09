#!/bin/bash

setDebug(){
    if ! [[ -z "${BULK_DEBUG}" ]]; then
        set -x
    fi
}
export -f setDebug

echoFile() {
    setDebug

    echo "$1"
    echo "$BASE"
    echo "$SOURCEDIR"
}

export -f echoFile

snyk_monitor(){
    setDebug

    PACKAGES="$1"
    PKG_MANAGER="$2"
    PROJECT_NAME="$3"
    snyk monitor --file="$PACKAGES" --remote-repo-url="$CUSTOM_REPO" --project-name="$PROJECT_NAME" --package-manager=$PKG_MANAGER
}

export -f snyk_monitor