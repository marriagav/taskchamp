set -e

# Get the script's directory
SCRIPT_DIR=$(dirname "$0")

# Change to the directory where the script is located
cd "$SCRIPT_DIR"

# Check if both files exist
if [ -f "../taskchampion-ios/lib.rs.h" ] && [ -f "../taskchampion-ios/libtaskchampion_lib.a" ]; then
    echo "Taskchampion static libraries exist!"
    exit 0
fi

# Check if directory exists
if [ ! -d "../taskwarrior/" ]; then
    echo "Directory not present, cloning taskwarrior..."
    ./clone_taskchampion.sh
fi

cd ../taskwarrior/src/taskchampion-cpp

# Check if Cargo is installed
if ! command -v cargo &> /dev/null
then
    echo "Cargo not found, installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
else
    echo "Cargo is already installed."
fi

rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim

cargo install cargo-lipo

cargo lipo --release

# Copy the files
cp target/universal/release/libtaskchampion_lib.a ../../../taskchampion-ios/
cp -L target/aarch64-apple-ios/cxxbridge/taskchampion-lib/src/lib.rs.h ../../../taskchampion-ios/
