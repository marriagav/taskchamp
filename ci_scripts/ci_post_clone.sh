#!/bin/sh

set -e

brew install swiftlint
brew install swiftformat
brew install fastlane

brew install mise
mise install

pushd ..
make install
make generate
popd
