# 開発進捗

更新: 2026-10-24
基準HEAD: 386ec36 Add downloadable sample PDFs

## 作業開始時の既存変更

ANDROID_PARITY_DEVELOPMENT_PLAN.md、LOCALIZATION_PROGRESS.md、project.pbxproj、AppVersionInfo.swift、ContentView.swift、Localizable.xcstrings、MihirakiPDFUtility-InfoPlist.xcstringsに既存差分あり。保持する。

## 現在の単位

- S00: 現在のXcode選択先で変更前ビルド成功、既存113テスト全件成功（失敗/スキップ0）。他OSの基準確認は未実施。
- G01: 完了。実装・ビルド成功。iPhone Duo Simulator / iOS 27.1で設定→診断→ログ/性能テスト、閉じる、旧診断セクション削除を操作確認済み。
- G02: 完了。実装/ビルド/対象テスト5件成功。iPhone Duoで一括実行・再実行・ミリ秒表示・既存リンク確認済み。
- H01: 完了。専用領域・終了時削除・起動時回収、対象11テスト成功。
- H02: 完了。容量判定4テスト成功。H03で実容量取得・生成へ接続済み。
- H03: 完了。対象23テスト成功、iPhone Duoで一括3件成功・再実行確認済み。
- G03: 完了。対象28テスト成功。iPhone Duoで画面再表示・プロセス再起動後の結果復元を確認。
- G04: 完了。対象32テスト成功。Duoで両形式の共有表示/キャンセル/コピー/削除と再起動後の削除維持を確認。
- H04a1: 完了。対象37テスト成功。Duoで一括5件成功・再実行・共有JSONを確認。
- H04a2: 完了。対象46ケース成功（2回に分けて検証）。Duoで一括8件成功・再実行・JSON確認。
- H04b1: 完了。対象テスト成功、Duoで一括10件成功/再実行/JSON確認。
- H04b2: 完了。対象39テスト成功、Duoで一括12件/再実行/JSON確認。
- H05a: 完了。対象39テスト成功、Duoで一括15件/再実行/工程時間/JSON確認。
- H05b1: 完了。対象42テスト成功。Duoで一括16件/再実行/ランダム編集詳細/JSON確認。
- H05b2a: 完了。対象45テスト成功。Duoで一括17件/再実行/画像負荷詳細/JSON確認。
- H05b2b1: 完了。49テスト成功。Duoで17件成功、回収時間のText/JSONと再起動復元を確認。
- H05b2b2a: 完了。52テスト成功、Duoで一括17件/再実行/共有JSON確認。
- H05b2b2b: 完了。56テスト成功、Duoで17件/再実行/チェックサム/JSON確認。
- H05b2c: 完了。59テスト成功、Duoで17件/削除計測共有/再起動復元確認。表示調整後の対象10テスト成功。
- H06a: 完了。61テスト成功、Duoで18件/再実行/共有JSON/通常ログ最新記録を確認。
- H06b: 完了。診断/画像取込71テスト成功、Duoで19件/再実行/新ケース詳細/JSON確認。
- その他: 未着手。

変更前ビルドログ:
`/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261021-110220.txt`

次の操作: F01c完了。次はF01dとしてリスト/見開き・プレビューのサイズ遷移確認。Duoの折りたたみ/実サイズ遷移とiPad/Macは引き続き未検証。

## 今回の変更

- DiagnosticsView.swiftを追加（ログ閲覧・既存性能テストへのリンク、閉じる操作）。
- ContentView.swiftに診断メニューとsheetを追加。バージョン情報から診断セクションを削除。ヘルプの誘導先を修正。
- 一括実行・共有・容量管理・PDF生成は今後の単位で実装する。
- 新しいヘルプ文の各言語翻訳は未実施。既存カタログの翻訳作業は維持。

変更後ビルド: 成功、エラー0。
ログ: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261021-150823.txt`
既存テスト結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunAllTests/4CE83D76-7364-4434-A0AC-38197EDEC0C6.txt`

再開時: git差分とこの記録の末尾を確認し、未完了の確認またはH05bへ進む。

## G01画面検証結果

iPhone Duo Simulator / iOS 27.1、日本語UI。設定→診断→ログ、戻る、既存性能テスト実行、結果表示、完了で閉じる、バージョン情報からの診断削除を確認。クラッシュ/新規画面の表示崩れなし。CPU 223 ms、メモリ5 ms、PDF 29 ms（100ページ/38 KB）はSimulator参考値。セッション終了済み。

証跡ディレクトリ:
`/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/DeviceInteractionSynthesize/`
画面: `Verify Diagnostics Navigation-15_09_22_046-screenshot.png`、ログ: `Verify Diagnostics Navigation-15_09_35_327-screenshot.png`、結果: `Verify Diagnostics Navigation-15_10_14_432-screenshot.png`、バージョン: `Verify Diagnostics Navigation-15_10_34_428-screenshot.png`。

未検証: Mac/iPadでの画面操作、Duo折りたたみ遷移全体。既存のバージョン情報のアプリ名はこの幅で省略表示されるためFのレイアウト確認候補とする。今回の変更範囲外として未修正。

## G02実装・検証

DiagnosticsRunner.swiftに結果状態/結果/レポート/台帳とMainActorのObservable実行管理を追加。CPU/メモリは既存PerformanceTestRunnerを再利用し、バックグラウンドで直列に計測。計測結果にチェックサムを追加し既知値と照合する。診断画面にRun All Tests・対象範囲の説明・結果件数/詳細を追加。実行中は再実行と閉じる操作、旧性能テストの開始を無効化する。

対象テスト5件成功: 内蔵2ケース、検証不一致/例外後の継続、直列順、二重起動防止/再実行時置換、キャンセル後の未実行分類、既存性能レポート回帰。全件再実行はしていない。
ビルドログ: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261021-151412.txt`
テスト結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/1EC4F679-52A1-4898-8EB2-1A2A7CD3E19D.txt`

制限: 台帳はCPU/メモリ2件のみ。既存PDF性能テストは従来の別画面から利用可能。PDF統合・共有・永続結果・UIからの中止・バックグラウンド移行対応は後続工程。今回の新規UI文言はローカライズ可能なキーで追加したが翻訳は未実施。結果型は今後PDF検証向けに拡張する。

G02画面確認（iPhone Duo / iOS 27.1）: Run All Testsと再実行で成功2/失敗0、CPU/メモリの各1行、重複なしを確認。秒未満の計測が0表示になる問題を検出したためミリ秒表示へ修正し、再ビルド成功。新規文言は日本語UIでも英語（翻訳工程待ち）。
修正後ビルドログ: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261021-151526.txt`

最終確認: CPU 243 ms、メモリ5 msの表示、旧ログ/性能テストへの遷移も成功。Simulatorセッション終了済み。
画面証跡（上記DeviceInteractionSynthesizeディレクトリ）: `Verify Diagnostics Runner-15_16_03_295-screenshot.png`（概要）、`Verify Diagnostics Runner-15_16_04_545-screenshot.png`（詳細）。

## H01実装・検証

DiagnosticWorkspace actorを追加。アプリ専用tmp/MihirakiDiagnosticRuns配下のUUIDディレクトリを実行記録兼作業領域として使用。共有actorがアプリ内の全ウインドウの実行領域を管理し、実行中IDは回収対象から除外する。起動時と次回開始前に残存領域を回収。Runnerは正常/検証失敗/キャンセル後にも後始末を待ってレポートを確定する。準備失敗時はケースを未実行、削除失敗時はcleanup失敗として記録し次回再試行。起動時の回収失敗は個人情報を含めず診断ログへ記録。

対象11テスト成功（新規7、Runner回帰4）。正常/失敗/キャンセル時削除、再起動相当の回収、実行中領域と無関係ファイルの保護、OSによる先行消去、シンボリックリンク非追跡、準備失敗、削除失敗と再試行を確認。初回はリンク置換時のエラー型不一致1件を検出し、ルートの属性確認を修正して全件再検証した。

ビルド成功: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261021-212905.txt`
テスト結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/6B392E7E-FDEA-4B07-80E8-B9D4DF167A96.txt`

制限: テストPDF生成・容量判定は未実装。異常終了回収は新しい管理インスタンスで再起動を模擬した検証であり、実機強制終了の操作検証は未実施。複数プロセスが同じルートを共有する用途は対象外（製品ではsharedを使用）。今回UI構造は変更していない。新しい失敗メッセージの翻訳は後続工程。

## H02実装・検証

DiagnosticStorageBudget.swiftに純粋な容量判定を追加。安全余裕512 MiB、上限512 MiB、空き容量10%の最小値で予算計算。暫定ピーク見積もり128/32/4 MiBに安全係数2を適用し、標準（12/100/500/1100ページ＋画像負荷）、縮小（12/100）、最小（12）、生成中止を選択する。生成器の実測に基づく値の校正はH03/H05で実施する。

容量不明(nil)と0を区別し、負値は不明として扱う。再確認では既存使用量を元予算から差し引き、追加書込みが現在の空き容量予算も超えないか判定。整数オーバーフローを避ける比較を採用。

ビルド成功、対象4テストすべて成功: 容量不明/0/安全余裕以下、各プロファイル境界±1バイト、予算上限/異常値、途中容量減少/既存領域使用による中止。
ビルドログ: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261021-213052.txt`
テスト結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/B6A8398D-7AFA-4776-B627-C9CCA3381B62.txt`

重要: 今回は容量値を入力とする判定ロジックのみ。端末ボリュームの容量取得・フォールバック・PDF生成前/途中の呼出し・スキップ理由の結果接続はH03で実装する。まだ実際の生成を制御しているわけではない。容量API利用時のPrivacy ManifestはApple公式資料で用途に合う理由を確認し同時追加する。容量値を共有レポートへ含める可否も承認理由の制約に合わせて確認する。画面変更なし。

## H03実装・検証

DiagnosticStorageCapacityで作業ディレクトリのボリューム容量を取得。非必須データ用のopportunistic容量を優先し、未取得/例外/負値の場合のみ通常容量へフォールバックする。0は有効な値として保持し、各取得でURLリソースキャッシュを破棄する。

DiagnosticPDFTest actorで12ページの図形PDFを専用ディレクトリに生成。ページごとに寸法を変え、生成物の読込・PDFKitによる別ファイルへの保存・再読込で全ページ数と寸法を照合。開始前、ページごと、再保存前に容量を再確認する。入力/出力の実サイズは各2 MiB未満を検証し、合計4 MiBの保守的なピーク見積もりを維持する。容量不明/不足/途中変化は理由付きスキップ、実処理の失敗は失敗として一括診断に記録。CPU/メモリ/PDFの3項目が対象になった。正常・スキップ・キャンセル・失敗後の削除は既存Workspaceが担当する。

ビルド成功、対象23テスト成功（新規PDF/容量取得8ケース、Runner/Workspace/容量予算15ケース）。最小容量プロファイル境界で生成可能、容量不明/0/不足で未作成、途中の容量減少/キャンセルで部分ファイルを削除、正常後削除、既存診断回帰を確認。新規の容量関連異常は注入値による検証であり、実端末を容量不足にする試験は未実施。
ビルドログ: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261021-213711.txt`
テスト結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/65E8B2A8-C6A5-4304-B24A-802272F9FAFD.txt`

PrivacyInfo.xcprivacyを追加し、DiskSpace / E174.1を宣言。アプリバンドルへのコピーをビルドログで確認済み。これはファイル書込み可否の判定用途。容量値とその派生情報は端末外へ送信できないため、現段階ではローカル表示のみ。G04の共有では容量由来の結果/理由も扱いを再確認し、ユーザーが内容を確認して任意送信する不具合報告として7D9E.1の条件を満たす設計と宣言を検討する。単なる数値の削除だけで制約対応済みとしない。
公式根拠: https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons

制限: 今回の生成対象は12ページのみ。大容量の種類選択/負荷テストはH05、編集機能の結果照合はH04、UI中止・経過表示・部分結果永続化はG03、共有はG04。新規文言の翻訳は後続工程。Mac/iPadの実行、Duo折りたたみ遷移全体は未検証。

H03画面確認: iPhone Duo Simulator / iOS 27.1で設定→診断→Run All Testsを実行し、成功3/失敗0/スキップ0を確認。PDF生成・保存・再読込の説明と2 msの所要時間を表示（Simulator参考値）。再実行でも3件のみで重複なし、画面崩れなし。セッション終了済み。
証跡: 上記DeviceInteractionSynthesizeディレクトリの `Verify Generated PDF Diagnostics-21_38_13_084-screenshot.png`（集計）、`Verify Generated PDF Diagnostics-21_38_14_316-screenshot.png`（詳細）。

H03完了。次はG03。未コミット差分を維持して再開し、翻訳作業の差分を上書きしない。

## G03実装・検証

DiagnosticsRunnerをAppのStateで所有し環境経由で診断画面へ渡す。画面を閉じて開き直しても結果を保持し、複数ウインドウから同じ実行を重複起動しない。実行タスクを管理しCancel Testsボタンからキャンセル要求を送る。App全体がbackgroundになった場合も同じ経路で中止を要求する。処理終了・一時ファイル削除を待ってから次回実行可能にする。

診断画面に完了件数/総件数のプログレスバー、現在テスト、経過秒、対象ケースの状態一覧、中止待ち表示を追加。DiagnosticReportStoreは開始前・各ケース終了時・後始末完了時に最新1件のJSONをApplication Support/DiagnosticReports/latest.jsonへatomic保存する。PDF用tmpと分離し、バックアップ対象から除外。保存形式にバージョンと日時、状態、計測時間、結果説明を保持。タイトル/説明は実行時の言語で保存する。

次回起動時に未完了記録があれば中断メッセージと保存済み結果を復元し、結果が未確定のケースは未実行として表示する。自動再実行しない。生成PDFは既存の起動時回収で削除する。結果保存/復元失敗はUIで通知し、実行結果はメモリに保持する。破損データ、1 MiBを超えるデータ、未対応バージョンを復元しない。

ビルド成功、対象28テスト成功（新規5＋既存23）。完了結果の復元、開始前の記録、途中結果の復元、中止時の後続未実行、次回実行時のリセット、破損からの回復、保存失敗時の結果保持を確認。最初のテストビルドで#require内のtry不足を修正後に成功。
ビルドログ: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261021-214337.txt`
テスト結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/445F56F7-4397-468F-8F02-9F39CBB7C744.txt`

制限: CPU/メモリの既存の短い同期計測は完了を待って中止を反映する。PDF生成はページ境界で中止する。OSが即座にプロセスを停止した場合の後始末は次回起動時、途中結果は最後の保存済みチェックポイントまで。異常終了復元/キャンセルはゲートを用いた単体テストで検証。新規文言の翻訳、Mac/iPad実行、Duo折りたたみ遷移全体は未検証。共有はG04で実装する。

G03画面確認（中断前の検証結果を2026-10-22に記録）: iPhone Duo Simulator / iOS 27.1で成功3/失敗0/スキップ0。Doneで閉じて再表示した場合も結果を保持。プロセス再起動（PID 82272→82356）後もCPU 226 msを含む結果を復元。再実行で3件のみ、重複なし、表示崩れなし。セッション終了済み。
証跡: 上記DeviceInteractionSynthesizeディレクトリの `Verify Persistent Diagnostics-21_44_48_090-screenshot.png`（画面再表示）、`Verify Persistent Diagnostics-21_45_08_223-screenshot.png`（再起動後）、`Verify Persistent Diagnostics-21_45_22_221-screenshot.png`（再実行）。
実行が短いため、進捗・経過秒・中止ボタン操作はSimulatorのUI上では未検証。中止と部分結果保存は単体テストで確認済み。バックグラウンド移行中の中止、強制終了の操作検証は後続の長時間テスト追加時に確認する。

G03完了。次はG04。既存差分を保持し、共有前プレビュー、テキスト/JSON、容量由来情報の共有条件を確認して進める。

## G04実装・検証

DiagnosticReportExportに値型のレポート変換を追加。UTF-8テキスト/JSONで全結果状態・日時・中断有無・計測時間・説明を出力する。新規実行はアプリ版/ビルド、OS、プラットフォーム区分、Simulator有無、テスト定義版を実行時に取得・保存する。旧チェックポイントは環境情報なしで復元でき、共有時の環境を実行時の情報と誤表示しない。UIDevice.name/ホスト名/ユーザー文書/パスワード/フルパスは追加しない。

結果画面のReview and Share Reportから内容確認画面へ遷移。JSON切替、全内容プレビュー、ShareLink、コピーを追加。共有は不具合調査/対応のための任意提出と説明し、容量由来のスキップ理由も含まれる可能性を目立つ位置に表示。Appleの7D9E.1の条件を確認しDiskSpace利用理由へ追加。自動送信は実装しない。旧性能テストの説明/回帰テストを自動送信しない表現へ更新（通常ログの別画面には共有を追加していない）。

共有用DataRepresentationはレポートのメモリ上のコピーを渡す。アプリ管理の共有用一時ファイルは作らず、転送データの寿命はOSへ委譲するため、生成PDF削除や保存レポート削除に依存しない。保存済み最新結果の削除操作を追加。生成PDFは共有しない。

ビルド成功、対象32テスト成功（新規3、既存診断28、性能レポート回帰1）。全5状態/日本語/引用符/改行のJSON往復、1.5 msの精度、旧保存形式、PDF生成物回収後のエクスポート、保存結果削除後の共有スナップショット維持を確認。
ビルドログ: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261022-073410.txt`
テスト結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/18CA9B9F-0A7F-4C9D-8D92-78D4CE534420.txt`

制限: Mac/iPadの共有UI、外部アプリへの送信完了は未検証。新規文字列は翻訳待ち。現在はCPU/メモリ/12ページPDFの3ケースで、容量の生値、生成seed、処理工程別の詳細計測は未記録。後続H04〜H06でテスト内容とレポートを拡張する。

G04画面検証の再開記録: 前回の中断前にiPhone Duoで3件成功後、Textプレビュー、Copy Reportのコピー済み表示、Text/JSON両方の共有ポップオーバーを確認済み。外部送信なし。共有シートの表題はDiagnostic Bug Reportで拡張子/型は表示されなかった。利用制限でJSONプレビュー・共有キャンセル後の結果保持・保存結果削除・セッション終了の最終報告が未完了だったため、この範囲を再開している。コード変更はなく、成功済みの32テストは再実行していない。

G04画面検証完了: iPhone Duo / iOS 27.1。Text/JSONプレビュー、両形式の共有ポップオーバー表示とキャンセル、コピー済み表示、戻った後の成功3件保持を確認。Delete Saved Reportで結果・共有/削除ボタンが消え、アプリ再起動後も結果なし。表示崩れなし。外部送信は行っていない。旧セッションは終了済み、新規検証セッションも終了済み。
証跡（上記DeviceInteractionSynthesizeディレクトリ）: `Verify Diagnostic Sharing-07_35_45_933-screenshot.png`（Text）、`Verify Diagnostic Sharing-07_36_15_029-screenshot.png`（JSON）、`Verify Diagnostic Sharing-07_36_25_827-screenshot.png`（削除直後）、`Verify Deleted Diagnostic Report-16_08_39_448-screenshot.png`（再起動後）。共有シートUIにはDiagnostic Bug Reportのみ表示され、ファイル名/型はUIでは未確認。形式はコードとJSON往復テストで確認済み。

G04完了。次はH04a。今回の再開ではコード変更なし、対象32テストの成功結果を維持。

## H04a1実装・検証

H04aを2単位へ分割し、今回は回転/移動を追加。DiagnosticEditingCheckが各ケース専用サブディレクトリに容量確認付き12ページPDFを生成し、独立したPDFEditorModelで操作する。回転はページ2/5だけを-90度回転して270度に正規化されること、他10ページは0度、全幅順序/選択を保持することを照合。移動は同じ2ページを先頭/末尾へ移し、全12ページの順序と選択保持を照合する。結果説明に期待した操作と検証項目を記録する。

PDFEditorModelへrecordsDiagnostics引数（既定true）を追加。診断専用モデルではfalseとし通常の操作ログへ混在させない。編集モデルはMainActor上で操作し、PDFKitのモデルを並列共有しない。各ケース終了時に専用PDFを削除、削除失敗時はRunnerの領域全体削除へ引き継ぐ。既存CPU/メモリ/PDFと合わせ一括5件。テスト定義版を2へ更新。

ビルド成功、対象37テスト成功（新規4、既存診断31、編集回帰2）。正常結果、容量不足スキップ、領域削除、独立したユーザー用モデルのページ/選択/回転/Undoを保持することを確認。
ビルドログ: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261022-161941.txt`
テスト結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/9108C967-723B-4875-9A17-79C9353FC6EB.txt`

制限: 検証はページ寸法・順序・回転・選択・変更フラグ。ピクセル内容や編集後再保存は未照合（保存/履歴はH04b）。ケース所要時間はモデル読込/生成を除いた編集と照合の時間。H04a2で削除/複製/空白挿入を追加予定。新規文言の翻訳は後続。

H04a1画面検証成功: iPhone Duo / iOS 27.1。一括実行/再実行とも成功5/失敗0/スキップ0。追加2件の説明と計測値、JSON全5件の一意IDとtestDefinitionVersion 2を確認。表示崩れなし、外部送信なし。セッション終了済み。
証跡: 上記DeviceInteractionSynthesizeディレクトリの `Verify PDF Editing Diagnostics-16_20_37_941-screenshot.png`（再実行集計）、`Verify PDF Editing Diagnostics-16_20_47_928-screenshot.png`（追加詳細）、`Verify PDF Editing Diagnostics-16_21_06_250-hierarchy.txt`（JSON）。
計測参考値: 回転0.731083 ms、移動1.274041 ms。既存結果UIは整数msのため回転は0 ms表示、JSONには小数値を保持する。
H04a1完了。H04a全体は未完了で、次はH04a2。

## H04a2実装・検証

削除/複製/空白挿入の内蔵3ケースを追加し、一括8件・テスト定義版3へ更新。削除は選択2ページを除いた10ページの順序/最近傍選択と全ページ削除防止を検証。複製は14ページの順序・複製ページ選択・90/270度回転・元と複製の描画一致を検証。空白は前/後を別モデルで実行し、14ページの順序・寸法・回転・選択、挿入ページの白描画と元ページの描画維持を検証する。

描画照合は128×128のグレースケールbitmapで実施。生成した単純図形のテスト専用であり、任意PDFの見た目同一性や内容の完全検証を保証しない。複製元に暗いピクセルがあることも確認し、描画が全て白になっただけの偽陽性を防止する。

ビルド成功。初回は&&中のthrow式のtry位置を修正。回帰実行38件成功後、パラメーター化テストがmovementの1種類だけになっていることをコンソールで検出。識別しやすいrawValue文字列を引数へ渡す形に修正し、5種類×正常/容量不足の10ケースを再実行、全件成功。重複分を除く検証対象は46ケース（既存/一括/保存等36＋編集10）。一括ケース自身も8件成功を検証済み。
ビルドログ: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261022-162713.txt`
回帰結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/8F2D9894-8CEA-4D75-8EFA-7D6DDFF07EF6.txt`
全編集引数結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/059113F5-D182-4453-9DCB-5338F2D5265D.txt`

制限: 保存後再読込・属性・暗号化・Undo/Redoの内蔵診断はH04b。空白挿入ケースの計測は2つのモデル読込と描画照合を含むため純粋な編集時間ではない。新規翻訳/Mac/iPad/折りたたみ遷移全体の検証は後続。

H04a2画面検証成功: iPhone Duo / iOS 27.1。一括/再実行とも成功8/失敗0/スキップ0。新3件の説明/時間、JSONの8個の一意IDとtestDefinitionVersion 3を確認。重複/表示崩れなし、外部送信なし、セッション終了済み。
証跡: 上記DeviceInteractionSynthesizeディレクトリの `Verify Eight Diagnostics-16_28_09_045-screenshot.png`（集計）、`Verify Eight Diagnostics-16_28_23_746-screenshot.png`（新3件）、`Verify Eight Diagnostics-16_28_58_345-hierarchy.txt`（JSON）。Simulator参考値: 削除0.740625 ms、複製1.594292 ms、空白8.729458 ms。整数ms表示とJSON小数値の仕様は既存どおり。
H04a2完了、H04a全体完了。次はH04bを小分けに進める。

## H04b1実装・検証

保存/再読込とUndo/Redoの2ケースを追加。一括10件、定義版4。保存は選択2ページを90度回転して先頭へ移動後、既存exportDocumentでデータ化、容量再確認後に専用領域へatomic書込み、didExportと別モデルでの再読込を実行。12ページの順序/回転/描画、変更フラグ解除と新規モデルの選択初期化を照合する。保存直前は既存生成物の実サイズと追加書込み見積もりを初期予算/現在容量に照合する。

履歴は回転/移動後にUndoを2回、Redoを2回実行し、途中および最終の順序/回転/描画/選択/変更フラグ/canUndo/canRedoを照合。診断用モデル・一時領域は引き続き独立し、通常操作ログへ記録しない。

ビルド成功。回帰43件成功（全7種類の正常ケースを含む）。容量不足のパラメーター指定がrotationだけになるツール側の選択現象を再確認したため、そのテストは全7種類を内部ループする1ケースへ変更し、別途成功。保存直前の容量減少→スキップ/削除も成功。単純合算でケース数を水増ししない。
ビルドログ: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261022-163203.txt`
回帰結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/9D91616A-6A66-4CA1-861B-52BD051BE7DD.txt`
全容量不足検証: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/30A8B951-D73C-4246-96CA-3B3A52A146A2.txt`

制限: 属性/暗号化はH04b2。計測時間には描画照合等が含まれ、純粋な保存や編集性能の比較用ではない。OSのファイルピッカーを介する保存UIはこのケースの対象外。翻訳/Mac/iPad/折りたたみ遷移全体は後続。

H04b1画面確認成功: iPhone Duo / iOS 27.1。一括実行/再実行とも成功10/失敗0/スキップ0。保存再読込4 ms、Undo/Redo7 msと説明を表示。JSONに10個の一意ID、全件passed、testDefinitionVersion 4を確認。重複/表示崩れなし、外部送信なし。セッション終了済み。
証跡: 上記DeviceInteractionSynthesizeディレクトリの `Verify Ten Diagnostics-16_32_54_781-screenshot.png`（集計）、`Verify Ten Diagnostics-16_33_10_542-screenshot.png`（新2件）、`Verify Ten Diagnostics-16_33_40_344-hierarchy.txt`（JSON）。
H04b1完了。次はH04b2。H04b全体は属性/暗号化が未完了。

## H04b2実装・検証

文書属性とパスワード保護の2ケースを追加し一括12件・定義版5。属性は日本語を含むタイトル/作者/件名/キーワード、右→左読み/2列左レイアウトを設定し、容量確認後の書出しと別モデルでの再読込で照合する。ページ数/幅順序も保持を検証。

パスワードはテスト専用の固定値を設定し書出し、暗号化/ロック状態、誤った値の拒否、正しい値で解除後の12ページ寸法/描画一致を検証。その後に保護設定を外して別ファイルへ書出し、暗号化解除と12ページを確認する。各書出し直前に初期予算・既存実サイズ・現在容量を照合する。パスワード値とフルパスはレポートへ含めず、診断モデルの通常ログ記録も無効。

ビルド成功、対象39テスト成功。編集の正常時/容量不足時はそれぞれ1テスト内で全9種類をループし、引数選択の一部実行を回避する形へ統一。保護解除用書出し直前の容量減少→スキップ/削除、テキスト/JSONにテストパスワードと作業パスがないことも検証。テスト件数はループ内の種類を個別カウントしていない。
ビルドログ: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261022-164446.txt`
テスト結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/A6A21EED-8679-41CA-8592-B9E54706DFA7.txt`

制限: PDFKit/既存書出しの動作照合であり暗号アルゴリズムの監査ではない。属性ケースは右→左/2列左の代表値で、全レイアウトの組合せは既存開発テストで扱う。保護解除はテストモデルの出力設定を外す操作で、インポート済み他社PDFの全保護形式を網羅しない。計測は検証処理込み。翻訳/Mac/iPad/折りたたみ遷移全体は後続。

H04b2画面検証成功: iPhone Duo / iOS 27.1。一括/再実行とも成功12/失敗0/スキップ0。属性2 ms、パスワード保護5 msと各検証説明を表示。JSONに12個の一意ID、全件passed、testDefinitionVersion 5。具体的なパスワード値は表示されない。重複/表示崩れなし、外部送信なし、セッション終了済み。
証跡: 上記DeviceInteractionSynthesizeディレクトリの `Verify Twelve Diagnostics-16_45_32_138-screenshot.png`（集計）、`Verify Twelve Diagnostics-16_45_45_153-screenshot.png`（新2件）、`Verify Twelve Diagnostics-16_46_15_626-hierarchy.txt`（JSON）。
H04b2完了、H04全体完了。次はH05を小分けに進める。

## H05a実装・検証

DiagnosticPDFTestを12/100/500/1100ページ対応へ拡張。100/500/1100の3ケースを直列台帳へ追加し、一括15件・定義版6。事前容量計画により標準は全3種類、縮小は100のみ、最小では大容量3件を理由付きスキップ。各ページ前/書出し前に容量と実使用量を確認し、ページ境界でキャンセルする。ケース専用ディレクトリは終了時削除し、失敗時はRunnerの回収へ引き継ぐ。

生成、読込＋全ページ寸法検証、書出し、再読込＋検証を別々に計測。入力/出力バイト数と3桁小数msを結果説明に含め、共有JSONのdetailにも残す。正しさのみ合否判定し、速度に全機種共通閾値を置かない。数値は現状文字列として記録し、機械処理向け専用メトリクス項目は未追加。図形と寸法は12ページ周期、PDF全体のページ数/全寸法を照合。

ビルド・対象39テスト成功。3規模の生成/計測、プロファイル別の実行/スキップ、途中容量減少/キャンセル後の削除、既存12ページ生成と全編集/保存/共有の回帰を検証。編集ツールのreplaceAllが挿入文中の同じ文も再置換し重複宣言を生成したため一度ビルド失敗。対象ファイルを正しい132行の内容へ書き直してビルド/テスト成功を確認済み。
ビルドログ: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/BuildProject/BuildProject-Log-20261022-165056.txt`
テスト結果: `/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A/RunSomeTests/8278FADC-20CE-4798-BC22-E99A88137C94.txt`

実サイズ参考: 100ページ入力40,965/出力41,361 bytes、500ページ入力199,423/出力201,379 bytes、1100ページ入力439,865/出力444,221 bytes。全3規模とも入力＋出力4 MiB未満をテストで確認。既存32/128 MiBの予算見積もりは画像負荷などへの余裕を残して維持し、今回の小型図形PDFの実サイズだけで緩和しない。

制限: 1100ページも単純図形で、画像多用PDFの負荷とは異なる。PDFKitの同期write中は強制停止せず、戻った時点でキャンセルを処理する。後始末時間、温度/メモリ制御、ランダム編集、画像負荷はH05b以降。容量不明/低容量は注入試験。Mac/iPad/実機性能・翻訳は後続。

H05a画面検証成功: iPhone Duo / iOS 27.1。一括/再実行とも成功15/失敗0/スキップ0。3規模の工程別時間・サイズ表示とJSON15個の一意ID/testDefinitionVersion 6を確認。進捗13/15・経過0秒・Cancel Testsの表示を観測できたが中止操作は短時間のため未検証。表示崩れ/重複なし、外部送信なし、セッション終了済み。
Simulator参考値（生成/読込検証/書出し/再読込検証ms）: 100ページ24.618/1.933/2.405/2.668、500ページ133.608/12.469/6.337/12.593、1100ページ258.885/41.522/15.824/41.858。
証跡: 上記DeviceInteractionSynthesizeディレクトリの `Verify Stress Diagnostics-16_52_12_782-screenshot.png`（集計）、`Verify Stress Diagnostics-16_52_29_728-screenshot.png`（詳細）、`Verify Stress Diagnostics-16_53_00_301-hierarchy.txt`（JSON）。
H05a完了。次はH05bを小分けに進める。


## H05b1実装・検証

固定シード20261022で64回の回転・前方移動・複製・削除を実行するランダム編集診断を追加。独立した値配列モデルと各操作後のページ順序・サイズ・回転・選択位置を比較し、保存・再読み込み後も照合する。初期12ページ、最大24ページ。実行ごとに専用PDFを生成し、終了時に削除する。8操作ごとの容量確認、操作間のキャンセル確認、保存前の容量確認を実施。一括診断は16ケース、共有レポートのtestDefinitionVersionは7。

再現用シードは地域設定で整形されない文字列として記録する。初回検証では数値整形による文字列照合失敗2件があり、修正後に診断関連42テストすべて成功（失敗/スキップ0）。100シードの計画上限、4シードで実編集・保存・再読み込み・後始末、容量低下/キャンセルの後始末を検証。

ビルド成功: BuildProject/BuildProject-Log-20261022-220616.txt
テスト結果: RunSomeTests/9157AC18-E73E-40FE-B9C4-B5A513BE0314.txt
（既出ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A以下）

制限: ランダム編集の照合対象はページ状態で、画像描画比較は既存の個別編集テストが担当。画像多用PDF、温度/メモリ制御、後始末時間の計測はH05b2以降。同期PDFKit処理中の即時停止、実機性能、Mac/iPad、新規文言翻訳は未検証/後続。

Duo画面検証成功: iPhone Duo / iOS 27.1。一括/再実行とも成功16/失敗0/スキップ0。ランダム編集のシード20261022、64操作、最大24ページ、保存再読込10ページを表示。JSONに16個の一意ID、全件passed、testDefinitionVersion 7、pdf.stress.randomEditingを確認。表示崩れ/重複なし、外部送信なし、セッション終了済み。

証跡（既出ActionArtifacts配下DeviceInteractionSynthesize）: Verify Random Editing-22_08_21_740-screenshot.png、Verify Random Editing-22_08_32_486-screenshot.png、Verify Random Editing-22_09_11_737-hierarchy.txt。

H05b1完了。次はH05b2の画像負荷・資源制御を小分けに進める。


## H05b2a実装・検証

DiagnosticImagePDFTestを追加。1024×1024のグレースケール画像を8枚、その場で生成して8ページPDFに埋め込む。ページごとに異なる16段階の明暗帯と決定的なテクスチャを使用し、同梱画像/PDFを追加しない。生成用ビットマップは1ページ単位で扱い、autoreleasepoolで一時オブジェクトを解放。専用actorで生成・PDFKit保存・描画検証を行う。

保存前後に全ページを128×128へ描画し、各16点の明度を独立した期待値と許容差8で比較。ページ数/サイズと生成・開く/検証・書き込み・再開/検証の時間、入出力サイズを結果に記録する。一括診断17ケース、testDefinitionVersion 8。

容量ポリシーの標準プロファイルのみ画像負荷を実行。縮小/最小/不足/不明ではスキップする。各ページの生成/描画および保存前後に容量・キャンセルを確認。各PDFの上限64 MiB、追加書き込み見積もり64 MiBに既存の安全係数を適用する。ケース終了時の専用ディレクトリ削除とRunnerの最終回収を利用。実測入力183879 bytes、出力183907 bytes（今回のSimulator）だが、保守的な容量見積もりを維持する。

ビルド成功: BuildProject/BuildProject-Log-20261022-223452.txt
診断関連45テスト全件成功（失敗/スキップ0）: RunSomeTests/A65BBE94-5B3A-40D3-AED4-05281AD5A781.txt
（既出ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A以下）
新規テストで画像生成・再描画、5種類の容量入力、容量低下/キャンセル時の後始末を確認。

制限: 圧縮しやすいグレースケールの合成画像であり、写真/カラー/高解像度の最悪ケース負荷を代表しない。温度/メモリ圧力の検知・制御、後始末時間はH05b2b。同期PDFKit書き込み/1ページ描画中の強制中止は行わず、処理の境界で中止。実機性能、Mac/iPad、翻訳は後続。

Duo画面検証成功: iPhone Duo / iOS 27.1。一括/再実行とも成功17/失敗0/スキップ0。画像負荷結果で8ページ・1024×1024・保存前後全ページ描画/16点照合と工程時間を確認。JSON17個の一意ID、全件passed、testDefinitionVersion 8、pdf.stress.imagesを確認。画像ケース469 msはSimulator参考値。表示崩れ/重複なし、外部送信なし、セッション終了済み。

証跡（既出ActionArtifacts配下DeviceInteractionSynthesize）: Verify Image Diagnostics-22_36_26_288-screenshot.png、Verify Image Diagnostics-22_36_44_453-screenshot.png、Verify Image Diagnostics-22_37_12_914-hierarchy.txt。

H05b2a完了。次はH05b2bの温度/メモリ制御・後始末計測。


## H05b2b1実装・検証

DiagnosticThermalPolicyを追加。Runnerが各ケースの開始前にProcessInfo.thermalStateを確認し、nominal/fairでは実行、serious/criticalでは理由付きスキップ、未知状態もスキップする。温度情報を注入可能にし、実端末を加熱せず境界とケース間の変化を試験する。全件スキップでも作業領域の後始末と結果保存を行う。キャンセル判定を温度判定より先に行い、利用者による中止は未実行として維持。

最終workspace.finishの所要時間をfinalCleanupMillisecondsとしてレポート・チェックポイント・共有JSONへ追加。共有テキストにFinal workspace cleanupを表示し、ケース内の削除時間を含まないことを明記。ケース内削除を含む全削除時間ではない。最終回収失敗時は既存の失敗結果を維持し、試行時間を記録。旧保存データには値がなくても読み込めるoptional項目とし、schemaVersionは1、testDefinitionVersionは9。一括テスト数は17のまま。

ビルド成功: BuildProject/BuildProject-Log-20261023-073220.txt
診断関連49テスト全件成功（失敗/スキップ0）: RunSomeTests/21EEF7FB-8AA4-457A-8A89-4E2295DE1707.txt
（既出ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A以下）
新規4テストで温度4状態、高温時の実行抑止/回収/保存/JSON、ケース間の温度上昇、旧チェックポイント互換性を検証。

制限: 今回はケース開始前の温度確認。実行中の温度上昇の検知・協調停止、メモリ圧力/時間上限、ケース別削除時間は後続H05b2b2。H05b2b全体の完了ではない。Simulatorでの通常経路と注入試験を実機の高温/メモリ圧力検証と同一視しない。

Duo画面検証成功: iPhone Duo / iOS 27.1で成功17/失敗0/スキップ0。共有テキストとJSONに最終回収時間2.231334 ms、定義版9を確認。アプリ再起動後も17件と同じ回収時間/定義版を復元。表示崩れなし、外部送信なし、セッション終了済み。高温は注入試験のみ。
証跡（既出ActionArtifacts配下DeviceInteractionSynthesize）: Verify Cleanup Metrics-07_34_00_292-hierarchy.txt、Verify Cleanup Metrics-07_34_23_124-screenshot.png、Verify Cleanup Metrics-07_34_34_340-hierarchy.txt。
H05b2b1完了。次はH05b2b2。


## H05b2b2a実装・検証

DiagnosticResourceGuardを追加。Runnerが実行するケースにTaskLocalで温度/メモリ確認を渡し、PDF生成・編集・画像生成・描画・保存再開の既存キャンセル確認点へ接続。既存ユーザー文書の通常編集経路は変更しない。DispatchSourceMemoryPressureでnormal/warning/criticalを監視し、Mutexでキュー間の状態を保護。監視は初回診断以降プロセス寿命で保持する。現在のメモリ通知状態は注入可能。

高温またはメモリ圧力を開始前に検知した場合は全後続ケースを理由付きスキップ。途中で検知した場合は実行中をcancelled、後続をskippedとし、最初の停止理由を実行単位で保持する。利用者キャンセルは既存のcancelled/notRunを維持。ケースのdeferとworkspace.finishで一時生成物を回収し、途中結果・停止理由・回収時間を保存/共有。正常終了直後にも確認し、資源問題を検知したケースを成功扱いしない。定義版10、内蔵17ケース。

ビルド成功: BuildProject/BuildProject-Log-20261023-073657.txt
診断関連52テスト成功（失敗/スキップ0）: RunSomeTests/086D3F4C-99EC-43F6-AEFE-AC52A2B16BCD.txt
（既出ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A以下）
新規テスト: メモリ圧力開始時のスキップ、PDF生成中の温度/メモリ変化で停止と削除/永続化/共有、TaskLocalのスコープ分離。既存のケース中に高温へ変化する試験は、変更後の契約に合わせ実行中cancelled/後続skippedへ更新。

制限: メモリ通知はOSのイベント配信に依存し、初回通知前や通知間の状態を完全には把握しない。OSによる強制終了を防ぐ保証はない。同期PDFKit処理は戻った後に停止する。CPU/メモリの既存detached計算は開始前/完了後確認のみで、計算ループ内の確認とキャンセル伝播は次単位。時間上限・ケース別回収時間も次単位H05b2b2b。実機資源圧迫は未検証。

Duo画面検証成功: iPhone Duo / iOS 27.1、初回/再実行とも成功17/失敗0/スキップ0。共有画面/JSONプレビューに17個の一意ID、全件passed、定義版10、最終回収2.044 msを確認。表示崩れなし、外部送信なし、セッション終了済み。資源圧迫は注入試験のみ。
証跡（既出ActionArtifacts配下DeviceInteractionSynthesize）: Verify Resource Guard-07_37_59_761-screenshot.png、Verify Resource Guard-07_38_15_844-hierarchy.txt。
H05b2b2a完了。次はH05b2b2b。


## H05b2b2b実装・検証

CPU計算は16384反復ごと、メモリ走査は65536バイトごと（既存64バイト間隔の走査を維持）に確認点を追加。メモリ16 MiB確保の前後にも確認。既存のmeasureCPU()/measureMemory()は非throwラッパーとして残し、従来性能画面の呼出し互換性を維持する。一括診断はthrow可能なcheck付き処理を使う。

DiagnosticResourceGuard.measureOffMainでTaskLocal資源情報をdetachedタスクへ明示的に渡し、親のキャンセルをwithTaskCancellationHandlerで子へ伝える。子の終了を待ってから後始末へ進み、子だけが残って計算を続けない。既知チェックサムは不変。確認処理の費用も計測時間に含まれるため、過去定義版と無条件に性能比較しない。

ケースごとにContinuousClockで120秒の期限を設定し、資源/キャンセルと同じ確認点および完了直後で判定。期限超過は実行中cancelled、後続skippedとし理由を保存/共有。速度の合否閾値ではない。同期PDFKitやメモリ確保を途中で強制停止する仕組みではなく、協調処理が戻った境界で止まる。定義版11、内蔵17ケース。

ビルド成功: BuildProject/BuildProject-Log-20261023-073948.txt
診断関連56テスト成功（失敗/スキップ0）: RunSomeTests/9D53A079-2694-4BB5-8FAB-E65BDFDD3C49.txt
（既出ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A以下）
新規4テストで両計算ループの途中throwとチェックサム維持、detachedへの資源情報引継ぎ、親からの中止伝播、期限切れと後続スキップ/後始末を確認。

残作業: ケース別削除時間の計測はH05b2cへ分離。従来Performance Test画面は従来の非throw経路であり、今回の資源停止・期限契約は一括診断に適用。実機での資源圧迫/性能は未検証。

Duo画面検証成功: iPhone Duo / iOS 27.1、初回/再実行とも成功17/失敗0/スキップ0。CPU/メモリの既知チェックサムを維持。JSONに17個の一意ID、全件passed、定義版11、最終回収1.931916 ms。共有表示問題なし、外部送信なし、セッション終了済み。タイムアウト/中止は注入試験で確認。
証跡（既出ActionArtifacts配下DeviceInteractionSynthesize）: Verify Computation Limits-07_40_47_228-screenshot.png、Verify Computation Limits-07_40_57_863-hierarchy.txt。
H05b2b2b完了。次はH05b2c。


## H05b2c実装・検証

DiagnosticCaseCleanupとCodableなDiagnosticCleanupMeasurementを追加。TaskLocalでケースごとの削除計測器を渡し、Mutexで記録を保護。PDF編集/画像/ランダム/大量ページのdefer削除を計測する。基本PDFも2ファイルをケース終了時に削除し、従来の最終回収までの保持を短縮。キャンセル中も削除は試みる。存在しないファイルは削除済みとして扱う。

DiagnosticTestResult.cleanupに削除試行の合計millisecondsとsucceededを格納。成功/失敗/中止/生成後のスキップでもdeferの計測を残す。削除失敗は元ケース結果を保持したまま<caseID>.cleanupの失敗項目を追加し、最終workspace.finishで再試行。保存復元とJSONのoptional cleanup、共有テキストのCase cleanup行へ接続。旧保存結果の値なしは未計測として復元できる。CPU/メモリや実行前スキップには架空の0msを付けない。内蔵17ケース、定義版12。finalCleanupMillisecondsは最終回収だけの時間として維持。

ビルド成功: BuildProject/BuildProject-Log-20261023-092641.txt
診断関連59テスト成功（失敗/スキップ0）: RunSomeTests/050E2E26-EF3C-41AB-B87C-8F6C19A82CEE.txt
（既出ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A以下）
新規3テストで成功/失敗/キャンセル時の削除・保存復元・JSON、注入した削除失敗の明示と最終回収、ファイル消失/旧形式の互換性を確認。

制限: 削除API呼出しの時間であり、OSが物理媒体から消去する時間や空き容量表示への反映時間ではない。ケース時間には既存の各計測方式を維持し、削除時間を別途加算して全体所要時間を再構成する保証はしない。失敗時の詳細OSエラーやユーザーパスを共有しない。実機・Mac/iPad・翻訳とReleaseサイズ確認は後続。

Duo画面検証成功: 初回/再実行とも17件成功、PDF15件のcleanupが非負/成功true、CPU/メモリにcleanupなし。Text/JSON、定義版12、再起動後に同一計測値の復元を確認。外部送信なし、セッション終了済み。
証跡（既出ActionArtifacts配下DeviceInteractionSynthesize）: Verify Case Cleanup-09_27_58_580-screenshot.png、Verify Case Cleanup-09_28_18_339-hierarchy.txt、Verify Case Cleanup-09_28_46_885-hierarchy.txt。
画面検証で見つかった長い小数表記は、共有テキストのケース/最終回収時間を小数3桁へ整形して修正。JSON精度は維持。修正後ビルド成功（BuildProject-Log-20261023-092913.txt）、対象10テスト成功（RunSomeTests/37A8E3C4-2A22-4A9B-BC70-1DC355AEB495.txt）。この表示整形後の追加Simulator操作は未実施。
H05b2c完了。次はH06。


## H06a実装・検証

DiagnosticLogStoreTestを追加し、logs.isolatedStoreとして一括診断へ接続。実行用一時領域のlog-storeを明示的に指定し、DiagnosticLogStore.sharedは使用しない。固定日時を使用し、14日前の1秒前は削除、境界ちょうどは保持されること、別ストアインスタンスで再読込できること、イベント/ページ数/選択数/所要時間を照合。JSON記録フィールドが既知の許可リスト内であることを確認する（アプリ全体の個人情報非記録を証明する試験ではない）。

セッションマーカーを残した再開では異常終了が1件記録され、background後の再開では追加されないことを検証。ログのexportにも生成用フルパスが含まれないことを確認。容量は小型セット相当で生成前/各書込段階に確認し、不明/不足/途中低下で理由付きスキップ。PDF以外にもスキップ理由を扱えるDiagnosticSkipReasonを追加し、ログ用の文言を使用する。資源/中止確認、計測付き削除、結果共有を既存基盤に接続。定義版13、内蔵18ケース。

ビルド成功: BuildProject/BuildProject-Log-20261023-105357.txt
診断関連61テスト成功（失敗/スキップ0）: RunSomeTests/D1FD732A-CD5F-4BDA-930F-A66625BDC2FD.txt
（既出ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A以下）
追加2テストは複数条件をループ実行: 容量不明/ゼロ/十分での結果、無関係なログファイルの不変、書込後の容量低下/キャンセル、削除成功と作業領域の空を確認。

残作業: H06bの合成画像フォルダ→PDF変換/順序/向き診断。今回のログ診断は固定された少数レコードであり、大量ログ負荷や全種類の破損入力を網羅しない。通常ログ実装のエラー抑制方針は変更せず、期待レコードを再読込して失敗を検知する。

Duo画面検証成功: iPhone Duo / iOS 27.1、初回/再実行とも18件成功。新ケース説明・JSON定義版13/18一意ID、logs.isolatedStore passed/cleanup成功を確認。通常ログ画面の最新記録に合成操作の混入なし（過去ログ全件監査ではない）。表示崩れなし、外部送信なし、セッション終了済み。
証跡（既出ActionArtifacts配下DeviceInteractionSynthesize）: Verify Isolated Logs-10_55_24_120-screenshot.png、Verify Isolated Logs-10_55_38_226-screenshot.png、Verify Isolated Logs-10_56_22_618-hierarchy.txt、Verify Isolated Logs-10_55_47_103-hierarchy.txt。
H06a完了。次はH06b。


## H06b実装・検証

DiagnosticImageImportTestを追加。3枚の小型TIFF（20×40、30×50、60×80、うち1枚EXIF orientation=6）を専用一時領域で生成。既存ImageImportServiceのフォルダ列挙/自然順ソート/変換を使用し、1/2/10の昇順と10/2/1の降順を検証。それぞれPDF保存再読込で3ページ、寸法（回転画像は50×30）、中央の明度を照合。明度の期待範囲は黒0...16、中間96...160、白239...255とし、色変換差を許容しつつページ取り違え/白紙を検出する。画像ファイル/PDFを同梱しない。

ImageImportService.makePDFへ既定空処理のcheckpoint引数を追加し、開始/画像ごと/終了に診断専用の容量・資源確認を挿入できるようにした。通常取込の呼出しと既存キャンセル処理は維持。小型セット容量で実行可能、各画像と出力PDFを1 MiB未満に制限、変換入力3枚のみ。出力は同じconverted.pdfへ上書きするため同時保持は3画像+1PDF。原本/通常モデル/通常ログを参照せず、deferで画像/PDFを一括削除し計測。定義版14、内蔵19ケース。

初回は中間グレーの色変換差（入力128相当→描画146）で明度照合が失敗。重ならない3段階の期待範囲に修正し、診断と既存画像取込の対象71テスト全件成功（失敗/スキップ0）。既存パラメータ化テストは選択実行のため、全引数網羅とは別に扱う。
ビルド成功: BuildProject/BuildProject-Log-20261023-145611.txt
テスト: RunSomeTests/9926D4E5-E62E-425B-9D07-0F733032CEE4.txt
（既出ActionArtifacts/E0E063EB-DEF9-4DA1-9767-E6954624AE5A以下）
追加2テストは容量不明/ゼロ/最小/十分での実行結果、画像生成後/PDF保存後の容量低下/キャンセル、削除と作業領域の空を検証。

制限: 内蔵診断はTIFF3枚・名前順・EXIF6の寸法補正・単色中央画素に限定。全対応形式、日時ソート、全EXIF向きや非対称内容の向き、利用者の写真の色忠実度を保証するものではない。画像変換処理のData出力は既存方式を使用し、今回の小型入力で上限を制御。実機/Mac/iPad/全言語翻訳は後続。

Duo画面検証成功: iPhone Duo / iOS 27.1、初回/再実行とも19件成功。新ケースの生成3枚/自然順/EXIF寸法/描画説明を確認。JSON定義版14、19一意ID、images.folderConversion passed/cleanup成功。表示崩れ/重複なし、外部送信なし、セッション終了済み。
証跡（既出ActionArtifacts配下DeviceInteractionSynthesize）: Verify Folder Conversion-14_57_17_217-screenshot.png、Verify Folder Conversion-14_57_26_886-screenshot.png、Verify Folder Conversion-14_58_00_979-hierarchy.txt。
H06b完了。次はF01。

## F01a 再開・サイズ依存identityの修正（2026-10-24）

状態: 実装済み、サイズ遷移の操作検証待ち。既存差分は保持。
対象ファイル: ContentView.swift（変更済み）。アプリSwift全体を検索し、旧screen/orientation/lifecycle/safe-area APIの追加対象なし。PerformanceTestの端末情報取得はレイアウト用途ではないため維持。

GeometryReader配下の.id(geometry.size)を削除し、サイズ変更だけでList/ScrollViewを再生成しないようにした。寸法に追従するframeとadaptive gridは維持。初期表示はiOSのhorizontalSizeClassをonAppearで一度だけ評価し、regularならサムネイル、それ以外はリスト。以後のサイズ変更・再表示で利用者の選択を上書きしない。macOSは従来のサムネイル初期値を維持。

設定確認: Debug/ReleaseのLaunch Screen自動生成あり。Info.plist/projectに方向指定・全画面固定なし。xcconfigとbaseConfigurationReferenceなし。設定は変更していない。
Apple DocumentationSearchでid変更がView状態をリセットする契約とhorizontalSizeClassを確認。独立レビューで変更方針・全ファイル検索範囲を照合。

BuildProject成功（エラー0）:
`/var/folders/5q/69sz67qx1zqc5wv9_vnrdy6m0000gn/T/ActionArtifacts/627A2367-A83F-4B33-B2E8-E6AC24033277/BuildProject/BuildProject-Log-20261024-114731.txt`
git diff --check成功。今回モデル処理変更なし、単体テストの追加・再実行なし。

Simulator基準確認ではDuoの466×678表示がorientation landscapeLeft後もPortrait/同寸法だった。回転命令の成功をサイズ遷移成功とは扱わない。利用可能なDeviceEventSynthesize構文に折りたたみ操作なし。選択・スクロール・ズーム・ドラッグのサイズ遷移保持、iPad/Mac回帰は未検証。F01全体を完了とはしない。

新版インストール/起動、設定→診断の表示に成功。クラッシュ/文字の重なりなし。保存済み19件成功/0失敗を表示（今回の診断再実行ではない）。外部送信なし、セッション終了済み。
証跡: 上記ActionArtifacts配下DeviceInteractionSynthesizeの `Verify F01 Resize-11_47_47_331-screenshot.png`（新版起動）、`Verify F01 Resize-11_48_01_562-screenshot.png`（診断）、同名hierarchy.txt。

## F01b 対応画面方向の宣言（2026-10-24）

状態: 実装済み、画面検証中。生成後のアプリInfo.plistにもUISupportedInterfaceOrientationsがないことを確認。F計画の縦横回転検証のため、ソースInfo.plistにiPhoneの縦/左右横とiPadの全4方向を明示。全画面固定/最低OS/Scene設定は変更なし。Apple資料のsupportedInterfaceOrientationsでアプリ宣言とViewControllerの許可方向を照合する契約を確認。

BuildProject成功（エラー0）。生成Info.plistの3方向配列を確認、git diff --check成功。
ログ: 上記ActionArtifacts配下 `BuildProject/BuildProject-Log-20261024-115927.txt`。

画面確認: 新版PID 1873の起動、空状態ボタン、PDFピッカー/キャンセル、設定→診断は正常。左右横向き命令でもPortrait・466×678のままであり、方向宣言の欠落だけでは説明できない。Control Centerはコントロール一覧が空で回転ロック状態を確認できず、設定変更なし。ローカルPDFの最近使った項目は空、DLなし。セッション終了済み。
証跡: 上記DeviceInteractionSynthesize配下 `Verify F01b Orientation-11_59_53_369`（左）、`11_59_57_421`（右）、`12_00_35_479`（診断）、`12_00_49_548`（Control Center）、`12_01_00_230`（復帰）のscreenshot.png/hierarchy.txt。

Apple資料「Configuring the environment of a simulated device」にDevice HubのEnter resize modeで任意寸法へ変更可能との記載あり。今回の接続ツールにはcanvasのresize操作がなく未実施。実サイズ遷移・選択/スクロール保持、低い横画面、iPad/Mac確認は残る。F01bは設定と通常導線確認までで、回転不具合を解消済みとはしない。

## F01c 別Simulatorでのサイズ遷移確認（2026-10-24）

状態: 完了（通常iPhoneの基本操作・サムネイルに限定）。iPhone 17 Pro / iOS 27.0へ現在のアプリをインストール。縦402×874→横874×402の実サイズ変更に成功。空状態の3ボタンが表示され、重なりなし。Duo / iOS 27.1でサイズが変わらない挙動を通常iPhoneでは再現せず。ただし端末とOS両方が異なるため、Duo固有かOS差かは未確定。
コード確認ではiOSの固定ウインドウサイズ・向き制限の独自実装なし。今回ここまで製品コード変更なし。

追加確認: 横でサムネイルを選択→縦へ復帰しても表示モード保持。診断シートも横向きで表示維持。simctlによるローカルPDF転送はCoreSimulatorServiceへのアクセス制限によりファイル変更前に失敗したため、既存の公開サンプル取得機能で英語PDFを開いて検証を継続。

最終確認: 公開英語サンプル24.1MBのPage 3を選択、横画面で11%スクロール→縦→横と往復後もPage 3 Selected、スクロール11%、先頭ページy=235.3を保持。左右両横向きの動作を確認。クラッシュ/文字重なりなし。縦では長い文書タイトル省略、編集操作群が高さを多く占めるが今回操作は可能。PDFの編集・保存・外部送信なし、セッション終了済み。単体テスト再実行なし（製品コード変更なし）、git diff --check成功。
証跡（上記DeviceInteractionSynthesize配下、各screenshot.png/hierarchy.txt）: `Verify F01c Standard Device-12_11_51_542`（横空状態）、`12_12_38_561`（横診断）、`12_13_42_915`（縦選択保持）、`12_13_51_323`（横復帰/選択/スクロール保持）。
未検証: リスト/見開きの位置保持、プレビュー拡大、ドラッグ途中、編集ダイアログ/キーボード、大きい文字、Duoサイズ遷移、iPad/Mac。F01全体は完了扱いにしない。


## Android最新版（v1.2.9）仕様追従 Phase 1：サンプル漫画v2・キャッシュ刷新・起動時クリーンアップ・公式動画連携（2026-11-05）

状態: 完了（全144単体テスト成功）。
Android最新版（v1.2.9および最新ワーキングツリー差分）の仕様変更に合わせ、iOS/macOS版の機能追従・整合を実施。

### 実施内容
1. **サンプル漫画 v2 カタログ更新 (全51冊)**
   - Android側の `manifest.json` に基づき、全14言語・17言語地域区分×第1〜3話（計51冊）のメタデータを `SamplePDFCatalog.json` に反映。
   - 配布元URLを GitHub Releases (`sample-manga-v2`) の固定ダウンロードURLへ切り替え。
   - 著者表記を「Komairo Hiyori」へ統一。
2. **ダウンロード・キャッシュ管理の刷新**
   - 保存先を `MihirakiSamplePdfs/verified/<SHA-256>/<fileName>` へ更新。
   - ダウンロード時のSHA-256検証、バイト数照合、アトミック配置（一時ファイルからのリネーム）を実装。旧パス（`SamplePDFs/<fileName>`）に同一ファイルが存在する場合の自動マイグレーションに対応。
3. **サンプル一覧画面のUI改善**
   - 17言語地域区分（中南米スペイン語 `es_419`、ポルトガル `pt_pt`、香港 `zh_hk` 等）のフィルター対応。
   - ソート順切替（最新話順 / 第1話順、各話内英語名順）を追加。
4. **起動時の一時ファイルクリーンアップ & 旧ログマイグレーション**
   - `PDFCacheCleanup.swift` を新設し、起動時に `temporaryDirectory` / `cachesDirectory` 配下の古いレンダリング・フォルダ画像一時PDF（`pdf-render-*.pdf`, `folder_images_*.pdf`）を安全に一括削除。
   - `fixed_location_labels_v1` フラグを用いて、過去の未フォーマット監査ログ（`app_audit_logs.txt`, `app_logs`）を初回起動時にクリーンアップ。
5. **公式チュートリアル動画（YouTube Shorts）連携**
   - ヘルプ画面に公式YouTube Shortsプレイリスト（`https://www.youtube.com/playlist?list=PLa-QGEwHSDRo`）へのリンク導線を追加。

### 検証結果
- BuildProject: 成功（エラー0）
- 単体テスト: 144件全件成功（Swift Testing 21スイート、失敗0・スキップ0）
  - 新規/更新テスト: `SamplePDFTests`（10件）、`PDFCacheCleanupTests`（2件）


## Android最新版（v1.2.9）仕様追従 Phase 2：コアPDF編集機能（ページ分割 & 均等トリミング）（2026-11-05）

状態: 完了（全185単体テスト成功）。
Android最新版のコア編集機能（左右/上下2分割、4辺均等クロップ0〜40%、LTR/RTL順序対応）をiOS/macOS版に完全追従実装。

### 実施内容
1. **ページ幾何計算ユーティリティの新設 (`PDFPageGeometry.swift`)**
   - `SplitDirection`（`.vertical` 垂直左右分割 / `.horizontal` 水平上下分割）の定義。
   - ページの内部回転角（0°, 90°, 180°, 270°）を考慮した視覚的左右/上下2分割ボックス計算（`splitBoxes`）。
   - 見開き方向（LTR: 左半分→右半分、RTL: 右半分→左半分）に応じた新ページ2件の生成・CropBox設定（`split`）。
   - 四辺均等クロップ計算（`cropBox`）：マージン0.0〜0.40（0〜40%）をクランプ、0%で基準mediaBox復帰。
2. **モデルへの編集操作追加 (`PDFEditorModel.swift`)**
   - `splitSelection(direction:)`: 選択中ページ（複数対応）を逆順ループで安全に2分割置換。操作後に選択解除、Undo/Redo対応、監査ログ（`.pagesSplit`）記録。
   - `cropSelection(margin:)`: 選択中ページに均等余白カットを適用、Undo/Redo対応、監査ログ（`.pagesCropped`）記録。
   - `AppDiagnostics.swift` に `.pagesSplit`, `.pagesCropped` ログイベントを追加。
3. **編集ダイアログ UI (`PDFEditDialogs.swift`) & メニュー導線**
   - `PDFSplitDialog`: 分割方向（左右垂直分割 / 上下水平分割）選択Picker、Run/Cancelボタン。
   - `PDFCropDialog`: 0%〜40%（5%刻み）のSlider、パーセンテージ数値表示、Run/Cancelボタン。
   - `ContentView.swift`: サムネイル操作バー（`ThumbnailAction`）および上部「Edit Pages」メニューに「Split Pages…」「Crop Pages…」のトリガーとシートを追加。
4. **多言語ローカライズ**
   - `Localizable.xcstrings`: 分割・クロップ関連文字列（14言語）にAndroid最新strings.xmlと同一の翻訳テキストを注入。
5. **テスト作成 & 回帰テスト検証**
   - `PDFPageGeometryTests.swift`: 分割座標計算（0°左右・上下）、クロップ余白クランプ（0%, 10%, 60%→40%）、ページ分割時のページ数倍加とUndo/Redo、クロップ適用とUndoを検証。

### 検証結果
- BuildProject: 成功（エラー0）
- 単体テスト: 185件全件成功（Swift Testing、失敗0・スキップ0）


## Android最新版（v1.2.9）仕様追従 Phase 3：プレビュー機能拡張（ズーム・パン・ページ送り）（2026-11-05）

状態: 完了（全188単体テスト成功）。
Android最新版のプレビュー機能（1〜5倍ズーム、拡大時パン、ダブルタップズーム、左右スワイプ/ボタンページ送り、RTL読書順対応、ページカウンター）をiOS/macOS版に完全追従実装。

### 実施内容
1. **専用プレビュービューの新設 (`PDFPagePreviewView.swift`)**
   - 1.0倍〜5.0倍のピンチズーム（`MagnificationGesture`）およびダブルタップトグル（1.0倍 ⇔ 2.5倍）。
   - 拡大時の自由パン移動（`DragGesture`）と1.0倍時のオフセット安全リセット。
   - `PDFPreviewNavigation` によるページインデックス計算（範囲境界チェック、左右スワイプ検出、RTL/LTR反転対応）。
   - 画面下部フローティングコントロール（「前へ」「次へ」ボタン、現在ページ「`current / total`」バッジ）。
   - 上部ナビゲーションバー（閉じるボタン、ズームリセットボタン、タイトル「`Page X / Y`」）。
   - ダークテーマ（黒背景）での高解像度レンダリング。
2. **`ContentView.swift` との統合**
   - 旧簡易プレビューを削除し、`model.pages`、`$previewedPageID`、`readingDirection == .rightToLeft` を渡す新構造へ移行。
3. **テスト作成 & 回帰テスト検証**
   - `PDFPagePreviewTests.swift`: ページ送りの境界制限テスト、LTR/RTLでのスワイプ方向反転検証、ズームスケールクランプ（1.0〜5.0倍）テスト。

### 検証結果
- BuildProject: 成功（エラー0）
- 単体テスト: 188件全件成功（Swift Testing、失敗0・スキップ0）


## Android最新版（v1.2.9）仕様追従 Phase 4：操作性・UI設定・ショートカット（2026-11-05）

状態: 完了（全191単体テスト成功）。
Android最新版の操作性（選択反転、サムネイルサイズ切替 S/M/L、ボタン表示切替）およびmacOS/iPadOS向けのキーボードショートカットを統合。

### 実施内容
1. **選択反転機能 (`invertSelection`)**
   - `PDFEditorModel`: `invertSelection()` を追加（現在選択されていない全ページを選択）。
   - 「Edit Pages」メニューに「Invert Selection」項目を追加（ショートカット: ⌘L）。
2. **UIオプション画面 (`PDFOptionsView.swift`)**
   - `ThumbnailSize`: `S` (90〜130pt), `M` (140〜220pt), `L` (220〜320pt) を `@AppStorage` で保存・動的適用。
   - `ButtonDisplayType`: `Icon and Text`, `Icon Only`, `Text Only` を `@AppStorage` で保存・サムネイル操作バーに即時反映。
   - 「Settings」メニュー（ギアアイコン）から「Options…」シートを開いて設定変更可能。
3. **キーボードショートカット網羅**
   - ⌘A: すべて選択
   - ⌘L: 選択反転
   - ⌘R: 右90°回転
   - ⇧⌘R: 左90°回転
4. **多言語ローカライズ**
   - `Localizable.xcstrings`: Options, Thumbnail Size, Button Display, Invert Selection, Small (S), Medium (M), Large (L), Icon and Text, Icon Only, Text Only について Android 版と同等の14言語翻訳を反映。
5. **テスト追加 & 全件検証**
   - `PDFEditorModelTests.swift`: 選択反転の単体テスト追加。
   - `PDFOptionsTests.swift`: `ThumbnailSize` の寸法大小関係および `ButtonDisplayType` ケース検証。

### 検証結果
- BuildProject: 成功（エラー0）
- 単体テスト: 191件全件成功（Swift Testing、失敗0・スキップ0）
