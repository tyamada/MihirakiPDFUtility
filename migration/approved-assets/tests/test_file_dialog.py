import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

from folimeld.app import MainWindow


class FileDialogTests(unittest.TestCase):
    def test_uses_and_remembers_last_open_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            selected = str(Path(directory) / "document.pdf")
            parent = object()
            settings = Mock()
            settings.value.return_value = directory
            with patch("folimeld.app.QSettings", return_value=settings), patch(
                "folimeld.app.QFileDialog.getOpenFileName",
                return_value=(selected, "PDF (*.pdf)"),
            ) as dialog:
                result = MainWindow.select_pdf(parent, "Open")

            self.assertEqual(result, selected)
            dialog.assert_called_once_with(parent, "Open", directory, "PDF (*.pdf)")
            settings.setValue.assert_called_once_with("last_open_directory", directory)

    def test_missing_saved_directory_falls_back_to_pictures(self):
        with tempfile.TemporaryDirectory() as pictures:
            settings = Mock()
            parent = object()
            settings.value.return_value = "missing-directory"
            with patch("folimeld.app.QSettings", return_value=settings), patch(
                "folimeld.app.QStandardPaths.writableLocation", return_value=pictures,
            ), patch(
                "folimeld.app.QFileDialog.getOpenFileName", return_value=("", ""),
            ) as dialog:
                result = MainWindow.select_pdf(parent, "Open")

        self.assertEqual(result, "")
        dialog.assert_called_once_with(parent, "Open", pictures, "PDF (*.pdf)")
        settings.setValue.assert_not_called()


if __name__ == "__main__":
    unittest.main()
