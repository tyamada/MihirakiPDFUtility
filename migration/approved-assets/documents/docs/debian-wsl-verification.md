# Debian WSL での deb 動作確認

検証日: 2026-09-08

- 環境: Debian GNU/Linux 13.6 (trixie)、WSL2、amd64、WSLg
- 対象: `releases/ubuntu/folimeld_0.3.2_amd64.deb`
- SHA-256: `40206e8ffbe272fa3bd9117ab8be8fb22da62017a03cc52477ed8141ba0e3202`

## 結果

`apt-get install` で依存関係を含めてインストールでき、通常ユーザーで起動できた。Debian 側に Python 開発環境は追加していない。

以下を配布済み deb の実行ファイルで確認した。

- `testdata/TestPDFView.pdf` の４ページのサムネイル表示（検証時はルートに配置）
- ページ移動（元のページ順を 2 → 1 → 3 → 4 に変更）
- ツールバーによる元の１ページ目の90度回転
- 別名保存と保存した PDF の再読込
- 保存結果のページ数・ページ順・回転角度を Windows 側の PyMuPDF で照合
- デスクトップファイル、PDF MIME 宣言、パッケージのインストール状態
- 配布チェックサムとの一致、`dpkg --audit` の指摘なし

検証用出力は `build/debian-smoke-saved.pdf`。元の PDF は変更していない。

## 起動時の警告と制限

- 最小構成の Debian では `Fontconfig error: Cannot load default config file` が出た。GUI 検証用に `xdotool` と `x11-apps` を追加した際、依存関係として `fontconfig-config` などが入り、この警告は解消した。現在の deb には Fontconfig 設定の明示的な依存宣言がない。
- Qt の Wayland プラグイン読み込み警告が出るが、X11 にフォールバックして起動・編集・保存できた。Wayland ネイティブ動作は未確認。
- `fitz` API の非推奨警告が出るが、今回の操作には影響しなかった。
- パスワード、挿入・削除、全言語、OS の「プログラムから開く」、アンインストールは今回の確認範囲外。

deb と検証用 X11 ツールは Debian にインストールした状態で残している。配布パッケージ自体は変更していない。
