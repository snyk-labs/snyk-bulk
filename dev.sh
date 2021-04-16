#!/bin/bash 
set -x
LABEL="python-development-$(git rev-parse HEAD)"
docker image build --file Dockerfile-python -t $LABEL ./
docker run -it -e SNYK_TOKEN -e SNYK_BULK_DEBUG='true' -v $(pwd):/home/dev --entrypoint=/bin/bash mrzarquon/snyk-bulk:python
