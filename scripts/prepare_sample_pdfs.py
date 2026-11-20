"""Prepare selected, verified manga PDFs outside the repository (integration use).

Use a pdf-manifest.json from the fixed manga-pdf-20261103-v1 release.
No files are copied into docs/sample or testdata. Offline failures are errors.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

PREFIX = 'https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/'


def validate_entry(entry):
    name = entry['filename']
    if Path(name).name != name or not name.endswith('.pdf'):
        raise ValueError('Unsafe PDF filename')
    if entry['new_download_url'] != PREFIX + name:
        raise ValueError('PDF URL is not in the fixed release')
    if entry['bytes'] <= 0 or len(entry['sha256']) != 64 or any(c not in '0123456789abcdef' for c in entry['sha256']):
        raise ValueError('Invalid size or SHA-256')


def verify_file(path, entry):
    validate_entry(entry)
    if path.stat().st_size != entry['bytes']:
        raise ValueError(f'Size mismatch: {path}')
    with path.open('rb') as stream:
        if stream.read(5) != b'%PDF-':
            raise ValueError(f'Not a PDF: {path}')
        stream.seek(0)
        if hashlib.file_digest(stream, 'sha256').hexdigest() != entry['sha256']:
            raise ValueError(f'SHA-256 mismatch: {path}')


def external_directory(path, root):
    path = path.resolve()
    root = root.resolve()
    if path == root or root in path.parents:
        raise ValueError('Use a cache outside the repository; never docs/sample or testdata')
    return path


def prepare(entry, cache, inputs=None, download=False):
    validate_entry(entry)
    target = cache / entry['filename']
    if target.exists():
        verify_file(target, entry)
        return target
    source = inputs / entry['filename'] if inputs else None
    if not (source and source.is_file()) and not download:
        raise FileNotFoundError(f"Missing {entry['sample_id']}; provide --input-directory or explicitly use --download")
    cache.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix='.sample-', dir=cache)
    os.close(fd)
    temp = Path(temp_name)
    try:
        if source and source.is_file():
            verify_file(source, entry)
            shutil.copyfile(source, temp)
        else:
            subprocess.run(['curl', '-q', '-fLsS', '--proto', '=https', '--proto-redir', '=https',
                            '--max-time', '180', '-o', str(temp), entry['new_download_url']], check=True)
        verify_file(temp, entry)
        # Never overwrite a file placed by another process.
        os.link(temp, target)
        return target
    finally:
        temp.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('manifest', type=Path)
    parser.add_argument('--manifest-sha256', required=True, help='Expected SHA-256 of the pinned manifest')
    parser.add_argument('--sample-id', action='append', required=True, help='Repeat for only the required PDFs')
    parser.add_argument('--cache-directory', type=Path, required=True)
    parser.add_argument('--input-directory', type=Path)
    parser.add_argument('--download', action='store_true', help='Explicitly permit HTTPS integration downloads')
    args = parser.parse_args()
    payload = args.manifest.read_bytes()
    if hashlib.sha256(payload).hexdigest() != args.manifest_sha256:
        raise ValueError('Manifest SHA-256 mismatch')
    manifest = json.loads(payload)
    if manifest['tag_candidate'] != 'manga-pdf-20261103-v1' or manifest['repository'] != 'tyamada/manga-prompt-kit':
        raise ValueError('Wrong fixed release manifest')
    entries = {e['sample_id']: e for e in manifest['entries']}
    if len(entries) != 51:
        raise ValueError('Expected 51 distinct samples')
    root = Path(__file__).resolve().parents[1]
    cache = external_directory(args.cache_directory, root)
    for sample_id in dict.fromkeys(args.sample_id):
        print(prepare(entries[sample_id], cache, args.input_directory, args.download))


if __name__ == '__main__':
    main()
