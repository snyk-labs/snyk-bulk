#!/bin/bash
set -euo pipefail

declare -x TMP_DIR

TMP_DIR=$(mktemp -d) || exit 1

cd "${TMP_DIR}" || exit 1

# declare -x SNYK_VERSION

# SNYK_VERSION=$(curl -s https://static.snyk.io/cli/latest/version)

curl -O -s -L "https://static.snyk.io/cli/latest/snyk-linux"
curl -O -s -L "https://static.snyk.io/cli/latest/snyk-linux.sha256"

if sha256sum -c snyk-linux.sha256; then
  mv snyk-linux /usr/local/bin/snyk
  chmod +x /usr/local/bin/snyk
else
  echo "Snyk Binary Download failed, exiting"
  exit 1
fi