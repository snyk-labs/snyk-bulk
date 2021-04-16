# snyk-bulk

`Dockerfile` entrypoints that replicate `snyk monitor —all-projects` on a per language basis.

__Useful for:__
* flexible testing of monorepos
* discovery-oriented vulnerability scanning
  * contents are not known ahead of time
  * scanning "out-of-band", not directly in the developer build pipeline

## Examples - future plans
build your snyk-bulk image for python3 scanning

`docker build -t snyk-bulk:python3 -f Dockerfile-python .`

snyk scan all python3 projects

`docker run -it --rm --env SNYK_TOKEN --env CI=1 -v $(PWD):/project snyk-bulk:python3 --test --target /project --json-std-out`

## Current in progress work:

These entrypoints take commandline arguments that will allow for flexible usage: 
```
--monitor: runs snyk monitor on every project found, can be run with --test, one of them is required

--test: runs snyk test on every project found, can be run with --monitor, one of them is required

--policy-path: !!! UNIMPLEMENTED !!!

--remote-repo-url: sets --remote-repo-url for every invocation of snyk

--help: ironically, not much help

--debug: runs everything with set -x and snyk --debug on

--target: REQUIRED specify the folder you want to be searched for projects

--json-file-output: provide path where json output from the execution will be stored (if none provided, a temporary directory is used)

--json-std-out: assumes env variable of CI = 1 is set, will collect all the json files into an array and return it over standard out, could be flaky, use --json-file-output to put the files in a directory that your CI build system will pickup, 

--severity-threshold: set severity threshold for snyk test

--fail-on: set --fail-on for snyk test
```

An example command for a docker container built with the python file above would look like this:
```
docker run -it -e SNYK_TOKEN -v $(pwd):/home/dev mrzarquon/snyk-bulk:python --test --remote-repo-url "https://bitbucket.org/cmbarker/myproject" --target "/root/testrepo/"
```

Adding `--json-file-output /home/dev/json_output` would have the entrypoint save the json to a folder outside of the container, etc. 


To scan a folder and return everything solely over standard out:
```
docker run -it -e CI=1 -e SNYK_TOKEN -v $(pwd):/home/dev mrzarquon/snyk-bulk:python --test --monitor --target /root/testrepo/piplock --remote-repo-url https://testing.com/project/repo --json-std-out
```
There is a test repository at `/root/testrepo` for an easy purge of cached packages / lockfiles while testing / developing entry points .

## Ecosystem manifest coverage

ecosystem  | manifests           | default base image    | starter Dockerfile |
---------- | ------------------- | --------------------- | ------------------ |
python     | requirements.txt<br/>Pipfile(.lock)<br/>poetry.lock<br/>setup.py | python:slim-buster | Dockerfile-python |

## Testrepo Content

Testrepo itself is setup as a subtree (not a submodule), tl,dr; subtree lets us just copy files & git history from a repo instead of trying to create a permanent link in time to it. It requires more work on the developer who is updating the subtree folder (testrepo) in the repo, but if you're not modifying testrepo, you can ignore it entirely.

Current testrepo source is: `https://github.com/mrzarquon/nightmare`

How to pull in new testrepo content from the upstream repo:
```
tl,dr; version:
git subtree pull -P testrepo git@github.com:mrzarquon/nightmare.git main
```

1) Add a subtree remote to this repo on your workstation
```
git remote add -f testrepo git@github.com:mrzarquon/nightmare.git
```

2) Pull in the latest from upstream:
```
git subtree pull -P testrepo testrepo main
```

