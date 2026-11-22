# MihirakiPDFUtility

See the [publication and X announcement record (Japanese)](docs/PUBLICATION_STATUS_20261123.ja.md) for the November 23, 2026 checks. Existing pending work remains pending.

English | [日本語](README_ja.md)

MihirakiPDFUtility is an app for Apple platforms that organizes PDF pages locally, including reordering, rotating, inserting and removing pages.

This repository was created to develop a new app based on code and specifications from Folimeld, originally created by Takuma Yamada.

## Current status

- SwiftUI project for iOS and iPadOS with a Swift Testing target (191 automated unit tests)
- Open and export PDFs with undo/redo support
- Add pages from another PDF or import images directly as PDF pages
- Split double-page spread pages vertically (left/right) or horizontally (top/bottom)
- Crop margins evenly around selected pages (0–40% clamp with boundary protection)
- Full-screen interactive preview with 1–5x pinch zoom, double-tap toggle, pan, swipe navigation, and Right-to-Left (RTL) reading order
- Reorder, duplicate, rotate (in 90° increments) and remove selected pages
- Invert selection to quickly switch between selected and unselected pages
- Customizable thumbnail sizes (Small, Medium, Large) and button display styles (Icon + Text, Icon Only, Text Only)
- Insert blank pages before or after a selection
- Export selected pages as a separate PDF
- Open password-protected PDFs
- Edit document title, author, subject and keywords
- Configure PDF page layout, cover display and reading direction
- Set or remove a viewing password on exported PDFs
- Open PDFs from Files and the system share sheet
- Run an on-device CPU, memory and PDF workflow performance test from Settings > Diagnostics > Run Performance Test
- View or copy on-device diagnostic logs from Settings > Diagnostics > View Diagnostic Logs; logs exclude personal information and PDF contents and expire after 14 days (pruned on startup/read/write)
- Review diagnostic test reports before manually sharing them; reports are not sent automatically. The separate performance test report can include the device name, so check its contents before sharing
- User interface localized in 14 languages (Japanese, English, Korean, Simplified Chinese, Traditional Chinese, German, French, Spanish, Portuguese, Italian, Vietnamese, Filipino, Nepali, Indonesian)
- Sample manga catalog v2 (51 volumes across 17 locales) and official YouTube Shorts video guides
- Optional non-consumable In-App Purchases for permanent Bronze, Silver, and Gold supporter icons
- Marketing, privacy and support pages for GitHub Pages

## Website

- [Marketing page](https://tyamada.github.io/MihirakiPDFUtility/)
- [Privacy Policy](https://tyamada.github.io/MihirakiPDFUtility/privacy.html)
- [Support](https://tyamada.github.io/MihirakiPDFUtility/support.html)

## Sample PDFs

[Sample manga PDFs](https://tyamada.github.io/manga-prompt-kit/samples/en/) — Choose a language and episode on the sample PDF download page. Episodes 1–3 are available across 17 locales (51 PDFs).

By **Komairo Hiyori**, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). See the [license and attribution details](docs/sample-pdf-license.html#en). The download page is the maintained source for the PDF list.

## Development

This app is in development. Uncommitted diagnostic features and other local work may differ from public main. Implementation status and verified behavior are tracked separately.

- Use macOS, Xcode, and an iOS 18.0+ simulator runtime. This review uses Xcode 27.1.
- Complete Xcode's first-launch setup and additional component installation. Check that `xcode-select -p` points to the Xcode Developer directory.
- No external Swift packages or CocoaPods are required. Offline repository checks use Python 3.
- The project also has a macOS 15.0 configuration; Mac UI readiness and verification are tracked separately from iOS/iPadOS.

```bash
git clone https://github.com/tyamada/MihirakiPDFUtility.git
cd MihirakiPDFUtility
xcodebuild -list -project MihirakiPDFUtility.xcodeproj
xcodebuild build -project MihirakiPDFUtility.xcodeproj -scheme MihirakiPDFUtility \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO
xcrun simctl list devices available
# Replace SIMULATOR_UUID with the UUID of an available iOS 18+ device.
xcodebuild test -project MihirakiPDFUtility.xcodeproj -scheme MihirakiPDFUtility \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UUID' \
  -parallel-testing-enabled NO -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO
python3 scripts/check_repository.py
python3 -m unittest discover -s scripts -p 'test_check_repository.py'
```

In Xcode, open `MihirakiPDFUtility.xcodeproj`, select the shared scheme of the same name and a simulator, then Run. Simulator builds do not need the author's certificate or private key. For a physical device, set your own Team and an available Bundle Identifier under Signing & Capabilities. Keep private keys and provisioning profiles out of Git.

Development-machine PDFs under `testdata/` are not required for normal builds or regression tests. The 1,100-page regression test generates a small synthetic PDF and removes it afterward; it does not certify performance on image-heavy documents. If an older public revision fails because it tries to bundle local `testdata/`, use a revision containing this fix. Include asset catalogs, Info.plist, added Swift sources, the Privacy Manifest and the shared scheme together when committing development work.

App Store signing/distribution and real purchases are separate work. `Products.storekit/Configuration.storekit` contains local test products, not production credentials. Diagnostic logs expire after 14 days and are pruned during startup/read/write operations, not by a timer while the app is stopped.

## Migration policy

- Code created by the original author is used as a reference for features and logic.
- PySide6, Shiboken6, Qt, PyMuPDF, MuPDF, Pillow, PyWinRT, the Python runtime, PyInstaller and their generated artifacts are not reused.
- The new implementation prioritizes standard Apple-platform APIs such as Swift, SwiftUI and PDFKit.
- Asset provenance and integrity are recorded in `PROVENANCE.md` and `migration/ASSET_MANIFEST.sha256`.

## License

Unless otherwise noted, source code, documentation, translations, tests and project assets in this repository are provided under the [MIT License](LICENSE).
