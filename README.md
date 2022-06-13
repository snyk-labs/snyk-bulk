# snyk-bulk
Recursively scan source repositories for open source vulnerabilities with the Snyk CLI, outside of a build environment.

## Background
The Snyk CLI is designed to be used from within a development or build environment, where all dependencies used and their versions in a given project can be accurately resolved and tested against. See [here](https://docs.snyk.io/features/snyk-cli/guides-for-our-cli/getting-started-with-the-cli#build-your-project) for more information.

This project aims to provide and prep the build environment when only the source is available, to allow the Snyk CLI to successfully scan for issues.

## How it works
This project provides ENTRYPOINT scripts that replicate `snyk monitor —all-projects` and `snyk test —all-projects` on a per language/package-manager basis, providing additional functionality of running the prerequisite build steps required by the Snyk CLI to complete a successful scan.  See [Ecosystem manifest coverage](#ecosystem-manifest-coverage) for details

The provided Dockerfiles are examples that may work in your environment as-is, or may need to be modified to meet your needs by using a different base image or adding additional configuration steps required in your environment.  Because of the broad variations of customer languages, package managers, and build environments, the examples attempt to cover common combinations as a starting point.  The intent is not to publish built images, but rather that you take the ENTRYPOINT scripts and build your own images, using either the provided Dockerfiles, or ones you have tailored to suit your needs.

The key value of this project is in the ENTRYPOINT scripts which abstract some complexities of the Snyk CLI by preparing the source to be scanned by Snyk.

## Useful for
* discovery-oriented vulnerability scanning
  * repo contents are not known ahead of time
  * scanning "out-of-band", not directly in the developer build pipeline
* monorepo scanning use cases

## Build examples
build your snyk-bulk image for python3 scanning

```
docker build -t snyk-bulk:python3 -f Dockerfile-python .
```

snyk scan all python3 projects

```
docker run -it --rm --env SNYK_TOKEN --env CI=1 \ -v $(PWD):/project \
  snyk-bulk:python3 \
  --test --target /project --json-std-out
```

## Entrypoint options

These entrypoints take command-line arguments that will allow for flexible usage
```
--monitor
  runs snyk monitor on every project found, can be run with --test, one of them is required

--test 
  runs snyk test on every project found, can be run with --monitor, one of them is required

--policy-path: 
  !!! UNIMPLEMENTED !!!

--remote-repo-url
  sets --remote-repo-url for every invocation of snyk

--help
  ironically, not much help

--debug
  runs everything with set -x and snyk --debug on

--target
  REQUIRED specify the folder you want to be searched for projects

--json-file-output
  provide path where json output from the execution will be stored (if none provided, a temporary directory is used)

--json-std-out
  assumes env variable of CI = 1 is set, will collect all the json files into an array and return it over standard out, could be flaky, use --json-file-output to put the files in a directory that your CI build system will pickup, 

--severity-threshold
  set severity threshold for snyk test

--fail-on
  set --fail-on for snyk test
```

## Examples

An example command for a docker container built with the python file above would look like this

```
docker run -it -e SNYK_TOKEN -v $(pwd):/home/dev snyk-bulk:python --test --remote-repo-url "https://bitbucket.org/cmbarker/myproject" --target "/root/testrepo/"
```

Adding `--json-file-output /home/dev/json_output` would have the entrypoint save the json to a folder outside of the container, etc. 


To scan every python project in a repository (assuming it is on the local filesystem) and return the test results over standard out:
```
docker run -e SNYK_TOKEN snyk-bulk:python \
  --test --target /root/testrepo \
  --remote-repo-url https://github.com/snyk-tech-services/snyk-bulk --json-std-out
```
There is a test repository at `/root/testrepo` for an easy purge of cached packages / lockfiles while testing / developing entry points .

An example command for a docker container built with the maven file above might look like this:
```
docker run -it --rm --env SNYK_TOKEN \
  --env CI=1 --env SNYK_CFG_ORG=ie-playground \
  -v $(PWD):/project -v $HOME/.m2:/root/.m2 snyk-bulk:maven \
  --monitor --target /project --json-std-out \
  --remote-repo-url https://github.com/snyk-tech-services/snyk-bulk
```

## Ecosystem manifest coverage
These are examples, use the base image thats right for you.

ecosystem  | manifests           | example parent image    | example Dockerfile |
---------- | ------------------- | --------------------- | ------------------ |
python     | requirements.txt<br/>Pipfile(.lock)<br/>poetry.lock<br/>setup.py | python:slim-buster | Dockerfile-python |
javascript | yarn.lock(including workspaces)<br/>package(-lock).json | node:lts-buster-slim | Dockerfile-node |
java [maven] | pom.xml | maven:maven:3.8.1-adoptopenjdk-15-openj9| Dockerfile-maven |
java [gradle] | build.gradle<br>build.gradle.kts | gradle:5.6.4-jdk11| Dockerfile-gradle |
ruby | Gemfile(.lock) | ruby:slim-buster| Dockerfile-ruby |
.NET | project.json<br/>packages.config<br/>project.assets.json<br/>paket.dependencies | bitnami/dotnet:latest| Dockerfile-dotnet |


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

## Custom Scripts

`snyk-bulk` will defer to a custom script (`.snyk.d/prep.sh`) it finds alongside a package manifest to execute instead of running snyk itself. Note: you lose the collected json output and other features. Currently if the custom script returns nonzero, `snyk-bulk` entrypoints will attempt to scan the folder regardless. If you have a folder you want to be ignored, make the contents of prep.sh:
```
#!/bin/bash

return 0
```

### Future plans for prep.sh:
- example [prep.sh](docs/CUSTOM_SCRIPT.md)
- standard args that snyk-bulk will pass to prep.sh (snyk token, log dir to allow unified output, etc)

### Adding New Langauges
- See the [design](docs/DESIGN.md) guide as the starting point for how snyk-bulk's language specific entrypoints should be designed