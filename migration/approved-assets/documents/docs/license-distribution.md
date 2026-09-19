# ライセンスと配布

Folimeld は AGPL-3.0-only です。`LICENSE` はプロジェクトの告知、
`licenses/AGPL-3.0.txt` は GNU から取得したライセンス全文です。
「ヘルプ → ライセンス」から、これらの文書と第三者ライブラリの告知を閲覧できます。

Windows / Linux / macOS の PyInstaller spec は `tools/license_bundle.py` を使い、
全文・告知・ビルド環境の依存パッケージのバージョンと付属ライセンス・Python の
ライセンスを同梱します。MSIX / deb / Mac App Store パッケージもこの実行物を使います。
ビルド時の文書取得にネットワークは使用しません。

## ビルドごとのソース保存

3つの PyInstaller spec は、ライセンス収集後・Analysis 前に
`tools/source_bundle.py` を呼び出します。通常のビルドコマンドで次を生成します。

- `dist/source/Folimeld-source-<SHA256>.zip`: ビルド時点の Folimeld のファイル。
  Pythonコード、画像、翻訳、ライセンス、ビルドスクリプト、spec、テスト、追跡済みの文書を含みます。
  そのMarkdownから参照する`docs/`内の新規文書・画像も含みます。
  `.git`、仮想環境、ビルド出力、配布バイナリ、`testdata/` は含めません。
  ソース用ディレクトリ内の未追跡ファイルも含むため、公開前にZIPの内容を確認してください。
- ZIP内の `SOURCE-MANIFEST.json`: 各ファイルのSHA256、ビルド元コミット、
  作業ツリー変更の有無、OS・CPU・Python、インストール済みPythonパッケージの正確な版。
  変更がある場合、コミットだけではソースを再現できません。ZIPの内容を基準にします。
- ZIP内の `build-requirements.txt`: そのビルド環境の全Pythonパッケージの固定版一覧。
  実際に同梱されたものだけの一覧ではなく、依存ソース自体でもありません。
- `dist/source/Folimeld-source-<SHA256>.json`: ZIPのSHA256を含む記録。
  同じ記録を実行ファイルの `licenses/Build-source.txt` に埋め込み、ライセンス画面でも表示します。
- `dist/source/<配布物名>-<SHA256>.json`: 実行ファイルとソースZIPの対応記録。
  deb・Snap・MSIX・Mac App Storeのビルドスクリプトは外側のパッケージのハッシュも記録します。

ビルド後にソースが変わっていた場合、対応記録の作成を失敗させます。
同じ作業ディレクトリで複数のビルドを同時に実行しないでください。
署名などで配布物が変わったら、**最終版**について次のコマンドを再実行します。
`--executable` はそのパッケージへ実際に入れたPyInstaller実行ファイルです。

```powershell
.venv\Scripts\python.exe tools/source_bundle.py --executable dist/Folimeld.exe --artifact dist/Folimeld_0.3.2.0_x64.msix
```

このコマンドは埋め込まれた記録とZIPのハッシュを検証します。古い実行ファイルに
現在のソースを後付けで対応付けることはできません。外側のパッケージと指定実行ファイルの
関係はビルドスクリプトから記録するため、公開前にパッケージから取り出した実行ファイルの
SHA256も一致することを確認してください。Macの`.app`はディレクトリなので、
配布するZIP/PKG等を`--artifact`に指定し、`Contents/MacOS/Folimeld`を`--executable`に指定します。

## 保存したソースからのビルド

ZIPを新しいディレクトリに展開し、記録と同じOS・CPU・Pythonで仮想環境を作成します。
`SOURCE-MANIFEST.json`があるため、Gitがない展開先でもspecを実行できます。
通常のビルドスクリプトは依存を取得・更新する場合があるので、保存版を再現する場合は
以下のように固定版を導入してからspecを直接実行してください。

```powershell
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r build-requirements.txt
.venv\Scripts\python.exe tools/write_version_info.py build/version_info.txt
.venv\Scripts\python.exe -m PyInstaller --noconfirm --clean Folimeld.spec
```

Linux/macOSでは仮想環境のPythonを`.venv/bin/python`に読み替え、
`Folimeld-linux.spec` / `Folimeld-mac.spec`を指定します。生成済み画像もZIPに含みます。
OSライブラリ、SDK、署名、ネイティブライブラリのビルド条件は別途必要です。
この一覧はバイト単位で同じバイナリができることを保証するロックファイルではありません。

## 依存ライブラリのソース収集

FolimeldのZIPだけで対応ソース全体が揃ったとは扱いません。
各記録の`dependency_sources`は未収集を明示します。対象のビルド記録または配布物内の
`Installed-packages`から版を確認し、PyPIのソース配布物は次のように取得できます。

```powershell
.venv\Scripts\python.exe tools/fetch_dependency_sources.py PyMuPDF==1.28.2 Pillow==12.3.0 PySide6==6.11.2
```

これは0.3.2 Linux版で確認した版の例です。今後のビルドでは、その記録の版に変更してください。
このツールはソースのビルドコードを実行せずにダウンロードし、PyPIのSHA256と照合します。
取得先URL・版・ハッシュをJSONに保存します。PySide6のようにPyPIにソース配布物が
ない場合は`upstream-source-required`と記録し、Qt公式配布元から別途取得します。

PyMuPDFのソース内`setup.py`が指定するMuPDFの版・ソース取得先も確認してください。
PyMuPDFのソース配布物にMuPDF全体が含まれるとは限りません。
Qt / PySide / Shiboken、MuPDFに内包される第三者コード、Pillowの画像ライブラリ、
PyInstallerのブートローダー等についても実際のバイナリとの対応・変更点・必要な告知を確認します。
Snapの`stage-packages`等はPythonのパッケージ一覧には出ないため、別途扱います。

## 既存0.3.2配布物

調査結果と残作業は [0.3.2 対応ソース調査](source-audit-0.3.2.md) に記録しています。
debとSnapはPythonの版と実行ファイルのハッシュが異なります。同じアプリの版番号だけで
同一のビルド環境・ソースと判断せず、各配布物について確認してください。

## 配布前に必要な確認

- 実行物に対応する Folimeld のソース、ビルドスクリプト、依存バージョンを保存し、
  バイナリのダウンロード場所から取得できるようにしてください。リポジトリの
  トップへのリンクだけでは、対応するソースを提供したことにはなりません。
  この仕組みの出力は`dist/`にありGitには自動追加されません。最終配布物に対応するZIP・
  JSON・確認済み依存ソースをリリースページ等へアップロードし、バイナリの横に
  対応ソースへのリンクを載せて、利用者としてダウンロード・ハッシュ検証してください。
- PyMuPDF / MuPDF の AGPL と Qt / PySide6 の LGPL の条件に従い、実際に同梱した
  バージョンの対応ソース（必要な依存コードや変更を含む）を提供してください。
  LGPL ライブラリを変更したものと組み合わせて再ビルド・実行できる手段も維持します。
- Qt、MuPDF、Python などに内包される第三者コードのライセンスを、対象OSと実際に
  梱包したバイナリに照らして確認し、必要な著作権告知を `licenses/` に追加してください。
  wheel の付属文書の自動収集だけで、内包コードの告知が網羅される保証はありません。
- Store の利用条件、DRM、署名・再インストールの制約が AGPL / LGPL に基づく
  利用者の権利と両立するか、配布経路ごとに確認してください。

今回の表示・同梱修正は、対応ソースの公開や、全OSの最終配布物のライセンス監査を
完了するものではありません。依存関係を更新した場合にも上記の確認が必要です。

## 一次資料

- GNU AGPL v3（第4～6条など）: https://www.gnu.org/licenses/agpl-3.0.html
- GNU LGPL v3（第4条）: https://www.gnu.org/licenses/lgpl-3.0.html
- Qt: https://doc.qt.io/qt-6/licensing.html
- Qt 内の第三者コード: https://doc.qt.io/qt-6/licenses-used-in-qt.html
- PyMuPDF: https://pymupdf.readthedocs.io/en/latest/faq/index.html
- PyWinRT: https://github.com/pywinrt/pywinrt

`licenses/` の GNU ライセンス全文は https://www.gnu.org/licenses/ の各 `.txt`、
`PyWinRT.txt` は PyWinRT v3.2.1 の `LICENSE` から取得しました。
