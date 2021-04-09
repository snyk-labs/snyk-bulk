#!/bin/bash

# source common functions

# source 'snyk-scan/common.sh'

# declare -x CUSTOM_REPO='https://gitlab.com/cmbarker/pythonfiles'
# declare -x JSON_STASH="/tmp/json"

declare -x TARGET=$1

customPrep(){
    /bin/bash .snyk.d/prep.sh
}

scanJavascript()
{ 
    PATH_TO_MANIFEST=$1
    DIR_NAME = $(dirname $PATH_TO_MANIFEST)
    
    # the file to provide as an argument to snyk test/monitor
    # could be different. for example, --file=yarn.lock, even
    # though our initial detection is for package.json.  
    # the prepJavascript function will return the name of the file
    # to provide to the snyk/test monitor command
    #
    # prep enviroment for a successful subsequent snyk scan
    declare -x MANIFEST_NAME=$(prepJavascript "${PATH_TO_MANIFEST}")

    echo "Running Snyk with File: snyk monitor --file=${MANIFEST_NAME}"

    # Run snyk monitor with specified manifest as workaround to avoid other manifest type
    snyk monitor --file="${MANIFEST_NAME}"  --remote-repo-url="${DIR_NAME}"
}

prepJavascript(){
    PATH_TO_MANIFEST=$1
    MANIFEST_NAME=$PATH_TO_MANIFEST
    DIR_NAME = $(dirname $PATH_TO_MANIFEST)
    
    cd $DIR_NAME
    
    if [ -f ".snyk.d/prep.sh" ]
    then
        customPrep
    else
        if [ -d "node_modules" ]; then
            #echo "Found node_modules folder"
            MANIFEST_NAME="package.json"
        elif [ -f "yarn.lock" ]; then
            #echo "Found package.json & yarn.lock"
            out=$(yarn install)
            MANIFEST_NAME="yarn.lock"
        elif [ -f "package-lock.json" ]; then
            #echo "Found package.json & package-lock.json"
            out=$(npm install)
            MANIFEST_NAME="package-lock.json"
        else
            # have to build dependency tree
            out=$(npm install)
            MANIFEST_NAME="package.json"
        fi
    fi
    cd -
    echo "${MANIFEST_NAME}"
}

JS_FILES=($(find $TARGET -type f -name "package.json" ! -path "*/node_modules/*" ! -path "*/vendor/*" ! -path "*/submodules/*"))

if [ -n "${JS_FILES[0]}" ]
then
    for f in "${JS_FILES[@]}"
    do
        echo "$f"
        scanJavascript "${f}"
    done
else
    echo "No package.json files found"
fi
