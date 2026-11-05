# ローカリゼーション進捗

## 実行ルール

- 承認済み計画に従い、1言語・最大5項目（長文は1〜2項目）ずつ処理する。
- 翻訳担当の同時実行は1つ。次のセットを先行実行しない。
- 各セットで保存・翻訳状態・差し込み値・必要な複数形を確認し、結果を報告して停止する。
- 次のセットはユーザーの「次へ」等の指示を受けて開始する。
- ツールが60秒以上応答しない場合は追加処理を止めて状況を報告する。
- カタログはString Catalog専用ツールで扱う。既存翻訳を保持し不足分を補う。

## 対応順序

ja → en → ko → zh-Hant → de → fr → it → es → pt → zh-Hans → vi → fil → ne → id

## 最新の完了工程

日本語セット6：最後の説明文1項目の翻訳・保存・検証と、日本語の両カタログの充足確認を完了。
ソース変更・ビルドは実施していない。

| キー | 保存した日本語 |
|---|---|
| Measures generation, loading, and export of a 100-page PDF. | 100ページのPDFの生成、読み込み、および書き出しにかかる時間を測定します。 |

対象1項目の保存成功と未翻訳一覧からの除外を確認。差し込み値はなく、複数形・デバイス別バリエーションは不要。

| 日本語カタログ | 翻訳登録済み（machine_translated） | translated | 未翻訳 | 要確認 |
|---|---|---|---|---|
| Localizable.xcstrings | 238 | 0 | 0 | 0 |
| MihirakiPDFUtility-InfoPlist.xcstrings | 3 | 0 | 0 | 0 |

StringCatalogReadで確認。翻訳登録済み件数は人手レビュー済みを意味しない。
今回、両カタログで日本語の未翻訳・要確認がともに0件であることを確認。日本語の翻訳登録は完了。他言語の最新件数は今回未確認。画面表示や最終ビルドの検証は未実施。

## 次回の対象（英語・現状確認のみ）

1. 英語（en）のLocalizable.xcstringsの翻訳状態を確認する。
2. 英語（en）のMihirakiPDFUtility-InfoPlist.xcstringsの翻訳状態を確認する。

次回は英語の状態確認と進捗記録のみを実施して報告し、停止する。英語はソース言語のため、その扱いを踏まえて判定する。韓国語以降は先行処理しない。

## 日本語の未翻訳キー（今回確認時点）

なし。

## 引き継ぎ

- 日本語セット5の計測内容の説明文2項目（整数演算、16 MBデータバッファ）は翻訳・保存確認済み。

- 日本語セット4の説明文2項目（ログとテスト結果を外部送信しない旨）は翻訳・保存確認済み。

- 日本語セット3の4項目（Run Performance Test、Run Tests、Running Tests…、View Diagnostic Logs）は翻訳・保存確認済み。

- 日本語セット1の5項目（Mac、Memory Processing、No Logs、OS、PDF Workflow）は翻訳・保存確認済み。
- 日本語セット2の5項目（Performance Test、Refresh、Results、Right Binding、Right Binding with Cover）は翻訳・保存確認済み。

- 過去の作業でイタリア語のプロジェクト登録とカタログへの翻訳追加を実施済み。
- AppVersionInfo.swiftでlocalizedInfoDictionaryを反映する変更が保存済み。
- ContentView.swiftで代替エラーメッセージをローカライズ可能なTextとして表示する変更が保存済み。
- 最終的な全14言語の不足確認・最終ビルドは未完了。過去のビルド成功を最終検証として扱わない。
