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

- [ためし部 第１話 ひと息マップ (Japanese)](docs/pdf/tameshibu_episode1_ja.pdf)
- [ためし部 第２話 机、ひろがる。 (Japanese)](docs/pdf/tameshibu_episode2_ja.pdf)
- [THE TRY-IT CLUB EPISODE 1 THE BREAK-TIME MAP (English)](docs/pdf/tameshibu_episode1_en.pdf)
- [THE TRY-IT CLUB EPISODE 2 ROOM TO GROW (English)](docs/pdf/tameshibu_episode2_en.pdf)
- [해봄부 제1화 한숨 돌림 지도 (Korean)](docs/pdf/tameshibu_episode1_ko.pdf)
- [해봄부제2화 책상이 넓어지다 (Korean)](docs/pdf/tameshibu_episode2_ko.pdf)
- [试试社 第1话 歇口气地图 (Chinese (Simplified))](docs/pdf/tameshibu_episode1_zh_cn.pdf)
- [试试社 第2话 桌子变大了 (Chinese (Simplified))](docs/pdf/tameshibu_episode2_zh_cn.pdf)

## Development

Open `MihirakiPDFUtility.xcodeproj` in Xcode and select the `MihirakiPDFUtility` scheme. The current deployment targets are iOS 18.0 and macOS 15.0, and the app supports iPhone, iPad, and Mac.

## Migration policy

- Code created by the original author is used as a reference for features and logic.
- PySide6, Shiboken6, Qt, PyMuPDF, MuPDF, Pillow, PyWinRT, the Python runtime, PyInstaller and their generated artifacts are not reused.
- The new implementation prioritizes standard Apple-platform APIs such as Swift, SwiftUI and PDFKit.
- Asset provenance and integrity are recorded in `PROVENANCE.md` and `migration/ASSET_MANIFEST.sha256`.

## License

Unless otherwise noted, source code, documentation, translations, tests and project assets in this repository are provided under the [MIT License](LICENSE).
