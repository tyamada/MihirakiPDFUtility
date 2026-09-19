from pathlib import Path
import sys
import unittest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "tools"))

from write_version_info import version_info, windows_version


class VersionInfoTests(unittest.TestCase):
    def test_windows_version_adds_revision(self) -> None:
        self.assertEqual(windows_version("1.2.3"), (1, 2, 3, 0))

    def test_generated_resource_uses_same_version(self) -> None:
        generated = version_info("1.2.3")
        self.assertIn("filevers=(1, 2, 3, 0)", generated)
        self.assertIn("StringStruct(u'ProductVersion', u'1.2.3')", generated)

    def test_invalid_version_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            windows_version("1.2")


if __name__ == "__main__":
    unittest.main()
