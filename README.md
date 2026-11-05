# MihirakiPDFUtility

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
- Run an on-device CPU, memory and PDF workflow performance test from Version Information
- Keep privacy-preserving diagnostic logs on the device, view or copy them for troubleshooting, and automatically delete records after 14 days
- User interface localized in 14 languages (Japanese, English, Korean, Simplified Chinese, Traditional Chinese, German, French, Spanish, Portuguese, Italian, Vietnamese, Filipino, Nepali, Indonesian)
- Sample manga catalog v2 (51 volumes across 17 locales) and official YouTube Shorts video guides
- Optional non-consumable In-App Purchases for permanent Bronze, Silver, and Gold supporter icons
- Marketing, privacy and support pages for GitHub Pages

## Website

- [Marketing page](https://tyamada.github.io/MihirakiPDFUtility/)
- [Privacy Policy](https://tyamada.github.io/MihirakiPDFUtility/privacy.html)
- [Support](https://tyamada.github.io/MihirakiPDFUtility/support.html)

## Sample PDFs

The author’s official romanized name is **Komairo Hiyori**. Sample manga PDFs are published in `docs/sample/` (the `sample/` directory on GitHub Pages). Episodes 1–3 are available across 17 locales (51 PDFs total).

- [ためし部 第1話 ひと息マップ — こまいろ日和 (Japanese)](docs/sample/tameshibu_episode1_2_ja.pdf)
- [ためし部 第2話 机、ひろがる。 — こまいろ日和 (Japanese)](docs/sample/tameshibu_episode2_2_ja.pdf)
- [ためし部 第3話 出張、ためし部！ — こまいろ日和 (Japanese)](docs/sample/tameshibu_episode3_ja.pdf)
- [THE TRY-IT CLUB EPISODE 1 THE BREAK-TIME MAP — Komairo Hiyori (English)](docs/sample/tameshibu_episode1_2_en.pdf)
- [THE TRY-IT CLUB EPISODE 2 ROOM TO GROW — Komairo Hiyori (English)](docs/sample/tameshibu_episode2_2_en.pdf)
- [THE TRY-IT CLUB EPISODE 3 OUT AND ABOUT — Komairo Hiyori (English)](docs/sample/tameshibu_episode3_en.pdf)
- [해봄부 제1화 한숨 돌림 지도 — 코마이로 히요리 (Korean)](docs/sample/tameshibu_episode1_2_ko.pdf)
- [해봄부 제2화 책상이 넓어지다 — 코마이로 히요리 (Korean)](docs/sample/tameshibu_episode2_2_ko.pdf)
- [해봄부 제3화 해봄부, 출장! — 코마이로 히요리 (Korean)](docs/sample/tameshibu_episode3_ko.pdf)
- [试试社 第1话 歇口气地图 — 小真彩日和 (Chinese (Simplified))](docs/sample/tameshibu_episode1_2_zh_cn.pdf)
- [试试社 第2话 桌子变大了 — 小真彩日和 (Chinese (Simplified))](docs/sample/tameshibu_episode2_2_zh_cn.pdf)
- [试试社 第3话 试试社，出差啦！ — 小真彩日和 (Chinese (Simplified))](docs/sample/tameshibu_episode3_zh_cn.pdf)
- [試試社 第1話 — 小舞樓日和 (Chinese (Traditional))](docs/sample/tameshibu_episode1_2_zh_tw.pdf)
- [試試社 第2話 — 小舞樓日和 (Chinese (Traditional))](docs/sample/tameshibu_episode2_2_zh_tw.pdf)
- [試試社 第3話 試試社，出差啦！ — 小舞樓日和 (Chinese (Traditional))](docs/sample/tameshibu_episode3_zh_tw.pdf)
- [DER PROBIERCLUB FOLGE 1 — Komairo Hiyori (German)](docs/sample/tameshibu_episode1_2_de.pdf)
- [DER PROBIERCLUB FOLGE 2 — Komairo Hiyori (German)](docs/sample/tameshibu_episode2_2_de.pdf)
- [Der Probierclub - Folge 3: Unterwegs — Komairo Hiyori (German)](docs/sample/tameshibu_episode3_de.pdf)
- [LE CLUB DES ESSAIS EPISODE 1 — Komairo Hiyori (French)](docs/sample/tameshibu_episode1_2_fr.pdf)
- [LE CLUB DES ESSAIS EPISODE 2 — Komairo Hiyori (French)](docs/sample/tameshibu_episode2_2_fr.pdf)
- [Le Club des essais - Épisode 3 : Le club en sortie — Komairo Hiyori (French)](docs/sample/tameshibu_episode3_fr.pdf)
- [EL CLUB DE LOS EXPERIMENTOS - EPISODIO 1 / MAPA DE DESCANSOS — Komairo Hiyori (Spanish)](docs/sample/tameshibu_episode1_es.pdf)
- [EL CLUB DE LOS EXPERIMENTOS - EPISODIO 2 / LA MESA CRECE — Komairo Hiyori (Spanish)](docs/sample/tameshibu_episode2_es.pdf)
- [EL CLUB DE LOS EXPERIMENTOS - EPISODIO 3 / DE SALIDA — Komairo Hiyori (Spanish)](docs/sample/tameshibu_episode3_es.pdf)
- [O CLUBE DAS EXPERIÊNCIAS - EPISÓDIO 1 / MAPA DO DESCANSO — Komairo Hiyori (Portuguese)](docs/sample/tameshibu_episode1_pt.pdf)
- [O CLUBE DAS EXPERIÊNCIAS - EPISÓDIO 2 / A MESA CRESCE — Komairo Hiyori (Portuguese)](docs/sample/tameshibu_episode2_pt.pdf)
- [O CLUBE DAS EXPERIÊNCIAS - EPISÓDIO 3 / O CLUBE VAI À BIBLIOTECA — Komairo Hiyori (Portuguese)](docs/sample/tameshibu_episode3_pt.pdf)
- [IL CLUB DEGLI ESPERIMENTI - EPISODIO 1 / LA MAPPA DELLE PAUSE — Komairo Hiyori (Italian)](docs/sample/tameshibu_episode1_it.pdf)
- [IL CLUB DEGLI ESPERIMENTI - EPISODIO 2 / IL TAVOLO SI ALLARGA — Komairo Hiyori (Italian)](docs/sample/tameshibu_episode2_it.pdf)
- [IL CLUB DEGLI ESPERIMENTI - EPISODIO 3 / IL CLUB IN TRASFERTA — Komairo Hiyori (Italian)](docs/sample/tameshibu_episode3_it.pdf)
- [CÂU LẠC BỘ THỬ NGHIỆM - TẬP 1 / BẢN ĐỒ CHỖ NGHỈ — Komairo Hiyori (Vietnamese)](docs/sample/tameshibu_episode1_vi.pdf)
- [CÂU LẠC BỘ THỬ NGHIỆM - TẬP 2 / CHIẾC BÀN RỘNG HƠN — Komairo Hiyori (Vietnamese)](docs/sample/tameshibu_episode2_vi.pdf)
- [CÂU LẠC BỘ THỬ NGHIỆM - TẬP 3 / CÂU LẠC BỘ ĐI CÔNG TÁC — Komairo Hiyori (Vietnamese)](docs/sample/tameshibu_episode3_vi.pdf)
- [CLUB NG MGA PAGSUBOK - KABANATA 1 / MAPA NG PAHINGAHAN — Komairo Hiyori (Filipino / Tagalog)](docs/sample/tameshibu_episode1_tl.pdf)
- [CLUB NG MGA PAGSUBOK - KABANATA 2 / LUMUWANG ANG MESA — Komairo Hiyori (Filipino / Tagalog)](docs/sample/tameshibu_episode2_tl.pdf)
- [CLUB NG MGA PAGSUBOK - KABANATA 3 / LUMABAS ANG CLUB — Komairo Hiyori (Filipino / Tagalog)](docs/sample/tameshibu_episode3_tl.pdf)
- [प्रयोग क्लब - भाग 1 / आरामको नक्सा — Komairo Hiyori (Nepali)](docs/sample/tameshibu_episode1_ne.pdf)
- [प्रयोग क्लब - भाग 2 / टेबुल फराकिलो भयो — Komairo Hiyori (Nepali)](docs/sample/tameshibu_episode2_ne.pdf)
- [प्रयोग क्लब - भाग 3 / क्लबको पहिलो भ्रमण — Komairo Hiyori (Nepali)](docs/sample/tameshibu_episode3_ne.pdf)
- [KLUB COBA-COBA - EPISODE 1 / PETA TEMPAT ISTIRAHAT — Komairo Hiyori (Indonesian)](docs/sample/tameshibu_episode1_id.pdf)
- [KLUB COBA-COBA - EPISODE 2 / MEJANYA MAKIN LUAS — Komairo Hiyori (Indonesian)](docs/sample/tameshibu_episode2_id.pdf)
- [KLUB COBA-COBA - EPISODE 3 / KLUB JALAN-JALAN — Komairo Hiyori (Indonesian)](docs/sample/tameshibu_episode3_id.pdf)

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
