# snyk-bulk

Dockerfile entrypoints that replicate `snyk monitor —all-projects` on a per language basis.

Useful for:
* flexible testing of monorepos
* discovery-oriented vulnerability scanning
  * contents are not known ahead of time
  * scanning "out-of-band", that is not directly in the developer build pipeline
