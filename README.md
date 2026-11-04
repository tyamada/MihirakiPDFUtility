# MihirakiPDFUtility

English | [日本語](README_ja.md)

MihirakiPDFUtility is an app for Apple platforms that organizes PDF pages locally, including reordering, rotating, inserting and removing pages.

This repository was created to develop a new app based on code and specifications from Folimeld, originally created by Takuma Yamada.

## Current status

- SwiftUI project for iOS and iPadOS with a Swift Testing target
- Open and export PDFs
- Add pages from another PDF
- Reorder, duplicate, rotate and remove selected pages
- Insert blank pages before or after a selection
- Export selected pages as a separate PDF
- Open password-protected PDFs
- Edit document title, author, subject and keywords
- Configure PDF page layout, cover display and reading direction
- Set or remove a viewing password on exported PDFs
- Open PDFs from Files and the system share sheet
- Run an on-device CPU, memory and PDF workflow performance test from Version Information
- Keep privacy-preserving diagnostic logs on the device, view or copy them for troubleshooting, and automatically delete records after 14 days
- User interface localized in 13 languages
- Optional non-consumable In-App Purchases for permanent Bronze, Silver, and Gold supporter icons
- Marketing, privacy and support pages for GitHub Pages

## Website

- [Marketing page](https://tyamada.github.io/MihirakiPDFUtility/)
- [Privacy Policy](https://tyamada.github.io/MihirakiPDFUtility/privacy.html)
- [Support](https://tyamada.github.io/MihirakiPDFUtility/support.html)

## Sample PDFs

- [ためし部 第1話 ひと息マップ — こまいろ日和 (Japanese)](docs/pdf/tameshibu_episode1_2_ja.pdf)
- [ためし部 第2話 机、ひろがる。 — こまいろ日和 (Japanese)](docs/pdf/tameshibu_episode2_2_ja.pdf)
- [THE TRY-IT CLUB EPISODE 1 THE BREAK-TIME MAP — Komairo Hiyori (English)](docs/pdf/tameshibu_episode1_2_en.pdf)
- [THE TRY-IT CLUB EPISODE 2 ROOM TO GROW — Komairo Hiyori (English)](docs/pdf/tameshibu_episode2_2_en.pdf)
- [해봄부 제1화 한숨 돌림 지도 — 코마이로 히요리 (Korean)](docs/pdf/tameshibu_episode1_2_ko.pdf)
- [해봄부 제2화 책상이 넓어지다 — 코마이로 히요리 (Korean)](docs/pdf/tameshibu_episode2_2_ko.pdf)
- [试试社 第1话 歇口气地图 — 小真彩日和 (Chinese (Simplified))](docs/pdf/tameshibu_episode1_2_zh_cn.pdf)
- [试试社 第2话 桌子变大了 — 小真彩日和 (Chinese (Simplified))](docs/pdf/tameshibu_episode2_2_zh_cn.pdf)
- [試試社 第1話 — 小舞樓日和 (Chinese (Traditional))](docs/pdf/tameshibu_episode1_2_zh_tw.pdf)
- [試試社 第2話 — 小舞樓日和 (Chinese (Traditional))](docs/pdf/tameshibu_episode2_2_zh_tw.pdf)
- [DER PROBIERCLUB FOLGE 1 — Komairo Hiyori (German)](docs/pdf/tameshibu_episode1_2_de.pdf)
- [DER PROBIERCLUB FOLGE 2 — Komairo Hiyori (German)](docs/pdf/tameshibu_episode2_2_de.pdf)
- [LE CLUB DES ESSAIS EPISODE 1 — Komairo Hiyori (French)](docs/pdf/tameshibu_episode1_2_fr.pdf)
- [LE CLUB DES ESSAIS EPISODE 2 — Komairo Hiyori (French)](docs/pdf/tameshibu_episode2_2_fr.pdf)

The sample PDFs are provided under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). See the [license and attribution details](docs/sample-pdf-license.html#en), including reuse requirements and the generative AI disclosure.

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
