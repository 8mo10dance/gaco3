#!/usr/bin/env bash

set -eu

RUBY_VERSION=${RUBY_VERSION:-}
APP_NAME=${APP_NAME:-myapp}
RAILS_NEW_OPTIONS=${RAILS_NEW_OPTIONS:-}

echo "Ruby Version: ${RUBY_VERSION}"
echo "To run: rails new ${APP_NAME} ${RAILS_NEW_OPTIONS}"

dagger shell <<EOF
container |
  build . --build-args RUBY_VERSION=${RUBY_VERSION} |
  with-exec -- rails new /ruby/${APP_NAME} ${RAILS_NEW_OPTIONS} |
  directory /ruby/${APP_NAME} |
  export ./${APP_NAME}
EOF
