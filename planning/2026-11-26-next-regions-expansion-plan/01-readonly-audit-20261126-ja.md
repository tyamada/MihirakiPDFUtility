# Utility 読み取り調査記録（2026-11-26）

- **調査対象**：Mihiraki: PDF Utility（Apple ID `6814705870`）および本リポジトリ（`HEAD: bec1940`）
- **実施方針**：完全読み取り専用。配信地域・価格・メタデータ・コンプライアンス・ソースコード・Git状態のいずれも変更していません。

---

## 1. App Store Connect 確認結果（2026-11-26）

### 1.1 アプリ本体・配信地域・登録言語
- **公開バージョン**：`iOS 1.0.4`（ビルド `6`）— `配信準備完了`
- **価格および配信状況**（基準国：米国 USD、税カテゴリ：`App Storeソフトウェア`）：
  - **配信可能（6地域）**：アメリカ合衆国、マカオ、香港、台湾、大韓民国、日本
  - **配信不可（169地域）**：**カナダ**、イギリス、オーストラリア、ニュージーランド、シンガポール、ドイツ、フランス、イタリア を含む
- **App Store 登録言語（3言語）**：
  1. 英語（アメリカ）— プライマリ
  2. 中国語（繁体字）
  3. 日本語

### 1.2 応援購入3商品の提供状況・登録価格・予定変更
3商品とも非消耗型・`承認済み`・全175地域で販売有効（`選択されたすべての国または地域`）・基準国 `日本（JPY）`。登録言語はいずれも `en-US`・`zh-Hant`・`ja` の3言語のみ（`de-DE` / `fr-FR` / `it` 未登録）。

| 地域 | 通貨 | Bronze 現行 (`6818716409`) | Silver 現行 (`6818716823`) | Gold 現行 (`6818717159`) | Android基準参考値 (B / S / G) | 2026-12-03 自動調整 |
|---|---|---:|---:|---:|---:|---|
| 日本（基準） | JPY | ¥200 | ¥500 | ¥1,000 | ¥200 / ¥500 / ¥1,000 | なし |
| カナダ | CAD | CA$0.49 | CA$3.99 | CA$7.99 | CA$2.79 / CA$6.99 / CA$13.99 | なし |
| イギリス | GBP | £0.49 | £2.99 | £5.99 | £1.79 / £4.49 / £8.99 | なし |
| オーストラリア | AUD | A$0.99 | A$4.99 | A$9.99 | A$2.99 / A$7.99 / A$15.99 | なし |
| ニュージーランド | NZD | NZ$0.99 | NZ$4.99 | NZ$9.99 | （未設定・要決定） | なし |
| シンガポール | SGD | S$0.48 | S$3.98 | S$8.98 | （未設定・要決定） | なし |
| ドイツ | EUR | €0.49 | €2.99 | €6.99 | €1.99 / €4.99 / €9.99 | なし |
| フランス | EUR | €0.49 | €2.99 | €6.99 | €1.99 / €4.99 / €9.99 | なし |
| イタリア | EUR | €0.49 | €2.99 | €6.99 | €1.99 / €4.99 / €9.99 | なし |

- **2026-12-03 Apple自動調整予定**：
  - Bronze：予定変更なし
  - Silver：4地域（エジプト・コロンビア・トルコ等）のみ。候補7地域に影響なし
  - Gold：5地域（エジプト・コロンビア・トルコ・ボツワナ・ルワンダ）のみ。候補7地域に影響なし

### 1.3 コンプライアンス・契約・税務・銀行口座
- **EU デジタルサービス法（DSA）**：
  - Business 側（27 EU地域、最終更新 `2026-08-29`）：`有効` だが選択は **「DSAに基づくトレーダーではありません、またはEU内で配信する予定はありません」**（連絡先未公開）。
  - アプリ側（`/distribution/compliance`）：「このデベロッパは自身がこのアプリのノントレーダーであることを認めています。アプリレベルのトレーダーステータスを更新するため、コンプライアンス要件を満たす必要があります。」と表示。
- **暗号化・フランス輸出申告**：
  - ビルド `1.0.4 (6)`：`非免除暗号化を使用するアプリ: いいえ`。追加書類の要求・警告なし。
- **年齢レーティング**：
  - 現行 `4+`（韓国・ブラジル・ベトナム等も設定済み）。
  - **期限付き通知**：**2027-01-15** までに「位置情報共有・出会い系機能」の新設質問に回答が必要。
- **中国本土向け警告（今回対象外）**：
  - セキュリティアセスメント・AI生成/合成コンテンツが `情報不足`（期限 `2027-01-31`）。
- **App のプライバシー**：公開済み（`データの収集なし`）。
- **契約・銀行・税務（Business）**：
  - 有料アプリ契約：`有効`（全地域、`2026-10-14` 〜 `2027-08-16`）
  - 無料アプリ契約：`有効`（全地域、`2026-10-30` 〜 `2027-08-16`）
  - 銀行口座：`有効`（Mizuho / JPY / ロイヤリティ USD）
  - 納税フォーム：`有効`（U.S. Form W-8BEN 等）
  - Business 画面上の未処理警告なし。

---

## 2. リポジトリ確認結果（2026-11-26）

### 2.1 アプリ内ローカライズ
- **`MihirakiPDFUtilityApp/Localizable.xcstrings`**（全438キー、ソース言語 `en`）：
  - キー登録数：`de` 437/438（`translated` 284 / `machine_translated` 153）、`fr` 437/438（284 / 153）、`it` 437/438（370 / 67）。
  - **欠落キー（1件）**：`%lld pages`（`en` / `zh-Hant` / `zh-HK` のみ存在）。
  - **英語のまま残存（12文字超・JAは翻訳済み）**：`de` 23件、`fr` 23件、`it` 30件。
    - `HelpView` で使用：`Open Diagnostics from Settings to run an on-device performance test.`（`de`/`fr`/`it` すべて英語残存）。
    - 購入復元・サポーター関連：`No Supporter Icons Purchased`（`de`/`fr` で英語残存）、`No purchases were found to restore.`（`it` で英語残存）。
    - `it` のみ追加で `HelpView` の3文（ページ操作・パスワード・14日ログ保持）も英語残存。
  - **用語・口調の揺れ**：ドイツ語で `du` 調と `Sie` 調が混在（例：`Verwende ...` vs `Passen Sie ...`）。
  - **長文による文字切れ・折返し重点確認箇所（iPhone SE 優先）**：
    - `de`：`Unterstützungsoptionen konnten nicht geladen werden`（51文字）、`Zwei Spalten, rechts beginnend`（30文字）、`Zwei Seiten, rechts beginnend`（29文字）、`Nach hinten verschieben`（23文字）
    - `fr`：`Afficher les journaux de diagnostic`（35文字）、`Définir le mot de passe de lecture`（34文字）、`Modifications non enregistrées`（30文字）、`Politique de confidentialité`（28文字）
- **`MihirakiPDFUtilityApp/InfoPlist.xcstrings`**：
  - `CFBundleDisplayName`：`en` = `"Mihiraki: PDF Utility"`、`ja` = `"見開きPDFユーティリティ"` に対し、`de` / `fr` / `it` は `"MihirakiPDFUtility"` のまま。
- **`Products.storekit/Configuration.storekit`**：
  - `de` に `Bronze-Tipp` / `Silber-Tipp` / `Gold-Tipp`（敬称 `Sie`）、`fr` に `Pourboire Bronze` / `Argent` / `Or` を定義。`it` は未登録。

### 2.2 Webページ（`docs/`）とストア原稿（`AppStoreConnect/metadata/`）
- **`docs/support_de.html`・`docs/support_fr.html`（重大）**：
  - 本文に **韓国語（ハングル83トークン）が混入**（「使い方」「FAQ回答」「お問い合わせ」「オープンソース」）。
  - 英語版 `support.html` にある応援購入（Bronze/Silver/Gold）・購入復元の説明が未反映。`support_de.html` は「新機能と追加ツール」節も欠落。
- **`docs/index_de.html`・`docs/index_fr.html`**：
  - 韓国語混入なし。`<title>` が `Mihiraki PDF Utility — Mihiraki PDF Utility` と重複。応援購入の記載が英語版と未同期。
- **`docs/privacy_de.html`・`docs/privacy_fr.html`**：
  - 韓国語混入なし、9節構成で英語版と整合。
- **イタリア語Webページ**：
  - `docs/*_it.html` は未作成。`AppVersionInfo.swift` の仕様どおり英語 `privacy.html` へフォールバック。
- **`AppStoreConnect/metadata/{en-US,de-DE,fr-FR,it}/`**：
  - すべて文字数上限内（`name` ≤ 30、`subtitle` ≤ 30、`keywords` ≤ 100、`promotional_text` ≤ 170）、ハングル・日本語混入なし。
  - `de-DE` / `fr-FR` の `support_url.txt` は上記の `support_de.html` / `support_fr.html` を参照しているため、登録前に Web 修正が必須。
  - `de-DE` / `fr-FR` / `it` の `release_notes.txt` は初回版文言のまま。
