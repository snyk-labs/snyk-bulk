# snyk-bulk

`Dockerfile` entrypoints that replicate `snyk monitor —all-projects` on a per language basis.

__Useful for:__
* flexible testing of monorepos
* discovery-oriented vulnerability scanning
  * contents are not known ahead of time
  * scanning "out-of-band", not directly in the developer build pipeline

## Examples
build your snyk-bulk image for python3 scanning

`docker build -t snyk-bulk:python3 -f Dockerfile-python .`

snyk scan all python3 projects

`docker run -it --env SNYK_TOKEN -v $(PWD):/project snyk-bulk:python3`

## Ecosystem manifest coverage

ecosystem  | manifests           | default base image    |
---------- | ------------------- | --------------------- |
javascript | package-(lock).json<br/>yarn.lock | node:lts-buster-slim  |
python     | requirements.txt<br/>Pipfile(.lock)<br/>poetry.lock<br/>setup.py | python:slim-buster |

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
