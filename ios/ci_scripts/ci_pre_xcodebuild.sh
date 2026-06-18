#!/bin/sh

# Runs immediately before xcodebuild archive. Ensures Flutter iOS config and
# CocoaPods are in sync so native plugins (e.g. background_fetch) are available.
set -e

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

cd "$CI_PRIMARY_REPOSITORY_PATH"

export PATH="$PATH:$HOME/flutter/bin"

flutter pub get
flutter build ios --config-only --release

cd ios && pod install

exit 0
