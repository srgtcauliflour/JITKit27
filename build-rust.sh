#!/bin/bash
set -euo pipefail
export IPHONEOS_DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-26.0}"
source "$HOME/.cargo/env" 2>/dev/null || true
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT/rust-core"
cargo build --release --target aarch64-apple-ios
cargo build --release --target aarch64-apple-ios-sim
cd "$ROOT"
rm -rf JITKit27FFI.xcframework
xcodebuild -create-xcframework \
  -library rust-core/target/aarch64-apple-ios/release/libjitkit27_ffi.a -headers rust-core/include \
  -library rust-core/target/aarch64-apple-ios-sim/release/libjitkit27_ffi.a -headers rust-core/include \
  -output "$ROOT/JITKit27FFI.xcframework"
