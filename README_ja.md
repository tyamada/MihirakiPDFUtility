# MihirakiPDFUtility

[English](README.md) | 日本語

MihirakiPDFUtilityは、PDFページの並べ替え、回転、挿入、削除などをローカル環境で行うAppleプラットフォーム向けアプリです。

このリポジトリは、Takuma Yamadaが作成したFolimeldのコードと仕様を移植元として、新しいMITライセンスのアプリを開発するために作成されました。

## 現在の状態

- MITリポジトリの初期化および権利確認済みリソースの管理
- iOS／iPadOS用SwiftUIプロジェクトとSwift Testingターゲット（191件の自動単体テスト）
- PDFを開く、別PDFのページ追加、画像のPDF変換読み込み、Undo/Redo対応
- 見開きページの中央2分割（左右分割・上下分割）
- 選択ページの余白均等トリミング（0〜40%クランプ・境界保護付き）
- 1〜5倍ズーム、ドラッグパン、左右スワイプ、RTL（右開き）読書順対応の高機能全画面プレビュー
- ページの複数選択、ドラッグ並べ替え、前後ボタン移動、90°刻みの回転、複製、削除
- 選択反転（Invert Selection）による選択／非選択の素早い反転
- サムネイルサイズ切替（S/M/L）および操作バーのボタン表示形式切替（アイコン＋文字／アイコンのみ／文字のみ）
- キーボードショートカット網羅（⌘O, ⌘S, ⌘Z, ⇧⌘Z, ⌘A, ⌘L, ⌘R, ⇧⌘R 等）
- 同じサイズの空白ページ挿入、選択ページのみの別PDF書き出し
- 未保存マークと、別のPDFを開く前の保存確認
- パスワード保護PDFの解除および書き出しPDFへの閲覧パスワード設定
- タイトル、作成者、件名、キーワードの文書プロパティ編集、見開き表示設定（表紙有無・綴じ方向）
- String Catalogによる14言語UI（日・英・簡・繁・韓・独・仏・西・葡・伊・越・比・尼・ネパール等）
- サンプル漫画v2カタログ（17言語地域・全51冊）および公式YouTube Shorts動画チュートリアル連携
- Filesアプリや共有シートからのPDF直接オープン
- 「設定 > 診断 > パフォーマンステストを実行」からCPU・メモリ・PDF操作の端末内性能テスト
- 「設定 > 診断 > 診断ログを表示」から端末内の診断ログを閲覧・コピー。個人情報やPDF内容を除外し、14日の保持期限を起動・読み書き時に整理
- 診断テスト報告は内容を確認して任意に共有し、自動送信しない。別の性能テスト報告には端末名が含まれる場合があるため、共有前に確認
- ブロンズ、シルバー、ゴールドのサポーターアイコンを永久的に利用できる、任意の非消耗型アプリ内購入
- GitHub Pages用のマーケティング、プライバシー、サポートページ

## ウェブサイト

- [マーケティングページ](https://tyamada.github.io/MihirakiPDFUtility/index_ja.html)
- [プライバシーポリシー](https://tyamada.github.io/MihirakiPDFUtility/privacy_ja.html)
- [サポート](https://tyamada.github.io/MihirakiPDFUtility/support_ja.html)

## サンプルPDF

作者「こまいろ日和」の正式なローマ字表記は **Komairo Hiyori** です。サンプルPDFマンガは [manga-pdf-20261103-v1 Release](https://github.com/tyamada/manga-prompt-kit/releases/tag/manga-pdf-20261103-v1)で配布しています。第1〜3話を17言語地域、計51ファイルで提供しています。

- [ためし部 第1話 ひと息マップ — こまいろ日和 (Japanese)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_2_ja.pdf)
- [ためし部 第2話 机、ひろがる。 — こまいろ日和 (Japanese)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_2_ja.pdf)
- [ためし部 第3話 出張、ためし部！ — こまいろ日和 (Japanese)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_ja.pdf)
- [THE TRY-IT CLUB EPISODE 1 THE BREAK-TIME MAP — Komairo Hiyori (English)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_en.pdf)
- [THE TRY-IT CLUB EPISODE 2 ROOM TO GROW — Komairo Hiyori (English)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_en.pdf)
- [THE TRY-IT CLUB EPISODE 3 OUT AND ABOUT — Komairo Hiyori (English)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_en.pdf)
- [해봄부 제1화 한숨 돌림 지도 — 코마이로 히요리 (Korean)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_2_ko.pdf)
- [해봄부 제2화 책상이 넓어지다 — 코마이로 히요리 (Korean)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_2_ko.pdf)
- [해봄부 제3화 해봄부, 출장! — 코마이로 히요리 (Korean)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_ko.pdf)
- [试试社 第1话 歇口气地图 — 小真彩日和 (Chinese (Simplified))](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_2_zh_cn.pdf)
- [试试社 第2话 桌子变大了 — 小真彩日和 (Chinese (Simplified))](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_2_zh_cn.pdf)
- [试试社 第3话 试试社，出差啦！ — 小真彩日和 (Chinese (Simplified))](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_zh_cn.pdf)
- [試試社 第1話 — 小舞樓日和（中国語・繁体字）](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_2_zh_tw.pdf)
- [試試社 第2話 — 小舞樓日和（中国語・繁体字）](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_2_zh_tw.pdf)
- [試試社 第3話 試試社，出差啦！ — 小舞樓日和 (Chinese (Traditional))](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_zh_tw.pdf)
- [DER PROBIERCLUB FOLGE 1 — Komairo Hiyori（ドイツ語）](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_de.pdf)
- [DER PROBIERCLUB FOLGE 2 — Komairo Hiyori（ドイツ語）](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_de.pdf)
- [Der Probierclub - Folge 3: Unterwegs — Komairo Hiyori (German)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_de.pdf)
- [LE CLUB DES ESSAIS EPISODE 1 — Komairo Hiyori（フランス語）](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_fr.pdf)
- [LE CLUB DES ESSAIS EPISODE 2 — Komairo Hiyori（フランス語）](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_fr.pdf)
- [Le Club des essais - Épisode 3 : Le club en sortie — Komairo Hiyori (French)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_fr.pdf)
- [EL CLUB DE LOS EXPERIMENTOS - EPISODIO 1 / MAPA DE DESCANSOS — Komairo Hiyori (Spanish)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_es.pdf)
- [EL CLUB DE LOS EXPERIMENTOS - EPISODIO 2 / LA MESA CRECE — Komairo Hiyori (Spanish)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_es.pdf)
- [EL CLUB DE LOS EXPERIMENTOS - EPISODIO 3 / DE SALIDA — Komairo Hiyori (Spanish)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_es.pdf)
- [O CLUBE DAS EXPERIÊNCIAS - EPISÓDIO 1 / MAPA DO DESCANSO — Komairo Hiyori (Portuguese)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_pt.pdf)
- [O CLUBE DAS EXPERIÊNCIAS - EPISÓDIO 2 / A MESA CRESCE — Komairo Hiyori (Portuguese)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_pt.pdf)
- [O CLUBE DAS EXPERIÊNCIAS - EPISÓDIO 3 / O CLUBE VAI À BIBLIOTECA — Komairo Hiyori (Portuguese)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_pt.pdf)
- [IL CLUB DEGLI ESPERIMENTI - EPISODIO 1 / LA MAPPA DELLE PAUSE — Komairo Hiyori (Italian)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_it.pdf)
- [IL CLUB DEGLI ESPERIMENTI - EPISODIO 2 / IL TAVOLO SI ALLARGA — Komairo Hiyori (Italian)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_it.pdf)
- [IL CLUB DEGLI ESPERIMENTI - EPISODIO 3 / IL CLUB IN TRASFERTA — Komairo Hiyori (Italian)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_it.pdf)
- [CÂU LẠC BỘ THỬ NGHIỆM - TẬP 1 / BẢN ĐỒ CHỖ NGHỈ — Komairo Hiyori (Vietnamese)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_vi.pdf)
- [CÂU LẠC BỘ THỬ NGHIỆM - TẬP 2 / CHIẾC BÀN RỘNG HƠN — Komairo Hiyori (Vietnamese)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_vi.pdf)
- [CÂU LẠC BỘ THỬ NGHIỆM - TẬP 3 / CÂU LẠC BỘ ĐI CÔNG TÁC — Komairo Hiyori (Vietnamese)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_vi.pdf)
- [CLUB NG MGA PAGSUBOK - KABANATA 1 / MAPA NG PAHINGAHAN — Komairo Hiyori (Filipino / Tagalog)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_tl.pdf)
- [CLUB NG MGA PAGSUBOK - KABANATA 2 / LUMUWANG ANG MESA — Komairo Hiyori (Filipino / Tagalog)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_tl.pdf)
- [CLUB NG MGA PAGSUBOK - KABANATA 3 / LUMABAS ANG CLUB — Komairo Hiyori (Filipino / Tagalog)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_tl.pdf)
- [प्रयोग क्लब - भाग 1 / आरामको नक्सा — Komairo Hiyori (Nepali)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_ne.pdf)
- [प्रयोग क्लब - भाग 2 / टेबुल फराकिलो भयो — Komairo Hiyori (Nepali)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_ne.pdf)
- [प्रयोग क्लब - भाग 3 / क्लबको पहिलो भ्रमण — Komairo Hiyori (Nepali)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_ne.pdf)
- [KLUB COBA-COBA - EPISODE 1 / PETA TEMPAT ISTIRAHAT — Komairo Hiyori (Indonesian)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_id.pdf)
- [KLUB COBA-COBA - EPISODE 2 / MEJANYA MAKIN LUAS — Komairo Hiyori (Indonesian)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_id.pdf)
- [KLUB COBA-COBA - EPISODE 3 / KLUB JALAN-JALAN — Komairo Hiyori (Indonesian)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_id.pdf)

- [EL CLUB DE LOS EXPERIMENTOS - EPISODIO 1 / MAPA DE DESCANSOS [es-419] — Komairo Hiyori (es_419)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_es_419.pdf)
- [O CLUBE DAS EXPERIÊNCIAS - EPISÓDIO 1 / MAPA DO DESCANSO [pt-PT] — Komairo Hiyori (pt_pt)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_pt_pt.pdf)
- [試試社 第1話 歇口氣地圖 [zh-Hant-HK] — Komairo Hiyori (zh_hk)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode1_3_zh_hk.pdf)
- [EL CLUB DE LOS EXPERIMENTOS - EPISODIO 2 / LA MESA CRECE [es-419] — Komairo Hiyori (es_419)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_es_419.pdf)
- [O CLUBE DAS EXPERIÊNCIAS - EPISÓDIO 2 / A MESA CRESCE [pt-PT] — Komairo Hiyori (pt_pt)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_pt_pt.pdf)
- [試試社 第2話 桌子變大了 [zh-Hant-HK] — Komairo Hiyori (zh_hk)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode2_3_zh_hk.pdf)
- [EL CLUB DE LOS EXPERIMENTOS - EPISODIO 3 / DE SALIDA [es-419] — Komairo Hiyori (es_419)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_es_419.pdf)
- [O CLUBE DAS EXPERIÊNCIAS - EPISÓDIO 3 / O CLUBE VAI À BIBLIOTECA [pt-PT] — Komairo Hiyori (pt_pt)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_pt_pt.pdf)
- [第3話 / 試試社，出差啦！ [zh-Hant-HK] — Komairo Hiyori (zh_hk)](https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/tameshibu_episode3_2_zh_hk.pdf)

サンプルPDFは[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)の下で提供されています。再利用時の表示事項と生成AI利用の説明を含む[ライセンスおよび著作権表示の詳細](docs/sample-pdf-license.html#ja)もご確認ください。

## 対応方針

最初にiOS版を開発し、その後iPadOSとmacOSへ展開します。Linux版とWindows版は作成しません。

## 移行方針

- 移植元の本人作成コードは、機能とロジックの参照元として利用します。
- PySide6、Shiboken6、Qt、PyMuPDF、MuPDF、Pillow、PyWinRT、Pythonランタイム、PyInstaller、およびそれらの生成物は流用しません。
- 新しい実装では、Swift、SwiftUI、PDFKitなどAppleプラットフォームの標準APIを優先します。
- 移行対象資産の出自と完全性は `PROVENANCE.md` と `migration/ASSET_MANIFEST.sha256` に記録します。

アプリは同梱カタログと固定Release URLを使用します。サンプルID・言語キー・SHA-256・端末内の保存名を維持します。フィリピン語も言語キー `fil` と第1・2話の保存名 `_fil.pdf` を保ち、新Releaseの `_tl.pdf` を取得します。Releaseの `pdf-manifest.json`・`pdf-migration.csv`・`SHA256SUMS` を同じディレクトリに取得し、`python3 scripts/verify_sample_distribution.py /path/to/evidence` で51件を照合できます。`--download-directory /path/to/pdfs` を追加すると匿名取得・サイズ・チェックサムも検証します。

## 開発環境

このアプリは開発途中です。診断機能などの未コミット実装があり、公開mainと手元の作業版は同一とは限りません。資料にある実装状況と、動作確認済みの範囲を区別してください。

- macOSとXcode、iOS 18.0以降のシミュレータが必要です。今回の確認環境はXcode 27.1です。
- Xcodeの初回起動と追加コンポーネントの導入を済ませ、`xcode-select -p`がXcodeのDeveloperディレクトリを示すことを確認します。
- 外部SwiftパッケージやCocoaPodsは不要です。資料検査スクリプトにはPython 3を使用します。
- プロジェクトにはmacOS 15.0の設定もありますが、Mac対応の完成度・画面操作の検証はiOS/iPadOSと別に管理します。

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

Xcodeでは`MihirakiPDFUtility.xcodeproj`を開き、同名の共有スキームとシミュレータを選んでRunします。シミュレータは作者の証明書や秘密鍵なしでビルドできます。実機にインストールする場合はSigning & Capabilitiesで自分のTeamと使用可能なBundle Identifierを設定します。鍵・プロビジョニングプロファイルはGitへ登録しません。

`testdata/`にある開発機だけのPDFは、通常ビルドや自動回帰テストに不要です。1,100ページの回帰テストは小さな合成PDFを生成して実行し、終了時に削除します。これは画像の多い既存PDFでの性能保証とは異なります。公開mainで古い`testdata/`同梱設定によりビルドが失敗する場合、この修正を含むリビジョンを使用してください。アセットカタログ・Info.plist・追加したSwiftファイル・Privacy Manifest・共有スキームを合わせてコミットする必要があります。

App Store署名・配布や実購入は別工程です。`Products.storekit/Configuration.storekit`は開発用の製品定義であり、配布用の認証情報ではありません。診断ログの14日保持期限は読み書き・起動時に整理され、アプリ停止中のタイマー削除ではありません。

## ライセンス

特記のない限り、このリポジトリのソースコード、文書、翻訳、テスト、およびプロジェクト資産は[MIT License](LICENSE)で提供されます。
