import json
from pathlib import Path
from unittest.mock import patch

from PySide6.QtGui import QKeySequence
from PySide6.QtWidgets import QApplication, QDialogButtonBox, QTabWidget

from folimeld.app import MainWindow
from folimeld.i18n import I18n, LANGUAGES


def test_help_available_without_pdf_and_reuses_window():
    app = QApplication.instance() or QApplication([])
    with patch("folimeld.app.is_packaged", return_value=False):
        window = MainWindow()
    try:
        assert window.help_action.isEnabled()
        assert window.help_action.shortcut() == QKeySequence("F1")
        window.help_action.trigger()
        dialog = window.help_dialog
        assert dialog.isVisible()
        assert not dialog.isModal()
        tabs = dialog.findChild(QTabWidget)
        shortcuts = tabs.widget(2).toPlainText()
        assert window.save_as_action.text() in shortcuts
        assert window.save_as_action.shortcut().toString(
            QKeySequence.SequenceFormat.NativeText
        ) in shortcuts
        dialog.findChild(QDialogButtonBox).button(
            QDialogButtonBox.StandardButton.Close
        ).click()
        assert not dialog.isVisible()
        window.help_action.trigger()
        assert window.help_dialog is dialog
        assert dialog.isVisible()
        assert not window.model.loaded
    finally:
        window.close()
        window.deleteLater()
        app.processEvents()


def test_help_is_translated_in_every_language():
    root = Path(__file__).resolve().parent.parent / "locales"
    english = json.loads((root / "en.json").read_text(encoding="utf-8"))
    keys = {key for key in english if key.startswith("help_")}
    translator = I18n()
    for language in LANGUAGES:
        data = json.loads((root / f"{language}.json").read_text(encoding="utf-8"))
        translator.load(language)
        for key in keys:
            assert data[key].strip(), (language, key)
            assert "???" not in data[key], (language, key)
            assert translator.tr(key) == data[key]
