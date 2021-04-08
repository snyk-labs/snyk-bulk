#/bin/bash 
LABEL="python-development-$(git rev-parse HEAD)"
docker image build --file Dockerfile-python -t $LABEL ./
docker run -it --volume `pwd`:/home/dev $LABEL
