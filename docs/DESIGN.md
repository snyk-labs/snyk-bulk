# Snyk Bulk Entrypoints Design

## Language specific file / project detection and execution

Snyk-Bulk entrypoints are glorified ways of wrapping a find command for specific package manifests (ie, a node.js' package.json) and then performing a best effort attempt get the environment prepared for snyk to scan that single manifest file. It adds some much needed configuration and extension points to the snyk CLI, overtime this project should reduce in scope as CLI adds these capabilities natively.

The workflow follows these steps:
- Check the provided target directory for an exclude file (`.snyk.d/exclude`) and build paths / filenames into a string
- Check for a similar file but with the name of the entrypoint itself (ie, python.sh will check for a `python.sh-exclude`)
- Perform a find populating an array with the resulting file paths:
    - pipfile's are put in a pipfile specific array, poetry files in a poetry specific array
- Run each file found against a function dedicated to handling that specific file type
    - `setup.py` is handled differently than a `requirements.txt` project, even though both have snyk resolving a requirements.txt file in the end

node.sh yarn.lock example:
```bash
# first we find all the yarn.lock files, there is some bashish trickery we have to employ to ensure this string is expanded but only by the amount we need 
# by default this expands to:
# readarray -t yarnfiles < <(find "${SNYK_TARGET}" -type f -name "yarn.lock" ! -path */node_modules/* ! -path */snyktmp/* ! -path */vendor/* ! -path */submodules/* )
readarray -t yarnfiles < <(find "${SNYK_TARGET}" -type f -name "yarn.lock" $SNYK_IGNORES )

# for every /target_directory/file/path/to/manifest.file in the results for that find command, run: snyk_yarnfile /target_directory/file/path/to/manifest.file
for yarnfile in "${yarnfiles[@]}"; do
  snyk_yarnfile "${yarnfile}"
done

# snyk_yarnfile then does this:
snyk_yarnfile() {
  # this does a set -x which gives us the very verbose output if we need it
  set_debug

  # we are passed one variable - /target_directory/file/path/to/manifest.file
  # this is local becaues we use this variable so many times we always want to be sure it is destroyed at the end of this functions call
  # we get the filename, since we are going to explicitly pass this to snyk down the line in --file
  local manifest
  manifest=$(basename "$1")

  # same as above, but this is the directory containing the file: /target_directory/file/path/to/
  local project_path
  project_path=$(dirname "$1")
  
  # as we want to use the relative path to the file, not the full path, we have to remove the target from that string
  # this makes /target_directory/file/path/to/ into file/path/to/
  local prefix
  prefix=${project_path#"${SNYK_TARGET}"}

  # many package managers use relative directories to derive build settings and paths
  # by simply moving the execution of the next commands to inside that directory instead of trying to call snyk outside of it
  # the package managers behave more predictably
  cd "${project_path}" || exit
  
  # this logic attemps the custom script if it is found in $project/.snyk.d/custom.sh and if that fails, we fall back to our own scanning of the same project
  if use_custom; then
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ( echo "${timestamp}|  Custom Script was run for : $${project_path}" >> "${SNYK_LOG_FILE}" ) 2>&1 | tee -a "${SNYK_LOG_FILE}"
  else
    # if we fail to run the custom script or it doesn't exist, proceed to our run_snyk common function
    # which takes this sequence of args: manifest_file_name package_manager_name (passed to --package-manager in snyk) relative_path_to_file (used --project-name and json output)
    run_snyk "${manifest}" "yarn" "${prefix}/${manifest}"
  fi

  cd "${BASE}" || exit
}
```


## Core Functionality

Snyk-Bulk makes use of two main common helper files, `util.sh` and `cmdline.sh` to keep consistency between the interactions and output of the different entrypoints this project creates.

```
└── entrypoints
    ├── cmdline.sh
    ├── node.sh
    ├── python.sh
    └── util.sh
```

The design is for the entrypoints (`node.sh`, `python.sh`) to handle the language specific nuances, from detection of projects to all the steps required to allow snyk to build a dependency graph. Once the environment is prepared, then Snyk will perform a test / monitor with the intended flags. It performs a test / monitor on a per project basis, instead of --all-projects.

For consistency, use --remote-repo-url as today (2021-04-06) that is the only way to group all the results in the Snyk dashboard in as one repository.

`cmdline.sh` is the interface all entrypoints should use, if a new entrypoint needs an additional flag or feature to be set, ensure it is added here. In theory one could build a single container with a meta-entrypoint that calls all the functions in each language specific one, so all settings should flow through the common command line interface.

## Env Variables

All command line flags are available as environment variables. When adding a new feature or setting, enable it first as an environment variable and add the default values to `cmdline.sh` as the other variables are. This allows for the variables to be set via a CI systems configuration file instead of having to be passed strictly via the command line and subject to bash expansion issues:

```yaml
# .gitlab-ci.yml example
job1:
  variables:
    SNYK_REMOTE_REPO_URL: $CI_PROJECT_URL
    SNYK_FAIL: patchable
    SNYK_SEVERITY: high
```
Any option passed via CLI overrides the Environment variable so they can be used as the baseline, the above example for GitLab CI sets the `SNYK_REMOTE_REPO_URL` to the GitLab CI project url, ensures that `SNYK_FAIL` is set for patchable and `SNYK_SEVERITY` is set for high. This translates to all runs of snyk executed by snyk-bulk entrypoints have these set: `--severity=high --fail-on=patchable --remote-repo-url=$CI_PROJECT_URL`.
