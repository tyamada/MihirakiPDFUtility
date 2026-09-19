import unittest

import fitz

from folimeld.model import PdfDocument


class BlankPageTests(unittest.TestCase):
    def test_inserts_same_sized_blank_pages_after_selected_pages(self):
        model = PdfDocument()
        model.doc = fitz.open()
        model.doc.new_page(width=200, height=300)
        model.doc.new_page(width=400, height=250)
        model.doc.new_page(width=612, height=792)

        inserted = model.insert_blank_after([0, 2])

        self.assertEqual(inserted, [1, 4])
        self.assertEqual(model.doc.page_count, 5)
        self.assertEqual(model.doc[1].rect, model.doc[0].rect)
        self.assertEqual(model.doc[4].rect, model.doc[3].rect)
        self.assertEqual(len(model.doc[1].get_text()), 0)
        self.assertEqual(len(model.doc[4].get_text()), 0)
        self.assertTrue(model.dirty)
        model.close()


class DeletePageTests(unittest.TestCase):
    def test_deletes_selected_pages_and_selects_nearest_remaining_page(self):
        model = PdfDocument()
        model.doc = fitz.open()
        for width in (100, 200, 300, 400):
            model.doc.new_page(width=width, height=500)

        selection = model.delete_pages([1, 3])

        self.assertEqual(selection, [1])
        self.assertEqual(model.doc.page_count, 2)
        self.assertEqual(model.doc[0].rect.width, 100)
        self.assertEqual(model.doc[1].rect.width, 300)
        self.assertTrue(model.dirty)
        model.close()

    def test_does_not_delete_every_page(self):
        model = PdfDocument()
        model.doc = fitz.open()
        model.doc.new_page()

        with self.assertRaises(ValueError):
            model.delete_pages([0])

        self.assertEqual(model.doc.page_count, 1)
        self.assertFalse(model.dirty)
        model.close()

    def test_empty_selection_does_not_modify_document(self):
        model = PdfDocument()
        model.doc = fitz.open()
        model.doc.new_page()

        self.assertEqual(model.insert_blank_after([]), [])
        self.assertEqual(model.doc.page_count, 1)
        self.assertFalse(model.dirty)
        model.close()


if __name__ == "__main__":
    unittest.main()
