# Windows 応援購入

Windows MSIX版の「ヘルプ → 開発を応援する…」から、Microsoft Storeの購入画面を開きます。
非消耗型商品を購入すると、Storeライセンス確認後にメニューがサポーターアイコン付き「サポーター…」になります。
通常EXE・macOS・Linuxではこの購入入口を表示しません。サイドロードMSIXでも入口は表示されますが、
Storeの商品情報を取得できない限り購入できません。PDF編集機能に購入制限はありません。

## Partner Center

### ローカルMSIXの署名

リポジトリルートで実行します。最新MSIXを指定してください。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\sign_dev_msix.ps1 -PackagePath .\dist\Folimeld_0.3.2.0_x64.msix
```

マニフェストのPublisherに一致する有効期間1年の開発用証明書を作成し、署名済みコピーを
`build/dev-signing/` に出力します。元のMSIXは変更しません。
秘密鍵はエクスポート不可として現在のユーザーの個人証明書ストアに保管します。
同じ証明書は次回も再利用します。信頼登録は自動では行いません。
`-ExecutionPolicy Bypass` はこのPowerShellプロセスにのみ適用され、PCの実行ポリシーは変更しません。

表示された証明書の拇印を確認し、**管理者PowerShell**で公開証明書を登録します。
以下はリポジトリルートを作業ディレクトリとした例です。

```powershell
Import-Certificate -FilePath .\build\dev-signing\Folimeld-dev.cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople
```

その後、`build/dev-signing/*.dev-signed.msix` を開いてインストールします。
これはローカル検証用です。Store公開用には元の未署名MSIXを提出します。
証明書を信頼してもStoreの商品登録や購入テスト環境の関連付けは完了しません。

### 商品登録

1. Folimeldに有効期限なしの **Durable** アドオンを作成。
2. 開発者指定のProduct IDを **folimeld.supporter** に設定。
   これはMicrosoftが発行するStore IDとは異なります。既存の商品IDを使う場合は
   `folimeld/store_support.py` の `OFFER_TOKEN` を変更します。
3. 価格、各言語の説明、購入前プレビューを登録。
   「買い切りでヘルプメニューにサポーターアイコンが追加される」と説明します。
4. アプリのMSIX Identity/PublisherをPartner Centerに関連付け、アプリとアドオンを提出。
5. Microsoftの課金テスト手順に従い、Store経由でインストールした関連付け済みアプリで検証。

## 実装と検証

依存はrequirements.txtにWindows限定で指定。WindowsのPyInstaller specにはWinRTの
Foundation/Collectionsも明示的に含めます。StoreContextへQtのメインウィンドウのHWNDを渡し、
WinRT非同期操作をQtタイマーで監視するため、購入待ちの間も画面は応答します。
商品情報が得られるまで購入ボタンは無効です。価格はStoreのformatted_priceを表示します。
購入状態は設定ファイルに保存せず、起動時・ダイアログ表示時・購入後・再確認ボタンで照会します。
返金の反映はこれらの再確認時です。オフラインではStoreが返すキャッシュに従います。
通信失敗だけで既知の購入権利を削除しません。

自動テストは偽のStore応答で成功、キャンセル、障害、重複クリック、権利取り消し、価格表示を確認します。
実Storeでの商品取得・購入・別端末復元・返金・オフライン・MSIX同梱の確認は別途必要です。
この開発環境ではPartner Centerの設定や実課金は実施していません。

公式資料：https://learn.microsoft.com/en-us/windows/uwp/monetize/in-app-purchases-and-trials
