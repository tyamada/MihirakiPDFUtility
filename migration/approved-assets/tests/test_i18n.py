import unittest
import json
from pathlib import Path

from folimeld.i18n import (I18n, LANGUAGES, QT_LANGUAGE_CODES,
                           STANDARD_BUTTON_LABELS, install_qt_translator)


class SystemLanguageTests(unittest.TestCase):
    def test_system_language_is_a_supported_locale_code(self):
        self.assertIn(I18n._system_language(), LANGUAGES)

    def test_generic_locale_falls_back_to_english(self):
        with (unittest.mock.patch("folimeld.i18n.sys.platform", "linux"),
              unittest.mock.patch("folimeld.i18n.QLocale.system") as system):
            system.return_value.name.return_value = "C"
            self.assertEqual(I18n._system_language(), "en")

    def test_all_languages_define_edit_labels(self):
        locales = Path(__file__).resolve().parent.parent / "locales"
        for path in locales.glob("*.json"):
            with self.subTest(language=path.stem):
                data = json.loads(path.read_text(encoding="utf-8"))
                self.assertTrue(data["insert_blank"])
                self.assertTrue(data["delete"])
                self.assertTrue(data["cannot_delete_all"])

    def test_all_languages_define_standard_button_labels(self):
        self.assertEqual(set(STANDARD_BUTTON_LABELS), set(LANGUAGES))
        for language, labels in STANDARD_BUTTON_LABELS.items():
            with self.subTest(language=language):
                self.assertTrue(labels["discard"])
                self.assertTrue(labels["cancel"])

    def test_qt_translator_uses_qt_locale_aliases(self):
        app = unittest.mock.Mock()
        translator = unittest.mock.Mock()
        with (unittest.mock.patch("folimeld.i18n.QTranslator", return_value=translator),
              unittest.mock.patch("folimeld.i18n.QLibraryInfo.path", return_value="translations")):
            translator.load.return_value = True
            result = install_qt_translator(app, "zh")

        self.assertIs(result, translator)
        translator.load.assert_called_once_with(
            f"qtbase_{QT_LANGUAGE_CODES['zh']}", "translations",
        )
        app.installTranslator.assert_called_once_with(translator)


if __name__ == "__main__":
    unittest.main()
