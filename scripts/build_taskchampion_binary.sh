set -e

if [ -f "../taskchampion-ios/lib.rs.h" ] && [ -f "../taskchampion-ios/libtaskchampion_lib.a" ]; then
    echo "Taskchampion static libraries exist!"
    exit 1
fi

if [ ! -d "../taskwarrior/"]
    echo "Directory not present, cloning taskwarrior..."
    ./clone_taskchampion.sh
fi

cd ..

cd taskwarrior/src/taskchampion-cpp

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
cp target/universal/release/libtaskchampion_lib.a ../../../taskchampion-ios/
cp -L target/aarch64-apple-ios/cxxbridge/taskchampion-lib/src/lib.rs.h ../../../taskchampion-ios/

