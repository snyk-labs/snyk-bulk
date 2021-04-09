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

## Testrepo Content

testrepo itself is a submodule so we can also test against the same repo in a CI pipeline, after cloning deploy it via
```
git submodule update --init --recursive
```

The repo is currently: https://github.com/mrzarquon/nightmare

