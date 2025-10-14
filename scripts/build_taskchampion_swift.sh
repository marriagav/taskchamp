#!/bin/sh
set -e  # Exit immediately if a command exits with a non-zero status

# Default value for the skip-sim flag
SKIP_SIM=false
export IPHONEOS_DEPLOYMENT_TARGET=17.0

# Parse flags manually
for arg in "$@"; do
    case $arg in
        --skip-sim)
            SKIP_SIM=true
            shift # Remove --skip-sim from the argument list
            ;;
        *)
            # Other flags or arguments can go here
            ;;
    esac
done

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define paths
TASKCHAMPION_SWIFT_DIR="$SCRIPT_DIR/../task-champion-swift/taskchampion-swift"
FRAMEWORK_DIR="$TASKCHAMPION_SWIFT_DIR/taskchampion-swift/RustXcframework.xcframework"
BASE_SOURCES_DIR="$TASKCHAMPION_SWIFT_DIR/taskchampion-swift/Sources/Taskchampion"

# List of expected binaries
BINARIES=(
  "$FRAMEWORK_DIR/ios-arm64/libtaskchampion_swift.a"
  "$FRAMEWORK_DIR/ios-arm64_x86_64-simulator/libtaskchampion_swift.a"
  "$FRAMEWORK_DIR/macos-arm64_x86_64/libtaskchampion_swift.a"
)

# Check if all required binaries exist
all_binaries_exist=true
for BIN in "${BINARIES[@]}"; do
  if [ ! -f "$BIN" ]; then
    if [ "$SKIP_SIM" = true ] && [[ "$BIN" == *"-simulator"* ]]; then
      continue
    fi
    all_binaries_exist=false
    break
  fi
done

# if [ "$all_binaries_exist" = true ]; then
#     echo "All Taskchampion Swift libraries exist! Skipping build."
#     exit 0
# fi

# Clone or update the repository
clone_or_update_repo() {
    if [ ! -d "$SCRIPT_DIR/../task-champion-swift" ]; then
        echo "Directory not present, cloning task-champion-swift..."
        "$SCRIPT_DIR/clone_taskchampion_swift.sh"
    else
        echo "Directory already present, pulling latest changes..."
        (cd "$TASKCHAMPION_SWIFT_DIR" && git pull)
    fi
}

# Ensure Cargo is installed
check_cargo() {
    if ! command -v cargo &> /dev/null; then
        echo "Cargo not found, installing Rust..."
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        export PATH="$HOME/.cargo/bin:$PATH"
    else
        echo "Cargo is already installed."
    fi
}

# Ensure required Rust targets are installed
install_rust_targets_for_sim() {
    echo "Adding Rust targets for simulator..."
    rustup target add aarch64-apple-ios-sim 
}

install_rust_targets() {
    echo "Adding Rust targets..."
    rustup target add aarch64-apple-ios
}

# Ensure cargo-lipo is installed
install_cargo_lipo() {
    if ! cargo install --list | grep -q "cargo-lipo"; then
        echo "Installing cargo-lipo..."
        cargo install cargo-lipo
    else
        echo "cargo-lipo is already installed."
    fi
}


# Build Taskchampion Swift
build_taskchampion_swift_for_sim() {
    echo "Building taskchampion-swift for simulator..."
    (cd "$TASKCHAMPION_SWIFT_DIR/taskchampion-swift" && cargo build --target aarch64-apple-ios-sim)
}

# Build Taskchampion Swift
build_taskchampion_swift() {
    echo "Building taskchampion-swift..."
    (cd "$TASKCHAMPION_SWIFT_DIR/taskchampion-swift" && cargo build --release --target aarch64-apple-ios)
}

add_import_if_needed() {
  local file="$1"
  
  # Ensure the file exists before modifying it
  if [[ -f "$file" ]]; then
    if ! grep -Fxq "import RustXcframework" "$file"; then
      echo "import RustXcframework\n$(cat "$file")" > "$file"
    fi
  else
    echo "File not found: $file"
  fi
}

SRC_BIN="$TASKCHAMPION_SWIFT_DIR/target/aarch64-apple-ios/release/libtaskchampion_swift.a"
SRC_BIN_FOR_SIM="$TASKCHAMPION_SWIFT_DIR/target/aarch64-apple-ios-sim/debug/libtaskchampion_swift.a"
HEADER="$TASKCHAMPION_SWIFT_DIR/generated/SwiftBridgeCore.h"
SECOND_HEADER="$TASKCHAMPION_SWIFT_DIR/generated/taskchampion-swift/taskchampion-swift.h"
SRC_FILE="$TASKCHAMPION_SWIFT_DIR/generated/SwiftBridgeCore.swift"
SRC_FILE2="$TASKCHAMPION_SWIFT_DIR/generated/taskchampion-swift/taskchampion-swift.swift"

# Copy generated binaries and headers
copy_generated_files() {
    echo "Copying taskchampion-swift generated files..."

    TARGET_DIRS=(
      "ios-arm64"
      "macos-arm64_x86_64"
    )

    for DIR in "${TARGET_DIRS[@]}"; do
        \cp "$SRC_BIN" "$FRAMEWORK_DIR/$DIR/"
        \cp "$HEADER" "$FRAMEWORK_DIR/$DIR/Headers/"
        \cp "$SECOND_HEADER" "$FRAMEWORK_DIR/$DIR/Headers/"
    done

    # Copy Swift source files
    \cp "$SRC_FILE" "$BASE_SOURCES_DIR/"
    \cp "$SRC_FILE2" "$BASE_SOURCES_DIR/"

    # Modify the copied files
    add_import_if_needed "$BASE_SOURCES_DIR/$(basename "$SRC_FILE")"
    add_import_if_needed "$BASE_SOURCES_DIR/$(basename "$SRC_FILE2")"

    echo "Taskchampion Swift libraries generated! 🎉"
}

copy_generated_files_for_sim() {
    echo "Copying taskchampion-swift generated files for simulator..."

    TARGET_DIRS=(
      "ios-arm64_x86_64-simulator"
    )

    for DIR in "${TARGET_DIRS[@]}"; do
        \cp "$SRC_BIN_FOR_SIM" "$FRAMEWORK_DIR/$DIR/"
        \cp "$HEADER" "$FRAMEWORK_DIR/$DIR/Headers/"
        \cp "$SECOND_HEADER" "$FRAMEWORK_DIR/$DIR/Headers/"
    done

    echo "Taskchampion Swift libraries generated for simulator! 🎉"
}

### **Execution Order**
clone_or_update_repo
check_cargo
if [ "$SKIP_SIM" = false ]; then
    install_rust_targets_for_sim
    build_taskchampion_swift_for_sim
    copy_generated_files_for_sim
fi
install_rust_targets
# install_cargo_lipo # Not currently used
build_taskchampion_swift
copy_generated_files
