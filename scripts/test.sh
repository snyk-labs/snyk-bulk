#!/bin/bash

# This is a test script to perform a test against a single repo

for FILENAME in $(find . -type f -name 'Dockerfile-*'); do
  TAG=${FILENAME#*-}
  # we can't assume that the testrepo is in every path, so we assume we set workdir in the image to the testrepo we want to use 
  # in a pipeline usually the container is mounted in the root of the repo, so this mimics that setup
  echo "Testing: ${TAG}"
  docker run -it -e SNYK_TOKEN snyk-bulk:"${TAG}" --test --monitor --target . --remote-repo-url https://github.com/snyk-tech-services/snyk-bulk --json-std-out $1
done

