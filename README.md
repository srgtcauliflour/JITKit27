# JITKit27

On-device pairing toolkit for iOS 27 and iPadOS 27.

## v0.1
Generate an RPPairing record on-device, validate it by opening an RSD tunnel back to the physical device, build the compatible pairing payload, and export a `.mobiledevicepairing` file.

## v0.2
Use the validated pairing identity and RSD transport to provide on-device JIT enablement.

### Compatibility
- iOS 27.0+
- iPadOS 27.0+

Both platforms use the same minimum deployment target and Remote Pairing capability path.

### Build
Requires Xcode 27, Rust targets `aarch64-apple-ios` + `aarch64-apple-ios-sim`, and XcodeGen.

```sh
./build-rust.sh
xcodegen generate
```

No Apple Developer team is hard-coded. Sign with your own account.
