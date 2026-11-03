# Fast BBT-Bit iOS IPA builds

Two Codemagic workflows are defined in the root codemagic.yaml.

## Fast path (automatically checked on pull requests)

Select **bbt-bit-ios-fast-ipa** or open a PR against main,
review-only/* or fix/* (with a Codemagic webhook configured).
It builds Kotlin/Native and Rust only when their source/toolchain
fingerprints change, generates the Xcode project and runs:

    ./scripts/package-ios-ipa.sh 1.0.4 --fast --output-dir build/ios/ipa

This uses Xcode's **Debug** configuration and xcodebuild build for a
physical iPhone device, not the optimized Release archive task.
It produces BBT-Bit-VERSION-buildN-ios-debug-unsigned.ipa.

## Release path (manual)

In Codemagic, choose **bbt-bit-ios-ipa** for a full optimized Release
archive and standard BBT-Bit-VERSION-buildN-ios-unsigned.ipa.
The release workflow intentionally has no automatic pull-request
trigger to avoid running two full builds for every small SwiftUI change.

## What is cached

- Gradle and Kotlin/Native downloads (selected ~/.gradle and .konan paths).
- Cargo registry/git dependencies.
- Xcode 26 global compilation cache and Swift Package Manager downloads.
- Content-keyed native outputs, stored in tar.gz files. Archives retain
  macOS framework symlinks that Codemagic directory caching does not.
- Kotlin fingerprint: checked-in shared/Gradle sources and build script,
  Java and Xcode versions.
- Rust fingerprint: checked-in native-core/Cargo sources and build script,
  Rust and Xcode versions.

Changing only an AppleApp SwiftUI view should produce
BBT_NATIVE_CACHE_HIT=kotlin and BBT_NATIVE_CACHE_HIT=rust on a warm
successful workflow cache. Changes to Kotlin/Rust inputs invalidate
their respective cached binaries. The Rust build still compiles a macOS
host slice on a cache miss because the current UniFFI generator needs it.

Codemagic maintains **separate caches for each workflow**, and caches
are created only after successful runs. Cache retention is up to
14 days. Personal account caches are limited to 3 GB per workflow and
team account caches to 10 GB. Inspect cache status/size in Codemagic
after the first successful run; remove low-value cache paths if the
cap is exceeded. Never cache the entire DerivedData directory.

## Measuring savings

Record these lines from a cold and a warm build of the same workflow,
using the same Xcode version:

    BBT_NATIVE_CACHE_MISS=kotlin
    BBT_NATIVE_CACHE_MISS=rust
    BBT_NATIVE_CACHE_HIT=kotlin
    BBT_NATIVE_CACHE_HIT=rust
    BBT_NATIVE_SECONDS_kotlin=N
    BBT_NATIVE_SECONDS_rust=N
    BBT_XCODE_BUILD_SECONDS=N

Also compare Codemagic total workflow duration. A cold successful run
may be no faster while downloading dependencies and warming caches.
A native build that fails in Xcode will not publish a fresh Codemagic
cache, because Codemagic stores caches from successful builds.

## Installing on a physical iPhone

These IPAs are **unsigned**. They are appropriate for compile checks,
packaging checks and later signing, but cannot be installed onto a normal
physical iPhone as-is. Sign with an authorized Apple team and relevant
provisioning profiles, or use a signed/TestFlight pipeline.
The fast IPA is a Debug artifact for development, not distribution.

## Safeguards

- Source/toolchain fingerprint checked before restoring native outputs.
- Archive checksum verified before extraction.
- Failed builds cannot publish a partial tarball.
- The new cache script retains the macOS host slice required for UniFFI.
- Calling package-ios-ipa.sh without --fast remains a full Release archive
  with the original output naming scheme.
- Review changes and pass a macOS/Xcode build before merging anywhere.
  This PR does not target or change main.

References:
- https://docs.codemagic.io/knowledge-codemagic/caching/
- https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/
- https://developer.apple.com/documentation/xcode/build-settings-reference
