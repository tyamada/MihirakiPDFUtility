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

The author’s official romanized name is **Komairo Hiyori**. Sample manga PDFs are published in `docs/sample/` (the `sample/` directory on GitHub Pages). Episodes 1–3 are each available in 14 languages (42 PDFs total).

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

Open `MihirakiPDFUtility.xcodeproj` in Xcode and select the `MihirakiPDFUtility` scheme. The current deployment targets are iOS 18.0 and macOS 15.0, and the app supports iPhone, iPad, and Mac.

## Migration policy

- Code created by the original author is used as a reference for features and logic.
- PySide6, Shiboken6, Qt, PyMuPDF, MuPDF, Pillow, PyWinRT, the Python runtime, PyInstaller and their generated artifacts are not reused.
- The new implementation prioritizes standard Apple-platform APIs such as Swift, SwiftUI and PDFKit.
- Asset provenance and integrity are recorded in `PROVENANCE.md` and `migration/ASSET_MANIFEST.sha256`.

## License

Unless otherwise noted, source code, documentation, translations, tests and project assets in this repository are provided under the [MIT License](LICENSE).
