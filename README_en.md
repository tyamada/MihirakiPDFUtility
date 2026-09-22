# MihirakiPDFUtility

English | [日本語](README.md)

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
- User interface localized in 13 languages
- Optional consumable In-App Purchases to support development
- Marketing, privacy and support pages for GitHub Pages

## Website

- [Marketing page](https://tyamada.github.io/MihirakiPDFUtility/index_en.html)
- [Privacy Policy](https://tyamada.github.io/MihirakiPDFUtility/privacy_en.html)
- [Support](https://tyamada.github.io/MihirakiPDFUtility/support_en.html)

## Development

Open `MihirakiPDFUtility.xcodeproj` in Xcode and select the `MihirakiPDFUtility` scheme. The current deployment target is iOS 18.0 and the app supports iPhone and iPad.

## Migration policy

- Code created by the original author is used as a reference for features and logic.
- PySide6, Shiboken6, Qt, PyMuPDF, MuPDF, Pillow, PyWinRT, the Python runtime, PyInstaller and their generated artifacts are not reused.
- The new implementation prioritizes standard Apple-platform APIs such as Swift, SwiftUI and PDFKit.
- Asset provenance and integrity are recorded in `PROVENANCE.md` and `migration/ASSET_MANIFEST.sha256`.

## License

Unless otherwise noted, source code, documentation, translations, tests and project assets in this repository are provided under the [MIT License](LICENSE).
