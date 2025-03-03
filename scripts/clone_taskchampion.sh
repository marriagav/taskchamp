set -e

# Get the script's directory
SCRIPT_DIR=$(dirname "$0")

# Change to the directory where the script is located
cd "$SCRIPT_DIR"

cd ..
git clone --no-checkout --depth=1 --filter=blob:none https://github.com/GothenburgBitFactory/taskwarrior
cd taskwarrior
git config core.sparseCheckout true
echo "src/taskchampion-cpp" >> .git/info/sparse-checkout

git checkout

