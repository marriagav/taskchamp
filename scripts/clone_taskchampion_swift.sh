set -e

# Get the script's directory
SCRIPT_DIR=$(dirname "$0")

# Change to the directory where the script is located
cd "$SCRIPT_DIR"

cd ..
git clone git@github.com:marriagav/task-champion-swift.git # Using the fork for now before we are able to import with the new structure
