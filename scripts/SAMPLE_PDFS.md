# Sample PDF integration inputs

The user-facing list is maintained at <https://tyamada.github.io/manga-prompt-kit/samples/en/> (Japanese: <https://tyamada.github.io/manga-prompt-kit/samples/ja/>). Do not rebuild PDF lists in README or HTML. Maintenance: <https://github.com/tyamada/manga-prompt-kit/blob/main/docs/sample-download-maintenance.md>.

The app's machine-readable catalog, latest-manifest support, stable sample IDs, Filipino `fil` cache aliases, verified cache, and user downloads are independent of this documentation cleanup. Do not rewrite them to web page URLs.

Unit tests create small synthetic PDFs and need no manga download. Real manga is an explicit integration input, not a test that silently passes when files are missing. The Xcode project does not bundle `docs/sample` or `testdata` manga. No preparation command copies PDFs back into those directories.

Download `pdf-manifest.json` from the fixed `manga-pdf-20261103-v1` Release and verify its SHA-256 against the approved record. The 2026-11-20 approved manifest SHA-256 is `4ffcdc152b18fe631b7db4f749907caa1ccf5888511137784d23774abf5d7ed4`. Prepare only the samples required for a recording or integration check:

```sh
python3 scripts/prepare_sample_pdfs.py /path/to/pdf-manifest.json \
  --manifest-sha256 4ffcdc152b18fe631b7db4f749907caa1ccf5888511137784d23774abf5d7ed4 \
  --sample-id ep1_ja --sample-id ep1_zh_hk \
  --cache-directory /absolute/path/outside-this-repository/sample-cache \
  --download
```

For offline preparation use `--input-directory /path/to/verified-release-pdfs` instead of `--download`. Inputs use the Release filename (`_tl.pdf` for Filipino). Existing cache files are verified and reused; size, PDF signature, or SHA-256 failures stop the operation without replacing them. Missing offline input is an error. This cache is separate from the app's on-device cache and user PDFs.

To compare all 51 entries of an explicitly chosen app catalog against the Release evidence (`pdf-manifest.json`, `pdf-migration.csv`, `SHA256SUMS`), use:

```sh
python3 scripts/verify_sample_distribution.py /path/to/release-evidence \
  --catalog /path/to/SamplePDFCatalog.json
```

Optional `--download-directory /external/cache --sample-id ep1_ja` performs selected HTTPS integration checks. The caller must use a catalog corresponding to that Release; the verifier never updates it. Run offline helper tests with `python3 -m unittest discover -s scripts -p test_prepare_sample_pdfs.py`.

## Retained legacy files

See [the current retirement policy and inventory](../docs/sample-pdf-retirement-2026-11-24.md). Obsolete Pages copies are removed without changing Release assets, machine catalogs, technical regression fixtures, migration evidence or on-device PDFs. Untracked local inputs and original working copies remain untouched. Shipped 1.0.0/1.0.1 and the current main catalog reference Android Releases; preserve those Releases. Git history is retained for recovery; this is not a history rewrite.
