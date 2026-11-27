# Episode 4 integration verification

This opt-in test uses the current developer implementation of SamplePDFManifest / SamplePDFStore. It is separate from ordinary offline unit tests and does not imply that the public Git branch or installed App Store version has been executed.

Use a dedicated empty iOS simulator. The runner snapshots current app/test/project files into a NEW workspace outside the source repository. It never edits the source app, bundled catalog, existing PDFs, or user downloads. Network test downloads approximately 100 MB and retains the new simulator's catalog/PDF cache for manual screen verification. Missing network/invalid response/checksum mismatch fails the test; it is not silently skipped.

Example (absolute paths; replace simulator ID):

```sh
python3 integration-tests/episode4/run.py \
  --source /path/to/MihirakiPDFUtility \
  --workspace /external/new-episode4-workspace \
  --manifest integration-tests/episode4/episode4-manifest-fixture.json \
  --simulator-id YOUR-DEDICATED-SIMULATOR-ID
```

The captured 2026-11-28 manifest fixture has 52 entries. Fixture tests extend the bundled 51 entries, preserve old identities and Filipino cache aliases, retain an installed PDF without rewriting it, sort Japanese episode 4 first, and reload cached metadata offline. The live test refreshes the official manifest and uses the per-entry fixed URL (not top-level compatibility tags), checks 99,981,486 bytes and SHA-256 7c4bde39dc25800aa097854c6e47f31934abe12b3a05d97450fb73523af3c3dc, checks an eight-page document and its first/last page through PDFKit, and reloads downloaded state without network.

2026-11-28 result: developer 1.0.5 (8), iPhone 17 / iOS 27.2 simulator; 9 tests passed (2 episode-4 + 7 existing manifest tests). In the app screen, Japanese/latest-first listed episode 4 first with Downloaded/Open. After the user's CC BY 4.0 confirmation, the app opened the cover and page thumbnails. Manual two-page view showed cover on the right and page 3 left/page 2 right. PDF catalog flags TwoPageRight/R2L are metadata, not by themselves proof of reader behavior or full reading-order conformance.

Public 1.0.4 (6): archive includes manifest-refresh symbols and URL, bundled fallback remains 51 entries. Subsequent physical iPhone SE UI verification on the user-designated existing App Store installation confirmed installed 1.0.4 (6), Japanese/latest-first episode 4 listing, successful download and cover/body thumbnails. With airplane mode on and Wi-Fi off, the cached list retained downloaded episodes 3 and 4; episode 3 opened and episode 4 reopened successfully. Wi-Fi was restored afterward. The installation was not replaced; the distribution receipt was not independently inspected. Physical file size/hash extraction, a cold process restart, all-page visual order, and accessibility remain unverified on that device. The exact size/hash result above applies to the separate development simulator test. No App Store upload/submission/settings changes, PDF publication, or X post is part of this check.

The committed main branch does not yet contain the developer manifest implementation used by this run. These opt-in integration tests require that developer implementation, its existing seven manifest tests, and its 51-entry bundled catalog; they are not a claim that a clean main checkout currently passes this suite. No production implementation changes are included in this commit.
