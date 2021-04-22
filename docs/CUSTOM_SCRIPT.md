## Custom Script Execution Workflow

Snyk-Bulk will execute a file named prep.sh if located in the same folder as a manifest file:

```
.
├── .snyk.d
│   └── prep.sh <-- snyk-bulk will attempt to run this script first
├── Pipfile
└── Pipfile.lock
```

If the script fails or returns nonzero, then snyk-bulk entrypoints with attempt to scan the folder as normal. All environment variables that are shared to the snyk functions are also available, in the future there will be specific args passed to the script as well. The prep.sh script can call another function or binary already used to test this specific project instead.

Example:
```
#!/bin/bash

json_storage_directory="${JSON_TMP}"

snyk test --json-output-file="${json_storage_directory}/my_custom_script_test_results.json" || return 0

```
