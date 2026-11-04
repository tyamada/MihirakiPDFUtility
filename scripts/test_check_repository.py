import tempfile
from pathlib import Path
import unittest
from check_repository import check_links, check_build_inputs, check_manifest


class RepositoryChecks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / 'README.md').write_text('# App')
        (self.root / 'README_ja.md').write_text('# App')
        (self.root / 'docs').mkdir()

    def tearDown(self):
        self.temp.cleanup()

    def test_existing_image_and_remote_link(self):
        (self.root / 'docs/icon.png').write_bytes(b'asset')
        (self.root / 'README.md').write_text('![Icon](docs/icon.png) [Remote](https://example.invalid/unavailable)')
        self.assertEqual(check_links(self.root), [])

    def test_markdown_and_html_images_are_checked(self):
        (self.root / 'README.md').write_text('![Icon](missing.png) <img src="other.png">')
        self.assertEqual(len(check_links(self.root)), 2)

    def test_html_anchors_are_checked(self):
        (self.root / 'docs/index.html').write_text('<a href="#absent">Read</a>')
        self.assertTrue(any('anchor' in e for e in check_links(self.root)))

    def test_encoded_paths_with_query_and_fragment(self):
        (self.root / 'docs/a b.pdf').write_bytes(b'pdf')
        (self.root / 'README.md').write_text('[PDF](docs/a%20b.pdf?download=1#page=2)')
        self.assertEqual(check_links(self.root), [])

    def test_repository_escape_is_rejected(self):
        (self.root / 'README.md').write_text('[Outside](../README.md)')
        self.assertTrue(any('escapes' in e for e in check_links(self.root)))

    def test_missing_build_inputs_are_detected(self):
        self.assertTrue(any('Info.plist' in e for e in check_build_inputs(self.root)))

    def test_provenance_mismatch_is_detected(self):
        (self.root / 'migration').mkdir()
        (self.root / 'sample').write_bytes(b'data')
        (self.root / 'migration/ASSET_MANIFEST.sha256').write_text('0' * 64 + '  sample\n')
        self.assertTrue(any('mismatch' in e for e in check_manifest(self.root)))


if __name__ == '__main__':
    unittest.main()
