# Migration source reference

MihirakiPDFUtilityの機能および本人作成ロジックの移植元は、次のFolimeldリビジョンです。

- Repository: `https://github.com/tyamada/Folimeld.git`
- Local path: `/Users/tyamada22/src/Folimeld`
- Commit: `187ac1e54a45e540e6996d34eb7615c7f0c82e56`

## 参照可能な本人作成コード

- `main.py`
- `folimeld/*.py`
- `tests/*.py`
- プロジェクト固有のビルドおよび補助スクリプト

これらは移植時の機能・挙動・ロジックの参照元です。外部ライブラリのAPI呼び出しや外部ライブラリ由来の実装を新しいアプリへコピーしません。

## 主な置換境界

| Folimeldでの役割 | 旧依存 | MihirakiPDFUtilityでの扱い |
| --- | --- | --- |
| GUIと設定 | PySide6 / Qt | SwiftUIとApple標準APIで新規実装 |
| PDF読込、描画、編集、暗号化 | PyMuPDF / MuPDF | PDFKitとCore Graphicsを評価して新規実装 |
| 画像処理 | Pillow | Apple標準APIで新規実装、または事前生成済み権利確認資産を使用 |
| Windows Store連携 | PyWinRT | 移植対象外。必要な購入機能はStoreKitで別途設計 |
| パッケージング | PyInstaller等 | Xcodeのビルドシステムで構築 |

## 対象プラットフォーム

実装順はiOS、iPadOS、macOSです。LinuxおよびWindows向けコード、パッケージ、配布設定は移植しません。

## 注意

`migration/approved-assets/` は移行可能な資産の保存場所であり、アプリへ自動的に組み込まれる場所ではありません。実装段階で必要なファイルだけを製品ターゲットへ追加します。
