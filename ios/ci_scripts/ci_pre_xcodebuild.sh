#!/bin/sh

# Runs immediately before xcodebuild archive. Re-syncs pods after clone setup.
set -e

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

cd "$CI_PRIMARY_REPOSITORY_PATH"

export PATH="$PATH:$HOME/flutter/bin"

flutter pub get

cd ios && pod install

exit 0
