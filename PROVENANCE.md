# Provenance

この文書は、MihirakiPDFUtilityへ登録したコードおよび資産の出自を記録します。

## 権利者による宣言

移植元Folimeldのリポジトリ内にあるアプリケーションコード、文書、翻訳、テスト、およびプロジェクト固有の画像は、Takuma Yamadaが直接作成したか、Takuma YamadaがOpenAIのChatGPTまたはCodexを利用して作成したものです。

Takuma Yamadaは、自身が保有する権利の範囲で、これらをMihirakiPDFUtilityに移行し、MIT Licenseで提供することを許可しています。

## 移植元

- プロジェクト: Folimeld
- ローカル参照パス: `/Users/tyamada22/src/Folimeld`
- 上流URL: `https://github.com/tyamada/Folimeld.git`
- 参照コミット: `187ac1e54a45e540e6996d34eb7615c7f0c82e56`
- 移植元ライセンス: GNU Affero General Public License v3.0
- 移行許可者: Takuma Yamada（移植対象の本人作成部分の権利者）

既存のFolimeld公開物に適用されたAGPL-3.0はそのまま維持されます。MihirakiPDFUtilityは、権利者の許可に基づいて別のMITライセンスのリポジトリとして開始します。

## 生成AIを利用した資産

| 種別 | 移植元 | 作成方法 |
| --- | --- | --- |
| サポーター画像 | `assets/folimeld-supporter-maid.png` | ChatGPTを利用して生成 |
| アプリアイコン一式 | `assets/` | ChatGPTを利用して生成 |
| テストPDF | `testdata/*.pdf` | ChatGPTで生成、またはChatGPT生成画像からPDF化 |
| 翻訳 | `locales/*.json` | Codexを利用して生成 |
| スクリーンショット | `docs/screenshots/*` | Codexを利用して作成 |

文書およびテストは、Takuma Yamadaが直接作成したか、Codexを利用して作成したものです。

## 登録範囲

権利確認済み資産は `migration/approved-assets/` に保存します。個々のファイルのSHA-256は `migration/ASSET_MANIFEST.sha256` に記録します。

## 除外対象

以下はMihirakiPDFUtilityへ移行しません。

- PySide6、Shiboken6、Qt
- PyMuPDF、MuPDF
- Pillow
- PyWinRT
- Pythonランタイム
- PyInstaller
- 上記に由来するソース、バイナリ、プラグイン、翻訳、ライセンス束
- Folimeldの既存配布物、依存ソースアーカイブ、ビルド成果物

Codexなどが生成したコードを実装へ取り込む際は、第三者コードとの顕著な一致や第三者ライセンス表示の必要性を別途確認します。
