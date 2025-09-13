#!/usr/bin/env bash

set -eu

dagger shell <<EOF
container |
  build . --build-args RUBY_VERSION=${RUBY_VERSION} |
  with-directory . . |
  terminal
EOF
