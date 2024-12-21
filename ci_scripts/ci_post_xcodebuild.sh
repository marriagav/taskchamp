#!/bin/sh

set -e

if [ "$CI_WORKFLOW" = "Alpha" ] || [ "$CI_WORKFLOW" = "Beta" ]; then
  pushd ..
    mkdir TestFlight
    pushd TestFlight
      for locale in en-GB en-US es-MX es-ES; do
        cat ../WhatToTest.txt > WhatToTest.$locale.txt
      done
    popd
  popd
fi

if [ "$CI_WORKFLOW" = "Production" ]; then
  pushd ..
    fastlane upload_to_appstore ipa:$CI_APP_STORE_SIGNED_APP_PATH/$CI_PRODUCT.ipa bundle_id:$CI_BUNDLE_ID scheme:$CI_XCODE_SCHEME
  popd
fi
