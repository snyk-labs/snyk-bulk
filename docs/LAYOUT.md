## Snyk Bulk Entrypoints Layout

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