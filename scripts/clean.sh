#!/bin/bash
# shellcheck disable=SC2044

# This is a build script to generate local containers to perform tests

for FILENAME in $(find . -type f -name 'Dockerfile-*'); do
  TAG=${FILENAME#*-}
  docker rmi -f snyk-bulk:"${TAG}"
done

