"""Offline checks for public links, required build assets and optional provenance hashes."""
import argparse
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import plistlib
import re
from urllib.parse import unquote, urlsplit


class Links(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.references = []
        self.ids = set()
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if attrs.get('id'):
            self.ids.add(attrs['id'])
        for key in ('href', 'src'):
            if attrs.get(key):
                self.references.append(attrs[key])
        if tag == 'option' and '.html' in attrs.get('value', ''):
            self.references.append(attrs['value'])


def check_links(root):
    root = root.resolve()
    pages = {p: Links(p.read_text()) for p in sorted((root / 'docs').rglob('*.html'))}
    errors = []
    sources = [(path, page.references) for path, page in pages.items()]
    for name in ('README.md', 'README_ja.md'):
        path = root / name
        if not path.is_file():
            errors.append(f'Missing {name}')
            continue
        text = path.read_text()
        sources.append((path, Links(text).references + re.findall(r'\]\(([^\s)]+)(?:\s+"[^"]*")?\)', text)))
    for path, references in sources:
        for reference in references:
            url = urlsplit(reference)
            if url.scheme or url.netloc:
                continue
            target = (path.parent / unquote(url.path)).resolve() if url.path else path
            if url.path.startswith('/') or not target.is_relative_to(root):
                errors.append(f'{path.name}: link escapes repository: {reference}')
                continue
            if target.is_dir():
                target /= 'index.html'
            if not target.is_file():
                errors.append(f'{path.name}: missing local target: {reference}')
            elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].ids:
                errors.append(f'{path.name}: missing HTML anchor: {reference}')
    return errors


def check_build_inputs(root):
    errors = []
    required = ('MihirakiPDFUtility-Info.plist',
                'MihirakiPDFUtility.xcodeproj/project.pbxproj',
                'MihirakiPDFUtility.xcodeproj/xcshareddata/xcschemes/MihirakiPDFUtility.xcscheme',
                'MihirakiPDFUtilityApp/Assets.xcassets/Contents.json',
                'MihirakiPDFUtilityApp/Assets.xcassets/AppIcon.appiconset/Contents.json')
    for name in required:
        if not (root / name).is_file():
            errors.append(f'Missing build input: {name}')
    info = root / required[0]
    if info.is_file():
        try:
            plistlib.loads(info.read_bytes())
        except (plistlib.InvalidFileException, ValueError) as error:
            errors.append(f'Invalid Info.plist: {error}')
    for path in (root / 'MihirakiPDFUtilityApp/Assets.xcassets').rglob('Contents.json'):
        try:
            data = json.loads(path.read_text())
            for image in data.get('images', []):
                name = image.get('filename')
                if name and not (path.parent / name).is_file():
                    errors.append(f'{path.relative_to(root)}: missing image {name}')
        except (ValueError, OSError) as error:
            errors.append(f'{path.relative_to(root)}: {error}')
    return errors


def check_manifest(root):
    errors = []
    path = root / 'migration/ASSET_MANIFEST.sha256'
    if not path.is_file():
        return ['Missing migration/ASSET_MANIFEST.sha256']
    for line in path.read_text().splitlines():
        if not line.strip():
            continue
        try:
            digest, name = line.split(maxsplit=1)
            target = (root / name.lstrip('*')).resolve()
            if not target.is_relative_to(root.resolve()) or not target.is_file():
                errors.append(f'Missing/unsafe manifest entry: {name}')
            elif hashlib.sha256(target.read_bytes()).hexdigest() != digest:
                errors.append(f'Manifest checksum mismatch: {name}')
        except ValueError:
            errors.append('Malformed manifest line')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest', action='store_true', help='Also verify approved asset SHA-256 hashes')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    errors = check_links(root) + check_build_inputs(root)
    if args.manifest:
        errors += check_manifest(root)
    print(json.dumps({'errors': errors, 'external_links_checked': False,
                      'manifest_checked': args.manifest}, ensure_ascii=False, indent=2))
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(main())
