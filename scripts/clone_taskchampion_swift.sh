#!/bin/bash
set -e

CI=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --ci) CI=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
cd "$SCRIPT_DIR/.."

if [ "$CI" = true ]; then
    if [ -z "$DEPLOY_KEY" ]; then
        echo "Error: DEPLOY_KEY not set"
        exit 1
    fi

    SSH_DIR="$HOME/.ssh"
    mkdir -p "$SSH_DIR"
    echo "$DEPLOY_KEY" > "$SSH_DIR/id_ed25519"
    chmod 600 "$SSH_DIR/id_ed25519"
    ssh-keyscan github.com > "$SSH_DIR/known_hosts"

    git clone git@github.com:marriagav/task-champion-swift.git
else
    git clone git@github.com:marriagav/task-champion-swift.git
fi

