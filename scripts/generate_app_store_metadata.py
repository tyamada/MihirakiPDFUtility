#!/usr/bin/env python3
"""
Generate and validate App Store Connect store listing metadata based on Android store listing.
Outputs to both store_listing/ (cross-platform format) and AppStoreConnect/metadata/ (fastlane/App Store Connect format).
"""

import os
import re
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ANDROID_STORE_DIR = "/Users/tyamada22/src/MihirakiPDFUtility_Android/store_listing"
TARGET_DIRS = [
    os.path.join(BASE_DIR, "AppStoreConnect", "metadata"),
    os.path.join(BASE_DIR, "store_listing", "metadata"),
]

# Mapping Android filenames to App Store Connect locale identifiers
LOCALES = {
    "ja": {
        "file": "metadata_ja.txt",
        "name": "見開きPDFユーティリティ",
        "subtitle": "PDFの見開き表示・分割・結合・整理ツール",
        "keywords": "PDF,見開き,結合,分割,ページ並べ替え,自炊,漫画,回転,クロップ,編集,プレビュー,書類",
        "promotional_text": "見開き表示や右開き（漫画・自炊本）に完全対応！ページの分割・結合・並べ替え・余白カットをiPhoneやiPad上で快適かつ安全に行えるローカル完結型PDFツールです。",
        "release_notes": "初版リリース。iPhoneおよびiPadで見開きPDFの表示・分割・結合・ページ整理に対応しました。",
        "support_url": "https://tyamada.github.io/MihirakiPDFUtility/support_ja.html",
        "privacy_url": "https://tyamada.github.io/MihirakiPDFUtility/privacy_ja.html",
        "marketing_url": "https://tyamada.github.io/MihirakiPDFUtility/index_ja.html",
    },
    "en-US": {
        "file": "metadata_en.txt",
        "name": "Mihiraki: PDF Utility",
        "subtitle": "Spread View, Split & Reorder",
        "keywords": "pdf,spread,merge,split,reorder,manga,rotate,crop,editor,reader,scanner,preview,document",
        "promotional_text": "Full support for spread view and right-to-left reading! Merge, split, reorder, and crop PDF pages locally and securely on your iPhone and iPad.",
        "release_notes": "Initial release. Supports spread view, page splitting, merging, and reordering for PDFs on iPhone and iPad.",
        "support_url": "https://tyamada.github.io/MihirakiPDFUtility/support.html",
        "privacy_url": "https://tyamada.github.io/MihirakiPDFUtility/privacy.html",
        "marketing_url": "https://tyamada.github.io/MihirakiPDFUtility/",
    },
    "ko": {
        "file": "metadata_ko.txt",
        "name": "MihirakiPDFUtility",
        "subtitle": "직관적인 PDF 펼쳐보기·분할·병합·정리",
        "keywords": "PDF,펼쳐보기,병합,분할,페이지정리,만화,회전,자르기,편집,미리보기,문서",
        "promotional_text": "양면 펼쳐보기와 우철(만화·전자책) 완벽 지원! iPhone 및 iPad에서 안전하고 빠른 로컬 PDF 편집 도구.",
        "release_notes": "첫 번째 출시. iPhone 및 iPad에서 PDF 펼쳐보기, 분할, 병합 및 페이지 정리 기능을 제공합니다.",
        "support_url": "https://tyamada.github.io/MihirakiPDFUtility/support_ko.html",
        "privacy_url": "https://tyamada.github.io/MihirakiPDFUtility/privacy_ko.html",
        "marketing_url": "https://tyamada.github.io/MihirakiPDFUtility/index_ko.html",
    },
    "zh-Hans": {
        "file": "metadata_zh-CN.txt",
        "name": "MihirakiPDFUtility",
        "subtitle": "直观的PDF双页浏览·拆分·合并·整理",
        "keywords": "PDF,双页,跨页,合并,拆分,页面排序,漫画,旋转,裁剪,编辑,预览,文档",
        "promotional_text": "完美支持双页跨页与右开本阅读！在 iPhone 与 iPad 上安全、高效地进行 PDF 页面分割、合并与整理。",
        "release_notes": "首次发布。支持在 iPhone 与 iPad 上进行 PDF 双页浏览、页面拆分、合并与整理。",
        "support_url": "https://tyamada.github.io/MihirakiPDFUtility/support_zh_hans.html",
        "privacy_url": "https://tyamada.github.io/MihirakiPDFUtility/privacy_zh_hans.html",
        "marketing_url": "https://tyamada.github.io/MihirakiPDFUtility/index_zh_hans.html",
    },
    "zh-Hant": {
        "file": "metadata_zh-TW.txt",
        "name": "Mihiraki: PDF Utility",
        "subtitle": "直觀的PDF雙頁檢視·分割·合併·整理",
        "keywords": "PDF,雙頁,跨頁,合併,分割,頁面排序,漫畫,旋轉,裁切,編輯,預覽,文件",
        "promotional_text": "完美支援雙頁跨頁與右翻漫畫！在 iPhone 與 iPad 上安全且直觀地進行 PDF 頁面整理、分割與合併。",
        "release_notes": "首版發布。支援於 iPhone 與 iPad 上進行 PDF 雙頁檢視、頁面分割、合併與整理。",
        "support_url": "https://tyamada.github.io/MihirakiPDFUtility/support_zh_hant.html",
        "privacy_url": "https://tyamada.github.io/MihirakiPDFUtility/privacy_zh_hant.html",
        "marketing_url": "https://tyamada.github.io/MihirakiPDFUtility/index_zh_hant.html",
    },
    "zh-HK": {
        "file": "metadata_zh-HK.txt",
        "name": "Mihiraki: PDF Utility",
        "subtitle": "直觀的PDF雙頁檢視·分割·合併·整理",
        "keywords": "PDF,雙頁,跨頁,合併,分割,頁面排序,漫畫,旋轉,裁切,編輯,預覽,文件",
        "promotional_text": "完美支援雙頁跨頁與右翻漫畫！在 iPhone 與 iPad 上安全且直觀地進行 PDF 頁面整理、分割與合併。",
        "release_notes": "首版發布。支援於 iPhone 與 iPad 上進行 PDF 雙頁檢視、頁面分割、合併與整理。",
        "support_url": "https://tyamada.github.io/MihirakiPDFUtility/support_zh_hant.html",
        "privacy_url": "https://tyamada.github.io/MihirakiPDFUtility/privacy_zh_hant.html",
        "marketing_url": "https://tyamada.github.io/MihirakiPDFUtility/index_zh_hant.html",
    },
    "de-DE": {
        "file": "metadata_de.txt",
        "name": "Mihiraki: PDF Utility",
        "subtitle": "PDF teilen, verbinden & ordnen",
        "keywords": "PDF,Doppelseite,teilen,verbinden,sortieren,Manga,drehen,zuschneiden,bearbeiten,Reader",
        "promotional_text": "Volle Unterstützung für Doppelseitenanzeige und Rechts-nach-Links-Lesen! PDFs lokal und sicher auf iPhone und iPad bearbeiten.",
        "release_notes": "Erste Veröffentlichung. Unterstützt Doppelseitenanzeige, Teilen, Zusammenführen und Sortieren von PDFs auf iPhone und iPad.",
        "support_url": "https://tyamada.github.io/MihirakiPDFUtility/support_de.html",
        "privacy_url": "https://tyamada.github.io/MihirakiPDFUtility/privacy_de.html",
        "marketing_url": "https://tyamada.github.io/MihirakiPDFUtility/index_de.html",
    },
    "fr-FR": {
        "file": "metadata_fr.txt",
        "name": "Mihiraki: PDF Utility",
        "subtitle": "Vue double page, fusion & tri",
        "keywords": "PDF,double page,fusionner,diviser,trier,manga,pivoter,recadrer,editeur,lecteur",
        "promotional_text": "Prise en charge complète de la double page et lecture droite à gauche ! Fusionnez, divisez et organisez vos PDF sur iPhone et iPad.",
        "release_notes": "Première version. Prend en charge l'affichage en double page, la division, la fusion et l'organisation des PDF sur iPhone et iPad.",
        "support_url": "https://tyamada.github.io/MihirakiPDFUtility/support_fr.html",
        "privacy_url": "https://tyamada.github.io/MihirakiPDFUtility/privacy_fr.html",
        "marketing_url": "https://tyamada.github.io/MihirakiPDFUtility/index_fr.html",
    },
    "it": {
        "file": "metadata_it.txt",
        "name": "MihirakiPDFUtility",
        "subtitle": "Doppia pagina, dividi e unisci",
        "keywords": "PDF,doppia pagina,unisci,dividi,riordina,manga,ruota,ritaglia,editor,lettore",
        "promotional_text": "Supporto completo per visualizzazione a doppia pagina e lettura da destra a sinistra. Organizza e modifica PDF su iPhone e iPad.",
        "release_notes": "Prima versione. Supporta visualizzazione a doppia pagina, divisione, unione e riordino di PDF su iPhone e iPad.",
        "support_url": "https://tyamada.github.io/MihirakiPDFUtility/support_it.html",
        "privacy_url": "https://tyamada.github.io/MihirakiPDFUtility/privacy_it.html",
        "marketing_url": "https://tyamada.github.io/MihirakiPDFUtility/index_it.html",
    }
}


def parse_android_description(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        text = f.read()

    patterns = [
        r"【詳細な商品説明】[^\n]*\n(.*)",
        r"【詳細説明】[^\n]*\n(.*)",
        r"\[Vollständige Beschreibung\][^\n]*\n(.*)",
        r"\[Description complète\][^\n]*\n(.*)",
        r"【Full description】[^\n]*\n(.*)",
        r"【상세 설명】[^\n]*\n(.*)",
        r"【詳細說明】[^\n]*\n(.*)",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.DOTALL)
        if m:
            desc = m.group(1).strip()
            return desc
    return text.strip()


def adapt_description_for_ios(desc):
    desc = desc.replace("Androidデバイス", "iPhoneやiPad")
    desc = desc.replace("Android デバイス", "iPhoneやiPad")
    desc = desc.replace("Android device", "iPhone and iPad")
    desc = desc.replace("Android devices", "iPhone and iPad")
    desc = desc.replace("Android-Gerät", "iPhone und iPad")
    desc = desc.replace("appareil Android", "iPhone et iPad")
    desc = desc.replace("dispositivo Android", "iPhone e iPad")
    desc = desc.replace("안드로이드 기기", "iPhone 및 iPad")
    desc = desc.replace("Android 设备", "iPhone 和 iPad")
    desc = desc.replace("Android 裝置", "iPhone 與 iPad")

    desc = desc.replace("デスクトップ体験 (ChromeOS対応)\nキーボードショートカットやマウスの右クリックメニューをサポート。ChromebookでもPC並みの操作感を実現しました。", "大画面体験 (iPad・Mac対応)\nキーボードショートカットやトラックパッド操作、Split Viewをサポート。iPadやMacでも快適な操作感を実現しました。")
    desc = desc.replace("Desktop Ready (ChromeOS)\nEnhanced for large screens and Chromebooks with keyboard shortcuts and mouse context menus.", "Large Screen Ready (iPad & Mac)\nEnhanced for large screens with keyboard shortcuts, trackpad support, and multi-window multitasking on iPad and Mac.")
    desc = desc.replace("Desktop-Erlebnis (ChromeOS-Unterstützung)\nTastaturkürzel und Kontextmenüs auf Chromebooks.", "Großbildschirm-Erlebnis (iPad & Mac)\nTastaturkurzbefehle und Trackpad-Unterstützung auf iPad und Mac.")
    desc = desc.replace("Expérience bureau (Compatible ChromeOS)\nRaccourcis clavier et menus contextuels pour Chromebook.", "Expérience grand écran (iPad et Mac)\nRaccourcis clavier et prise en charge du trackpad sur iPad et Mac.")
    desc = desc.replace("데스크톱 환경 (ChromeOS 지원)\n키보드 단축키와 마우스 우클릭 메뉴를 지원합니다.", "대화면 환경 (iPad 및 Mac 지원)\n키보드 단축키와 트랙패드 동작을 완벽하게 지원합니다.")
    desc = desc.replace("桌面级体验 (支持 ChromeOS)\n支持键盘快捷键与鼠标右键菜单。", "大屏与桌面体验 (支持 iPad 与 Mac)\n支持外接键盘快捷键与触控板手势。")
    desc = desc.replace("桌面級體驗 (支援 ChromeOS)\n支援鍵盤快捷鍵與滑鼠右鍵選單。", "大螢幕與桌面體驗 (支援 iPad 與 Mac)\n支援外接鍵盤快捷鍵與觸控板手勢。")
    desc = desc.replace("Esperienza desktop (supporto ChromeOS)\nScorciatoie da tastiera e menu contestuale con clic destro.", "Esperienza su grande schermo (iPad e Mac)\nScorciatoie da tastiera e supporto trackpad su iPad e Mac.")

    return desc.strip()


def main():
    errors = []
    summary_rows = []

    for target_dir in TARGET_DIRS:
        os.makedirs(target_dir, exist_ok=True)

    for locale, info in sorted(LOCALES.items()):
        android_file = os.path.join(ANDROID_STORE_DIR, info["file"])
        if not os.path.isfile(android_file):
            errors.append(f"Missing Android metadata file: {android_file}")
            continue

        raw_desc = parse_android_description(android_file)
        desc = adapt_description_for_ios(raw_desc)

        fields = {
            "name.txt": info["name"],
            "subtitle.txt": info["subtitle"],
            "keywords.txt": info["keywords"],
            "description.txt": desc,
            "promotional_text.txt": info["promotional_text"],
            "release_notes.txt": info["release_notes"],
            "support_url.txt": info["support_url"],
            "privacy_url.txt": info["privacy_url"],
            "marketing_url.txt": info["marketing_url"],
        }

        # Validation
        if len(info["name"]) > 30:
            errors.append(f"[{locale}] Name exceeds 30 chars ({len(info['name'])}): {info['name']}")
        if len(info["subtitle"]) > 30:
            errors.append(f"[{locale}] Subtitle exceeds 30 chars ({len(info['subtitle'])}): {info['subtitle']}")
        if len(info["keywords"]) > 100:
            errors.append(f"[{locale}] Keywords exceed 100 chars ({len(info['keywords'])}): {info['keywords']}")
        if len(info["promotional_text"]) > 170:
            errors.append(f"[{locale}] Promotional text exceeds 170 chars ({len(info['promotional_text'])}): {info['promotional_text']}")
        if len(desc) > 4000:
            errors.append(f"[{locale}] Description exceeds 4000 chars ({len(desc)})")

        for target_dir in TARGET_DIRS:
            locale_dir = os.path.join(target_dir, locale)
            os.makedirs(locale_dir, exist_ok=True)
            for filename, content in fields.items():
                path = os.path.join(locale_dir, filename)
                with open(path, "w", encoding="utf-8") as f:
                    f.write(content.strip() + "\n")

        # Also write unified metadata_{locale}.txt to store_listing/
        unified_path = os.path.join(BASE_DIR, "store_listing", f"metadata_{locale}.txt")
        with open(unified_path, "w", encoding="utf-8") as f:
            f.write(f"【アプリ名 / App Name】 (Max 30)\n{info['name']}\n\n")
            f.write(f"【サブタイトル / Subtitle】 (Max 30)\n{info['subtitle']}\n\n")
            f.write(f"【キーワード / Keywords】 (Max 100)\n{info['keywords']}\n\n")
            f.write(f"【プロモーションテキスト / Promotional Text】 (Max 170)\n{info['promotional_text']}\n\n")
            f.write(f"【新機能 / What's New】 (Max 4000)\n{info['release_notes']}\n\n")
            f.write(f"【詳細説明 / Description】 (Max 4000)\n{desc}\n\n")
            f.write(f"【サポートURL】\n{info['support_url']}\n")
            f.write(f"【プライバシーポリシーURL】\n{info['privacy_url']}\n")
            f.write(f"【マーケティングURL】\n{info['marketing_url']}\n")

        summary_rows.append((locale, info["name"], info["subtitle"], len(info["keywords"]), len(desc)))

    for doc_dir in [os.path.join(BASE_DIR, "AppStoreConnect"), os.path.join(BASE_DIR, "store_listing")]:
        summary_path = os.path.join(doc_dir, "METADATA_SUMMARY.md")
        with open(summary_path, "w", encoding="utf-8") as f:
            f.write("# App Store Connect Metadata Summary\n\n")
            f.write("This directory contains ready-to-use metadata for App Store Connect submission, converted from the Android Google Play store listing.\n\n")
            f.write("## Locale Coverage & Character Counts\n\n")
            f.write("| Locale | App Name (<=30) | Subtitle (<=30) | Keywords len (<=100) | Description len (<=4000) |\n")
            f.write("| :--- | :--- | :--- | :--- | :--- |\n")
            for loc, name, sub, kw_len, desc_len in summary_rows:
                f.write(f"| `{loc}` | {name} ({len(name)}) | {sub} ({len(sub)}) | {kw_len} chars | {desc_len} chars |\n")
            f.write("\n## Directory Structure\n\n")
            f.write("```\nmetadata/\n")
            for loc, _, _, _, _ in summary_rows:
                f.write(f"  ├── {loc}/\n")
                f.write("  │   ├── name.txt\n")
                f.write("  │   ├── subtitle.txt\n")
                f.write("  │   ├── keywords.txt\n")
                f.write("  │   ├── description.txt\n")
                f.write("  │   ├── promotional_text.txt\n")
                f.write("  │   ├── release_notes.txt\n")
                f.write("  │   ├── support_url.txt\n")
                f.write("  │   ├── privacy_url.txt\n")
                f.write("  │   └── marketing_url.txt\n")
            f.write("```\n")

    if errors:
        for err in errors:
            print("ERROR:", err, file=sys.stderr)
        sys.exit(1)
    else:
        print(f"Successfully generated App Store Connect metadata for {len(summary_rows)} locales.")


if __name__ == "__main__":
    main()
