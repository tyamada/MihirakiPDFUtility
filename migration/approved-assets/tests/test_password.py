import tempfile
import unittest
from pathlib import Path

import fitz

from folimeld.model import PasswordRequiredError, PdfDocument


class PasswordTests(unittest.TestCase):
    def test_password_round_trip(self):
        with tempfile.TemporaryDirectory() as directory:
            source_path = Path(directory) / "source.pdf"
            protected_path = Path(directory) / "protected.pdf"
            unlocked_path = Path(directory) / "unlocked.pdf"
            source = fitz.open()
            source.new_page()
            source.save(source_path)
            source.close()

            model = PdfDocument()
            model.open(str(source_path))
            model.set_view_password("secret")
            model.save(str(protected_path))
            model.close()

            with self.assertRaises(PasswordRequiredError):
                model.open(str(protected_path), "wrong")
            model.open(str(protected_path), "secret")
            self.assertTrue(model.password_protected)
            model.set_view_password(None)
            model.save(str(unlocked_path))
            model.close()

            unlocked = fitz.open(unlocked_path)
            self.assertFalse(unlocked.needs_pass)
            unlocked.close()


if __name__ == "__main__":
    unittest.main()
