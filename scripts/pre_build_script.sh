set -e

if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

if which swiftlint > /dev/null; then
  if "$CI" == true; then

    if which swiftformat > /dev/null; then
        swiftformat taskchamp/Sources
    else
      echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
    fi

    swiftlint taskchamp/Sources --no-cache --strict 
    swiftlint taskchampWidget/Sources --no-cache --strict 
    swiftlint taskchampShared/Sources --no-cache --strict 

  elif [ "$ACTION" = 'build' ]; then
    swiftlint taskchamp/Sources
    swiftlint taskchampWidget/Sources
    swiftlint taskchampShared/Sources
  fi

else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
