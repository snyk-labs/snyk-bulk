#!/usr/bin/env bash

LIBS=("github.com/Sirupsen/logrus" "github.com/spf13/cobra")

for lib in "${LIBS[@]}"; do
  echo "Deleting $lib"
  set -x
  rm -rf $GOPATH/src/$lib
  rm -rf $GOPATH/pkg/darwin_amd64/$lib
  set +x
done

