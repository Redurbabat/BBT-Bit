# BBT-Bit

BBT-Bit is an independently maintained native music app for iPhone, iPad,
and Apple Silicon Mac under the BABAT app family.

BBT-Bit is a derivative of the open-source BitChord Apple port by Martin BAGUMA,
itself based on BitChord by Kushagra Singh. It is not an official BitChord release.

## Independent development

- Repository and source: https://github.com/Redurbabat/BBT-Bit
- Display name: BBT-Bit
- iOS/macOS bundle: com.babat.bbtbit
- Widget bundle: com.babat.bbtbit.widget
- Keychain and App Group use separate BBT-Bit namespaces.
- Update checks target BBT-Bit's own GitHub Releases; upstream releases are never installed.
- Automatic macOS updates are disabled pending independent signing keys.
- The app icon is original. Internal BitChord Swift and Kotlin module symbols
  remain to preserve build compatibility.
- Optional verified Automix weight downloads target BBT-Bit's own release assets.
  The weights are not bundled with the app.
- External services such as YouTube Music, and third-party toolchains, still
  require their respective providers.

## Building

Building requires a Mac with Xcode, XcodeGen, JDK, Rust, CMake, and access to
third-party dependencies. Follow the original detailed build steps in
docs/ORIGINAL_BITCHORD_README.md but clone Redurbabat/BBT-Bit instead.
The generated Xcode project and native scheme retain the internal BitChord
name; the installed app displays BBT-Bit.

There is no signed BBT-Bit IPA yet. Configure your own signing identity, then
build and test before releasing. The new app identifier does not migrate data
from an existing BitChord installation.

## Credits and licenses

The software remains GPLv3 where applicable. Copyright and original attribution
are preserved in LICENSE, LICENSES, THIRD_PARTY_NOTICES.md, source headers and
docs/ORIGINAL_BITCHORD_README.md. Keep those notices with redistributed builds.

BBT-Bit is not affiliated with or endorsed by Google or YouTube, and the
availability of third-party music services is outside this project's control.
