# MihirakiPDFUtility

[English](README.md) | 日本語

MihirakiPDFUtilityは、PDFページの並べ替え、回転、挿入、削除などをローカル環境で行うAppleプラットフォーム向けアプリです。

このリポジトリは、Takuma Yamadaが作成したFolimeldのコードと仕様を移植元として、新しいMITライセンスのアプリを開発するために作成されました。

## 現在の状態

- MITリポジトリの初期化
- 移植元の識別情報を記録
- 権利確認済みの文書、翻訳、テスト、画像、テストPDFを登録
- iOS／iPadOS用SwiftUIプロジェクトとSwift Testingターゲットを作成
- PDFを開く、別PDFのページ追加、同じサイズの空白ページ挿入、ページ一覧、複数選択、回転、削除、並べ替え、書き出しの初期実装
- 未保存マークと、別のPDFを開く前の保存確認
- 選択ページのドラッグ並べ替えと、前後へのボタン移動
- パスワード保護PDFを開くためのパスワード入力
- タイトル、作成者、件名、キーワードの文書プロパティ編集
- 書き出すPDFへの閲覧パスワード設定・解除
- String Catalogによる13言語UI
- Filesアプリや共有シートからのPDF直接オープン
- PDFの文書情報、表示方法、バージョン情報の確認と編集
- ブロンズ、シルバー、ゴールドのサポーターアイコンを永続的に利用できる、任意の非消耗型アプリ内購入
- GitHub Pages用のマーケティング、プライバシー、サポートページ

## ウェブサイト

- [マーケティングページ](https://tyamada.github.io/MihirakiPDFUtility/index_ja.html)
- [プライバシーポリシー](https://tyamada.github.io/MihirakiPDFUtility/privacy_ja.html)
- [サポート](https://tyamada.github.io/MihirakiPDFUtility/support_ja.html)

## サンプルPDF

- [ためし部 第１話 ひと息マップ (Japanese)](docs/pdf/tameshibu_episode1_ja.pdf)
- [ためし部 第２話 机、ひろがる。 (Japanese)](docs/pdf/tameshibu_episode2_ja.pdf)
- [THE TRY-IT CLUB EPISODE 1 THE BREAK-TIME MAP (English)](docs/pdf/tameshibu_episode1_en.pdf)
- [THE TRY-IT CLUB EPISODE 2 ROOM TO GROW (English)](docs/pdf/tameshibu_episode2_en.pdf)
- [해봄부 제1화 한숨 돌림 지도 (Korean)](docs/pdf/tameshibu_episode1_ko.pdf)
- [해봄부제2화 책상이 넓어지다 (Korean)](docs/pdf/tameshibu_episode2_ko.pdf)
- [试试社 第1话 歇口气地图 (Chinese (Simplified))](docs/pdf/tameshibu_episode1_zh_cn.pdf)
- [试试社 第2话 桌子变大了 (Chinese (Simplified))](docs/pdf/tameshibu_episode2_zh_cn.pdf)

## 対応方針

最初にiOS版を開発し、その後iPadOSとmacOSへ展開します。Linux版とWindows版は作成しません。

## 移行方針

- 移植元の本人作成コードは、機能とロジックの参照元として利用します。
- PySide6、Shiboken6、Qt、PyMuPDF、MuPDF、Pillow、PyWinRT、Pythonランタイム、PyInstaller、およびそれらの生成物は流用しません。
- 新しい実装では、Swift、SwiftUI、PDFKitなどAppleプラットフォームの標準APIを優先します。
- 移行対象資産の出自と完全性は `PROVENANCE.md` と `migration/ASSET_MANIFEST.sha256` に記録します。

## 開発環境

`MihirakiPDFUtility.xcodeproj` をXcodeで開き、`MihirakiPDFUtility` スキームを選択します。現在のDeployment TargetはiOS 18.0で、iPhoneとiPadを対象にしています。

## ライセンス

特記のない限り、このリポジトリのソースコード、文書、翻訳、テスト、およびプロジェクト資産は[MIT License](LICENSE)で提供されます。
