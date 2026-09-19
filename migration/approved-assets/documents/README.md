# Folimeld

[English](README_en.md) | [日本語](README.md)

![Folimeld icon](assets/Folimeld.iconset/icon_128x128.png)

Folimeld は、PDF のページを見ながら並べ替え、回転、挿入、削除できるデスクトップアプリです。Windows、macOS、Ubuntu、Debian に対応し、編集するファイルを外部サービスへ送信せず、ローカル環境で処理します。

![Folimeld main window](docs/screenshots/main-window.png)

## 特長

- サムネイルを見ながらPDFページを並べ替え
- 複数ページをまとめて選択・移動・回転・削除
- 別のPDFや、同じサイズの空白ページを挿入
- PDFバージョン、ページレイアウト、綴じ方向を編集
- 閲覧パスワードの設定と解除
- 日本語、英語、ドイツ語、スペイン語、フランス語、韓国語、ポルトガル語、中国語に対応
- Windows（Intel/AMD（x64）版・ARM（arm64）版の両方）、macOS、Ubuntu、Debianで利用可能

## ダウンロード

配布パッケージは [GitHub Releases](https://github.com/tyamada/Folimeld/releases) からダウンロードできます。

| OS | 配布形式 |
| --- | --- |
| Windows 10 / 11（Intel/AMD（x64） / ARM（arm64）） | EXE / MSIX（Microsoft Storeでの公開を準備中） |
| macOS | `.app` (App Storeでの公開を準備中) |
| Ubuntu | `.deb` / `.snap` / 単体実行ファイル（対応バージョンは各リリースを参照） |
| Debian 13 | `.deb`（amd64 / arm64、WSL2で基本動作確認済み） |

> [!NOTE]
> リリースによっては、一部のOS向けパッケージが用意されていない場合があります。

### Ubuntu / Debian版を直接ダウンロード

バージョン **0.3.3 / x86_64（amd64）**：

- [x86_64版debパッケージをダウンロード](releases/ubuntu/folimeld_0.3.3_amd64.deb?raw=true)（Ubuntu 22.04以降 / Debian 13）
- [x86_64版Snapパッケージをダウンロード](releases/ubuntu/folimeld_0.3.3_amd64.snap?raw=true)（snapdが必要）
- [SHA-256チェックサム](releases/ubuntu/folimeld_0.3.3_SHA256SUMS.txt?raw=true)
- [ビルド時のソースと対応記録](releases/ubuntu/source/0.3.3-amd64/)

ダウンロード先のフォルダーで、使用するパッケージのインストールコマンドを実行してください。

```bash
# deb版
sudo apt install ./folimeld_0.3.3_amd64.deb

# Snap版
sudo snap install --dangerous ./folimeld_0.3.3_amd64.snap
```

バージョン **0.3.3 / arm64（AArch64）**：

- [arm64版debパッケージをダウンロード](releases/ubuntu/folimeld_0.3.3_arm64.deb?raw=true)（Ubuntu 22.04以降 / Debian 13）
- [arm64版Snapパッケージをダウンロード](releases/ubuntu/folimeld_0.3.3_arm64.snap?raw=true)（snapdが必要）
- [SHA-256チェックサム](releases/ubuntu/folimeld_0.3.3_SHA256SUMS.txt?raw=true)
- [ビルド時のソースと対応記録](releases/ubuntu/source/0.3.3-arm64/)

```bash
# arm64 deb版
sudo apt install ./folimeld_0.3.3_arm64.deb

# arm64 Snap版
sudo snap install --dangerous ./folimeld_0.3.3_arm64.snap
```

Debian 13ではUbuntu版と同じdebパッケージを使用します。最小構成の環境で `Fontconfig error: Cannot load default config file` が表示される場合は、`sudo apt install fontconfig-config` を実行してください。Debian 13.6のamd64環境（WSL2 / WSLg、X11）でPDFの表示・ページ移動・回転・保存・再読込を確認しています。詳しくは[Debianでの検証記録](docs/debian-wsl-verification.md)を参照してください。arm64環境（WSL2）でもdebのインストールとPDFを指定した起動を確認済みです。

## 基本的な使い方

「ヘルプ → 使い方」またはF1キーで、基本操作・設定・ショートカットを確認できます。ヘルプ画面を開いたままPDFを操作できます。

1. Folimeldを起動し、「ファイル」→「開く」からPDFを選択します。
2. ページをクリックして選択します。複数選択には Ctrl または Shift を使用します。
3. ツールバー、メニュー、またはドラッグ操作でページを編集します。
4. 「保存」または「名前を付けて保存」でPDFを書き出します。

パスワード付きPDFを開くと、閲覧パスワードの入力画面が表示されます。

![Password dialog](docs/screenshots/password-dialog.png)

### 文書設定

「文書のプロパティ」の「詳細」タブでは、PDFバージョンとページレイアウトを変更できます。`TwoPageLeft` または `TwoPageRight` を選択した場合、必要に応じてPDFバージョンが1.5へ引き上げられます。

### 設定の保存

「設定 > 画像サイズ」からサムネイルの長辺のサイズを144 / 288 / 432 pxから選択できます（初期値288 px）。変更はすぐに反映されます。

表示言語、画像サイズ、最後に開いたフォルダーは端末内に保存されます。PDFは端末内で処理されます。Windows MSIX版の応援購入では、商品情報・購入状態の確認と決済にMicrosoft Storeを利用します。PDFをStoreへ送信することはありません。

Windows MSIX版では「ヘルプ → 開発を応援する…」から、サポーターアイコン付きの買い切り商品を購入できます（Storeでの商品公開後）。購入するとヘルプメニューにサポーターアイコンが追加されます。PDF編集機能は購入の有無で変わりません。開発者向けの設定手順は [Windows応援購入](docs/windows-store-purchases.md) を参照してください。

## 開発・コントリビューション

ソースからの実行、テスト、各OS向けパッケージの作成方法は [DEVELOPMENT.md](DEVELOPMENT.md) を参照してください。不具合報告や提案は [Issues](https://github.com/tyamada/Folimeld/issues) で受け付けています。

変更履歴は [CHANGELOG.md](CHANGELOG.md) にまとめています。

## ライセンス

Folimeld は [GNU Affero General Public License v3.0](LICENSE) で公開されています。

PySide6、PyMuPDFなどの第三者ライブラリには、それぞれのライセンスが適用されます。

ライセンス全文と第三者の告知は「ヘルプ → ライセンス」で閲覧できます。
配布時の確認事項は [ライセンスと配布](docs/license-distribution.md) を参照してください。
