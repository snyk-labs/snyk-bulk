#!/bin/bash
# shellcheck disable=SC2044
TAG=$1

if [ ${#TAG} -gt 0 ] ; then
  echo "Building Container: snyk-bulk:${TAG}"  
  docker image build --quiet --no-cache --file "Dockerfile-${TAG}" -t snyk-bulk:"${TAG}" ./
else
  for FILENAME in $(find . -type f -name 'Dockerfile-*'); do
    TAG=${FILENAME#*-}
    # we can't assume that the testrepo is in every path, so we assume we set workdir in the image to the testrepo we want to use 
    # in a pipeline usually the container is mounted in the root of the repo, so this mimics that setup
    echo "Building Container: snyk-bulk:${TAG}"
    docker image build --quiet --no-cache --file "${FILENAME}" -t snyk-bulk:"${TAG}" ./
  done
fi