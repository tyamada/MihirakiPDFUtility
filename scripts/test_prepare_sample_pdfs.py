import hashlib
from pathlib import Path
import tempfile
import unittest
from prepare_sample_pdfs import PREFIX, external_directory, prepare, verify_file


class PreparationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.inputs = self.root / 'input'
        self.inputs.mkdir()
        self.data = b'%PDF-1.4\nsmall test fixture\n'
        self.entry = dict(sample_id='ep1_fil', filename='fixture_tl.pdf', bytes=len(self.data),
                          sha256=hashlib.sha256(self.data).hexdigest(), new_download_url=PREFIX+'fixture_tl.pdf')
        (self.inputs/'fixture_tl.pdf').write_bytes(self.data)
        self.cache = self.root/'cache'

    def test_copy_and_offline_reuse_preserve_source(self):
        p = prepare(self.entry, self.cache, self.inputs)
        self.assertEqual(p.read_bytes(), self.data)
        stamp = p.stat().st_mtime_ns
        self.assertEqual(prepare(self.entry, self.cache), p)
        self.assertEqual(p.stat().st_mtime_ns, stamp)
        self.assertEqual((self.inputs/'fixture_tl.pdf').read_bytes(), self.data)

    def test_corrupt_cache_fails_without_overwriting(self):
        self.cache.mkdir(); p=self.cache/'fixture_tl.pdf';p.write_bytes(b'bad')
        with self.assertRaises(ValueError):prepare(self.entry,self.cache,self.inputs)
        self.assertEqual(p.read_bytes(),b'bad')

    def test_hash_mismatch_fails(self):
        bad=dict(self.entry,sha256='0'*64)
        with self.assertRaises(ValueError):verify_file(self.inputs/'fixture_tl.pdf',bad)

    def test_offline_missing_is_error(self):
        with self.assertRaises(FileNotFoundError):prepare(self.entry,self.cache)

    def test_repository_output_is_rejected(self):
        with self.assertRaises(ValueError):external_directory(self.root/'docs/sample',self.root)

    def test_unapproved_host_is_rejected(self):
        bad=dict(self.entry,new_download_url='https://example.com/fixture_tl.pdf')
        with self.assertRaises(ValueError):prepare(bad,self.cache,self.inputs)


if __name__=='__main__':unittest.main()
