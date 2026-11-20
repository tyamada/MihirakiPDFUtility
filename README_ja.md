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

[サンプル漫画PDF](https://tyamada.github.io/manga-prompt-kit/samples/ja/) — サンプルPDFダウンロードページで言語と話数を選べます。 第1〜3話、17地域・言語の全51冊を掲載しています。

作者：**こまいろ日和（Komairo Hiyori）**。ライセンス：[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)。[ライセンス・クレジットの詳細](docs/sample-pdf-license.html#ja)。PDF一覧は集約先で更新します。

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
