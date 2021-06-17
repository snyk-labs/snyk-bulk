#!/usr/bin/env bash

rm -rf Godeps
rm -rf vendor
rm -f govendor-demo

for lib in github.com/Sirupsen github.com/sirupsen github.com/spf13/cobra; do
  rm -rf $GOPATH/src/$lib
  rm -rf $GOPATH/pkg/darwin_amd64/$lib
done
