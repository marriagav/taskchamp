#!/bin/sh

set -e

brew install swiftlint
brew install swiftformat
brew install fastlane

brew install mise
mise install
curl https://sh.rustup.rs -sSf | sh -s -- -y

pushd ..
make clone_taskchampion
make build_taskchampion_ci
make install
make generate
popd
