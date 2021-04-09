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
