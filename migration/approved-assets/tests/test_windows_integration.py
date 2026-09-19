import sys
import types
import unittest
from pathlib import Path
from unittest.mock import patch

from folimeld.windows_integration import is_packaged, open_command, register_open_with


class WindowsIntegrationTests(unittest.TestCase):
    def test_open_command_quotes_executable_and_pdf_path(self):
        executable = str(Path("folder with spaces") / "Folimeld.exe")

        command = open_command(executable)

        self.assertTrue(command.endswith('Folimeld.exe" "%1"'))
        self.assertTrue(command.startswith('"'))

    def test_register_open_with_is_noop_when_windows_registry_is_unavailable(self):
        with patch.object(sys, "platform", "win32"), patch.object(sys, "frozen", True, create=True):
            with patch.dict(sys.modules, {"winreg": None}):
                self.assertFalse(register_open_with())

    def test_packaged_app_does_not_write_file_association_registry_keys(self):
        with patch.object(sys, "platform", "win32"), \
             patch.object(sys, "frozen", True, create=True), \
             patch("folimeld.windows_integration.is_packaged", return_value=True), \
             patch.dict(sys.modules, {"winreg": types.SimpleNamespace()}):
            self.assertFalse(register_open_with())

    def test_non_windows_process_is_not_packaged(self):
        with patch.object(sys, "platform", "linux"):
            self.assertFalse(is_packaged())


if __name__ == "__main__":
    unittest.main()
