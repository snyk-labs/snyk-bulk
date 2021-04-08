#!/bin/bash

# source common functions

#source 'snyk-scan/common.sh'

declare -x CUSTOM_REPO='https://gitlab.com/cmbarker/pythonfiles'
declare -x JSON_STASH="/tmp/json"

declare -x TARGET=$1

customPrep(){
    /bin/bash .snyk.d/prep.sh
}

pipenvPrep(){
    filename = $(basename $1)
    dirname = $(dirname $1)
    cd $dirname
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
    snyk monitor --file=Pipfile.lock --remote-repo-url=$CUSTOM_REPO --json-file=$JSON_STASH
}

# poetryPrep(){

# }

# setupPrep(){

# }

# reqPrep(){

# }

# monitor(){

# }

PY_PIPFILES=($(find $TARGET -type f -name "Pipfile" ! -path "*/node_modules/*" ! -path "*/vendor/*" ! -path "*/submodules/*"))
PY_POETRYFILES=($(find . -type f \( -name "poetry.lock" -o -name "pyproject.toml" \) ! -path "*/node_modules/*" ! -path "*/vendor/*" ! -path "*/submodules/*"))
PY_SETUPFILES=($(find . -type f -name "setup.py" ! -path "*/node_modules/*" ! -path "*/vendor/*" ! -path "*/submodules/*"))
PY_REQFILES=($(find . -type f -name "requirements.txt" ! -path "*/node_modules/*" ! -path "*/vendor/*" ! -path "*/submodules/*"))

if [ -n "${PY_PIPFILES[0]}" ]
then
    for f in "${PY_PIPFILES[@]}"
    do
        echo "$f"
    done
else
    echo "No Pipfiles found"
fi
