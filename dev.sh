#/bin/bash 
set -x
LABEL="python-development-$(git rev-parse HEAD)"
docker image build --file Dockerfile-python -t $LABEL ./
docker run -it -e SNYK_TOKEN -e BULK_DEBUG='true' --volume $(pwd):/home/dev --entrypoint /bin/bash $LABEL
