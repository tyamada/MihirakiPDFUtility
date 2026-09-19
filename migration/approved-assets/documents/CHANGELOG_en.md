# Changelog

[日本語](CHANGELOG.md) | [English](CHANGELOG_en.md)

## 0.3.3 - 2026-09-09

- Build distribution deb packages on Ubuntu 22.04 to support Ubuntu 22.04 and later, and complete the X11 dependency declarations
- Move full license texts and third-party notices from the About dialog to a dedicated dialog, and add Licenses to the Help menu
- Verify Windows EXE / MSIX and Linux deb / Snap builds on ARM64
- Fix line endings in Linux scripts, the Snap output location, and the font configuration dependency on minimal Debian installations
- Add build-time source snapshots and records linking distribution artifacts to their sources, and fix the recorded source ZIP filename

## 0.3.2 - 2026-09-07

- Fix the About dialog so it works during normal startup even when package metadata for WinRT or other dependencies is unavailable
- Add copyright information, full license texts, third-party notices, and a source code link to the About dialog
- Bundle license documents and dependency notices in builds for all operating systems

## 0.3.1 - 2026-09-06

- Immediately update the page display description and layout change guidance when the cover page checkbox changes
- Add Page display to the Details tab in Document Properties and display a live explanation of the selected page layout
- Align the page display description to the top and fix a translation error when selecting a cover page

## 0.3.0 - 2026-09-04

- Change the project license to GNU Affero General Public License v3.0
- Centralize the application version and automatically apply it to metadata for each package format
- Add a new Folimeld application icon and images for each operating system and Microsoft Store
- Move PDF file associations to the MSIX manifest
- Support building x64 MSIX packages for Microsoft Store
- Add ARM64 MSIX build instructions and detection of architecture mismatches
- Reorganize the README for publication on GitHub and move development instructions and the changelog into separate documents

## 0.2.5 - 2026-09-03

- Improve scrolling behavior

## 0.2.4 - 2026-08-31

- Add Ubuntu support

## 0.2.3 - 2026-08-31

- Support automatic PDF version changes

## 0.2.2 - 2026-08-30

- Set up macOS build instructions, icons, and signing

## 0.2.1 - 2026-08-30

- Safely disable Windows-specific operations on macOS

## 0.2.0 - 2026-08-30

- Rename the application to Folimeld

## 0.1.0 - 2026-08-29

- Initial release
