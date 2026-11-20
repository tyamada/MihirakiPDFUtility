"""Compare the bundled catalog with the pinned release's migration evidence.

Pass the downloaded pdf-manifest.json, pdf-migration.csv, and SHA256SUMS directory.
--catalog explicitly selects the catalog under verification. Optional
--download-directory verifies HTTPS downloads outside this repository;
--sample-id limits downloads to the required integration samples.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import csv
import json
from pathlib import Path

PREFIX = 'https://github.com/tyamada/manga-prompt-kit/releases/download/manga-pdf-20261103-v1/'


def verify(catalog, evidence):
    manifest = json.loads((evidence / 'pdf-manifest.json').read_text())
    entries = {e['sample_id']: e for e in manifest['entries']}
    rows = {r['sample_id']: r for r in csv.DictReader((evidence / 'pdf-migration.csv').open())
            if r['source_repository'] == 'tyamada/MihirakiPDFUtility_Android'}
    sums = {line.split(maxsplit=1)[1].strip().lstrip('*'): line.split()[0]
            for line in (evidence / 'SHA256SUMS').read_text().splitlines() if line.strip()}
    samples = catalog['samples']
    assert len(samples) == len(entries) == len(rows) == 51
    assert set(s['id'] for s in samples) == set(entries) == set(rows)
    assert len(set(s['downloadURL'] for s in samples)) == 51
    assert len(set(s['fileName'] for s in samples)) == 51
    languages = {s['languageCode'] for s in samples}
    assert len(languages) == 17
    for episode in range(1, 4):
        group = [s for s in samples if s['episode'] == episode]
        assert len(group) == 17 and {s['languageCode'] for s in group} == languages
    for sample in samples:
        entry, row = entries[sample['id']], rows[sample['id']]
        assert (sample['languageCode'], sample['episode'], sample['pages'], sample['byteSize'], sample['sha256']) == (
            entry['language_key'], entry['episode'], 8, entry['bytes'], entry['sha256'])
        assert sample['fileName'] == row['old_filename']  # Preserve on-device cache keys.
        assert sample['downloadURL'] == entry['new_download_url'] == row['new_download_url']
        assert sample['downloadURL'] == PREFIX + entry['filename']
        assert sample['sha256'] == sums[entry['filename']] == row['sha256']
        assert row['language_key'] == sample['languageCode']
        if sample['languageCode'] == 'fil':
            assert sample['id'] == f"ep{sample['episode']}_fil"
            assert entry['filename'].endswith('_tl.pdf')
    return samples


def download(sample, directory):
    from prepare_sample_pdfs import prepare
    entry = dict(sample_id=sample['id'], filename=sample['downloadURL'].rsplit('/', 1)[-1],
                 bytes=sample['byteSize'], sha256=sample['sha256'], new_download_url=sample['downloadURL'])
    prepare(entry, directory, download=True)
    return sample['id']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('evidence', type=Path)
    parser.add_argument('--download-directory', type=Path)
    parser.add_argument('--catalog', type=Path, required=True, help='Explicit catalog to verify; no app catalog is rewritten')
    parser.add_argument('--sample-id', action='append', help='Download only selected integration samples')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    samples = verify(json.loads(args.catalog.read_text()), args.evidence)
    print('PASS: 51 catalog entries match manifest, CSV, SHA256SUMS; 3 episodes × 17 locales.', flush=True)
    if args.sample_id:
        by_id = {s['id']: s for s in samples}
        samples = [by_id[key] for key in dict.fromkeys(args.sample_id)]
    if args.download_directory:
        from prepare_sample_pdfs import external_directory
        args.download_directory = external_directory(args.download_directory, root)
        args.download_directory.mkdir(parents=True, exist_ok=True)
        with ThreadPoolExecutor(max_workers=3) as pool:
            for sample_id in pool.map(lambda s: download(s, args.download_directory), samples):
                print(f'PASS: PDF, size, SHA-256 (HTTPS download or verified cache): {sample_id}', flush=True)


if __name__ == '__main__':
    main()
