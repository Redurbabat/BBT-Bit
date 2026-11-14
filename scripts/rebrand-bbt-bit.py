#!/usr/bin/env python3
"""Rebrand the imported code without altering third-party licenses or native module names."""
from pathlib import Path
import json

root = Path(__file__).resolve().parent.parent
src_repo = "Redurbabat/RED-Bit"
dst_repo = "Redurbabat/RED-Bit"

original = (root / "README.md").read_text(encoding="utf-8")
docs = root / "docs"
docs.mkdir(exist_ok=True)
(docs / "ORIGINAL_BITCHORD_README.md").write_text(original, encoding="utf-8")

def edit(rel, pairs):
    p = root / rel
    s = p.read_text(encoding="utf-8")
    for a, b in pairs:
        if a not in s:
            raise RuntimeError("Missing expected marker in " + rel + ": " + a)
        s = s.replace(a, b)
    p.write_text(s, encoding="utf-8")
    print("Updated", rel)

edit("AppleApp/project.yml", [
  ("PRODUCT_BUNDLE_IDENTIFIER: com.babat.bbtbit.widget", "PRODUCT_BUNDLE_IDENTIFIER: com.babat.bbtbit.widget"),
  ("PRODUCT_BUNDLE_IDENTIFIER: com.babat.bbtbit", "PRODUCT_BUNDLE_IDENTIFIER: com.babat.bbtbit"),
  ("CFBundleDisplayName: RedBit Widget", "CFBundleDisplayName: BBT-Bit Widget"),
  ("CFBundleDisplayName: RedBit", "CFBundleDisplayName: BBT-Bit"),
  ("CFBundleURLName: com.babat.bbtbit", "CFBundleURLName: com.babat.bbtbit"),
  ("CFBundleURLSchemes: [redbit]", "CFBundleURLSchemes: [bbtbit]"),
  ("com.babat.bbtbit.playback", "com.babat.bbtbit.playback"),
  ("group.com.babat.bbtbit", "group.com.babat.bbtbit"),
  ("SUFeedURL: https://raw.githubusercontent.com/Redurbabat/RED-Bit/main/appcast.xml", "SUFeedURL: https://raw.githubusercontent.com/Redurbabat/RED-Bit/main/appcast.xml"),
  ("SUEnableAutomaticChecks: true", "SUEnableAutomaticChecks: false"),
  ("RedBit uses ", "BBT-Bit uses "),
  ("RedBit saves ", "BBT-Bit saves "),
])
p = root / "AppleApp/project.yml"
s = p.read_text(encoding="utf-8")
s = "\n".join(x for x in s.split("\n") if "SUPublicEDKey:" not in x)
p.write_text(s, encoding="utf-8")

changed = 0
for p in (root / "AppleApp/Sources").rglob("*.swift"):
    s = p.read_text(encoding="utf-8")
    before = s
    for a, b in [
      ("group.com.babat.bbtbit", "group.com.babat.bbtbit"),
      ("com.babat.bbtbit", "com.babat.bbtbit"),
      ("com.babat.bbtbit.playback", "com.babat.bbtbit.playback"),
      ('"redbit"', '"bbtbit"'),
      ("redbit://", "bbtbit://"),
      ("com.babat.bbtbit", "com.babat.bbtbit"),
      ('Text("RED Bit")', 'Text("BBT-Bit")'),
      ('title: "RED Bit"', 'title: "BBT-Bit"'),
      ("RedBit uses ", "BBT-Bit uses "),
      ("RedBit is hidden", "BBT-Bit is hidden"),
    ]:
        s = s.replace(a, b)
    if p.name == "UpdateChecker.swift":
        s = s.replace(src_repo, dst_repo).replace("RedBit Apple updater", "BBT-Bit Apple updater")
    if p.name == "AutomixModelStore.swift":
        s = s.replace("github.com/" + src_repo + "/releases/download/", "github.com/" + dst_repo + "/releases/download/")
    if p.name == "MacUpdateManager.swift":
        s = s.replace("startingUpdater: true", "startingUpdater: false")
    if s != before:
        p.write_text(s, encoding="utf-8")
        changed += 1
print("Changed Swift files", changed)

edit("shared/src/commonMain/kotlin/com/music/redbit/data/AppUpdateChecker.kt", [
    ("api.github.com/repos/" + src_repo + "/releases/latest", "api.github.com/repos/" + dst_repo + "/releases/latest")
])
edit("scripts/fetch-automix-models.sh", [
    ("github.com/" + src_repo + "/releases/download/", "github.com/" + dst_repo + "/releases/download/")
])

(root / "appcast.xml").write_text("""<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
<channel><title>BBT-Bit Updates</title>
<link>https://github.com/Redurbabat/RED-Bit/releases</link>
<description>No independent Mac release yet.</description></channel></rss>
""", encoding="utf-8")

# Original independent visual identity for both legacy icon and Icon Composer.
svg = root / "AppleApp/AppIcon.icon/Assets/waves.svg"
svg.write_text("""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
<g fill="none" stroke="white" stroke-linecap="round" stroke-linejoin="round">
<path d="M300 325 A250 250 0 0 1 711 319" stroke-width="39"/>
<path d="M676 253 L716 324 L635 327" stroke-width="39"/>
<path d="M724 699 A250 250 0 0 1 313 705" stroke-width="39"/>
<path d="M350 774 L308 699 L393 701" stroke-width="39"/>
<path d="M370 481 V543 M444 438 V584 M516 406 V615 M588 455 V568 M662 481 V543" stroke-width="42"/>
</g></svg>
""", encoding="utf-8")
iconjson = root / "AppleApp/AppIcon.icon/icon.json"
data = json.loads(iconjson.read_text(encoding="utf-8"))
data["fill"]["linear-gradient"] = [
    "srgb:0.43137,0.24706,0.84314,1.00000",
    "srgb:0.10196,0.07059,0.27059,1.00000"]
iconjson.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
from PIL import Image, ImageDraw
N = 1024
im = Image.new("RGB", (N, N))
pix = im.load()
for y in range(N):
    for x in range(N):
        t = (x+y)/(2*N)
        pix[x,y] = (int(110-84*t), int(63-45*t), int(215-146*t))
d = ImageDraw.Draw(im)
white = (255,255,255)
d.arc((195,195,829,829), 207, 312, fill=white, width=36)
d.arc((195,195,829,829), 27, 132, fill=white, width=36)
for x,h in [(370,62),(444,147),(516,212),(588,115),(662,62)]:
    d.line((x,512-h//2,x,512+h//2),fill=white,width=30)
    d.ellipse((x-15,512-h//2-15,x+15,512-h//2+15),fill=white)
    d.ellipse((x-15,512+h//2-15,x+15,512+h//2+15),fill=white)
im.save(root / "AppleApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

(root / "README.md").write_text("""# BBT-Bit

BBT-Bit is an independently maintained native music app for iPhone, iPad,
and Apple Silicon Mac under the BABAT app family.

BBT-Bit is a derivative of the open-source RedBit Apple port by Martin BAGUMA,
itself based on BitChord by Kushagra Singh. It is not an official RedBit release.

## Independent development

- Repository and source: https://github.com/Redurbabat/RED-Bit
- Display name: BBT-Bit
- iOS/macOS bundle: com.babat.bbtbit
- Widget bundle: com.babat.bbtbit.widget
- Keychain and App Group use separate BBT-Bit namespaces.
- Update checks target BBT-Bit's own GitHub Releases; upstream releases are never installed.
- Automatic macOS updates are disabled pending independent signing keys.
- The app icon is original. Internal RedBit Swift and Kotlin module symbols
  remain to preserve build compatibility.
- Optional verified Automix weight downloads target BBT-Bit's own release assets.
  The weights are not bundled with the app.
- External services such as YouTube Music, and third-party toolchains, still
  require their respective providers.

## Building

Building requires a Mac with Xcode, XcodeGen, JDK, Rust, CMake, and access to
third-party dependencies. Follow the original detailed build steps in
docs/ORIGINAL_BITCHORD_README.md but clone Redurbabat/RED-Bit instead.
The generated Xcode project and native scheme retain the internal RedBit
name; the installed app displays BBT-Bit.

There is no signed BBT-Bit IPA yet. Configure your own signing identity, then
build and test before releasing. The new app identifier does not migrate data
from an existing RedBit installation.

## Credits and licenses

The software remains GPLv3 where applicable. Copyright and original attribution
are preserved in LICENSE, LICENSES, THIRD_PARTY_NOTICES.md, source headers and
docs/ORIGINAL_BITCHORD_README.md. Keep those notices with redistributed builds.

BBT-Bit is not affiliated with or endorsed by Google or YouTube, and the
availability of third-party music services is outside this project's control.
""",encoding="utf-8")
print("BBT-Bit migration prepared")
