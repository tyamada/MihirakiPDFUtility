import SwiftUI

struct SamplePDFListView: View {
    let openDocumentURL: URL?
    let openDocument: (URL) -> Void

    @Environment(\.locale) private var locale
    @State private var store = SamplePDFStore()
    @State private var cellularDownload: SamplePDF?
    @State private var deletionCandidate: SamplePDF?
    @State private var licenseCandidate: SamplePDF?
    @State private var isShowingError = false
    @State private var selectedLanguageCode: String?
    @State private var visibleSamples: [SamplePDF] = []
    @State private var languageCodes: [String] = []

    var body: some View {
        SamplePDFListContent(
            catalog: store.catalog,
            samples: visibleSamples,
            languageCodes: languageCodes,
            selectedLanguageCode: $selectedLanguageCode,
            locale: locale,
            state: store.state(for:),
            isOpen: isOpen(_:),
            isDownloadEnabled: store.isNetworkPathKnown,
            downloadAction: requestDownload(_:),
            openAction: { licenseCandidate = $0 },
            deleteAction: { deletionCandidate = $0 }
        )
        .navigationTitle("Sample PDFs")
        .task {
            store.loadCatalog()
            configureCatalog()
        }
        .onChange(of: selectedLanguageCode) {
            updateVisibleSamples()
        }
        .onChange(of: store.errorMessage) { _, message in
            isShowingError = message != nil
        }
        .sheet(item: $licenseCandidate) { sample in
            SamplePDFLicenseDialog(
                sampleTitle: sample.title,
                sourceURL: sample.downloadURL,
                license: store.catalog?.license
            ) {
                openDocument(store.localURL(for: sample))
            }
        }
        .alert(
            "Download Using Mobile Data?",
            isPresented: Binding(
                get: { cellularDownload != nil },
                set: { if !$0 { cellularDownload = nil } }
            ),
            presenting: cellularDownload
        ) { sample in
            Button("Cancel", role: .cancel) {
                cellularDownload = nil
            }
            Button("Download") {
                cellularDownload = nil
                startDownload(sample, allowsCellular: true)
            }
        } message: { sample in
            Text("This PDF is \(sample.formattedFileSize). Downloading it will use mobile data.")
        }
        .alert(
            "Delete Sample PDF?",
            isPresented: Binding(
                get: { deletionCandidate != nil },
                set: { if !$0 { deletionCandidate = nil } }
            ),
            presenting: deletionCandidate
        ) { sample in
            Button("Cancel", role: .cancel) {
                deletionCandidate = nil
            }
            Button("Delete", role: .destructive) {
                _ = store.delete(sample)
                deletionCandidate = nil
            }
        } message: { sample in
            Text("Delete \(sample.title) from this device?")
        }
        .alert("Unable to Complete the Operation", isPresented: $isShowingError) {
            Button("OK") {
                store.errorMessage = nil
            }
        } message: {
            Text(store.errorMessage ?? String(localized: "An unknown error occurred."))
        }
    }

    private func configureCatalog() {
        guard let catalog = store.catalog else { return }
        languageCodes = SamplePDFLanguageFilter.availableLanguageCodes(in: catalog.samples)
        selectedLanguageCode = SamplePDFLanguageFilter.initialLanguageCode(
            preferredLanguages: Locale.preferredLanguages,
            availableLanguageCodes: languageCodes
        )
        updateVisibleSamples()
    }

    private func updateVisibleSamples() {
        guard let samples = store.catalog?.samples else {
            visibleSamples = []
            return
        }
        guard let selectedLanguageCode else {
            visibleSamples = samples
            return
        }
        visibleSamples = samples.filter { $0.languageCode == selectedLanguageCode }
    }

    private func requestDownload(_ sample: SamplePDF) {
        if store.isUsingCellular {
            cellularDownload = sample
        } else {
            startDownload(sample, allowsCellular: false)
        }
    }

    private func startDownload(_ sample: SamplePDF, allowsCellular: Bool) {
        Task {
            await store.download(sample, allowsCellular: allowsCellular)
        }
    }

    private func isOpen(_ sample: SamplePDF) -> Bool {
        guard let openDocumentURL else { return false }
        return openDocumentURL.standardizedFileURL
            == store.localURL(for: sample).standardizedFileURL
    }
}

private struct SamplePDFListContent: View {
    let catalog: SamplePDFCatalog?
    let samples: [SamplePDF]
    let languageCodes: [String]
    @Binding var selectedLanguageCode: String?
    let locale: Locale
    let state: (SamplePDF) -> SamplePDFDownloadState
    let isOpen: (SamplePDF) -> Bool
    let isDownloadEnabled: Bool
    let downloadAction: (SamplePDF) -> Void
    let openAction: (SamplePDF) -> Void
    let deleteAction: (SamplePDF) -> Void

    var body: some View {
        if let catalog {
            List {
                SamplePDFLanguageFilterPicker(
                    languageCodes: languageCodes,
                    selectedLanguageCode: $selectedLanguageCode,
                    locale: locale
                )

                Section {
                    ForEach(samples) { sample in
                        SamplePDFRow(
                            sample: sample,
                            languageName: sample.languageDisplayName(locale: locale),
                            state: state(sample),
                            isOpen: isOpen(sample),
                            isDownloadEnabled: isDownloadEnabled,
                            downloadAction: { downloadAction(sample) },
                            openAction: { openAction(sample) },
                            deleteAction: { deleteAction(sample) }
                        )
                    }
                } footer: {
                    Text("Opening a sample displays its CC BY 4.0 license information first.")
                }

                Section("License") {
                    Link(destination: catalog.license.url) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(catalog.license.name)
                            Text("Catalog provided by \(catalog.license.creator)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "The sample PDF list could not be loaded.",
                systemImage: "doc.badge.ellipsis"
            )
        }
    }
}

private struct SamplePDFLanguageFilterPicker: View {
    let languageCodes: [String]
    @Binding var selectedLanguageCode: String?
    let locale: Locale

    var body: some View {
        Section {
            Picker("Language", selection: $selectedLanguageCode) {
                Text("All").tag(nil as String?)

                ForEach(languageCodes, id: \.self) { languageCode in
                    Text(locale.localizedString(forLanguageCode: languageCode) ?? languageCode)
                        .tag(Optional(languageCode))
                }
            }
        }
    }
}

private struct SamplePDFRow: View {
    let sample: SamplePDF
    let languageName: String
    let state: SamplePDFDownloadState
    let isOpen: Bool
    let isDownloadEnabled: Bool
    let downloadAction: () -> Void
    let openAction: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(sample.title)
                .font(.headline)

            Text(verbatim: "\(languageName) · \(sample.formattedFileSize)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            SamplePDFRowAction(
                state: state,
                isOpen: isOpen,
                isDownloadEnabled: isDownloadEnabled,
                downloadAction: downloadAction,
                openAction: openAction,
                deleteAction: deleteAction
            )
        }
        .padding(.vertical, 4)
    }
}

private struct SamplePDFRowAction: View {
    let state: SamplePDFDownloadState
    let isOpen: Bool
    let isDownloadEnabled: Bool
    let downloadAction: () -> Void
    let openAction: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        HStack {
            switch state {
            case .notDownloaded:
                Button("Download", systemImage: "arrow.down.circle", action: downloadAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(!isDownloadEnabled)
            case .downloading:
                ProgressView()
                Text("Downloading…")
            case .downloaded:
                Label("Downloaded", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                Spacer()

                Button("Open", action: openAction)
                    .disabled(isOpen)

                Button("Delete", role: .destructive, action: deleteAction)
                    .disabled(isOpen)
            case .deleting:
                ProgressView()
                Text("Deleting…")
            }
        }
    }
}

private struct SamplePDFLicenseDialog: View {
    let sampleTitle: String
    let sourceURL: URL
    let license: SamplePDFLicense?
    let openAction: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SamplePDFLicenseSummary(sampleTitle: sampleTitle)
                    SamplePDFAttributionRequirements(sourceURL: sourceURL, license: license)
                    SamplePDFLicenseNotice()
                }
                .padding()
                .frame(maxWidth: 620, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("CC BY 4.0 License")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Agree and Open") {
                        openAction()
                    }
                }
            }
        }
    }
}

private struct SamplePDFLicenseSummary: View {
    let sampleTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sampleTitle)
                .font(.headline)

            Text("This sample is provided under the Creative Commons Attribution 4.0 International license (CC BY 4.0). You may share and adapt it, including for commercial purposes.")
        }
    }
}

private struct SamplePDFAttributionRequirements: View {
    let sourceURL: URL
    let license: SamplePDFLicense?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("When reusing this work")
                .font(.headline)

            Label("Credit the work title and the author, Komairo Hiyori.", systemImage: "person.text.rectangle")
            Label("Include the original source and a link to the license.", systemImage: "link")
            Label("Clearly indicate whether you made any changes.", systemImage: "pencil.and.list.clipboard")
            Label("Do not imply that the author endorses you or your use.", systemImage: "hand.raised")

            Link("Open the original source", destination: sourceURL)
            if let license {
                Link("Read the full \(license.identifier) license", destination: license.url)
            }
        }
    }
}

private struct SamplePDFLicenseNotice: View {
    var body: some View {
        Text("Third-party materials, including fonts, may have separate license terms. The license does not replace permissions that may be required for privacy, publicity, moral, or other rights.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}
