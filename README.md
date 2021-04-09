# snyk-bulk

`Dockerfile` entrypoints that replicate `snyk monitor —all-projects` on a per language basis.

__Useful for:__
* flexible testing of monorepos
* discovery-oriented vulnerability scanning
  * contents are not known ahead of time
  * scanning "out-of-band", that is not directly in the developer build pipeline


testrepo itself is a submodule so we can also test against the same repo in a CI pipeline, after cloning deploy it via
```
git submodule update --init --recursive
```

The repo is currently: https://github.com/mrzarquon/nightmare