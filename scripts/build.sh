#!/bin/bash

# This is a build script to generate local containers to perform tests

for FILENAME in $(find . -type f -name 'Dockerfile-*'); do
  TAG=${FILENAME#*-}
  docker image build --no-cache --file "${FILENAME}" -t snyk-bulk:"${TAG}" ./
done