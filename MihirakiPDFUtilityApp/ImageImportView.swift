import Observation
import SwiftUI

struct ImageImportFolder: Identifiable {
    let url: URL
    var id: URL { url }
}

struct ImportedImagePDF {
    let data: Data
    let name: String
}

@MainActor
@Observable
final class ImageImportModel {
    private let service = ImageImportService()
    private var files: [ImageImportFile] = []
    private(set) var orderedFiles: [ImageImportFile] = []
    var sortKey: ImageSortKey = .name {
        didSet { updateOrder() }
    }
    var direction: ImageSortDirection = .ascending {
        didSet { updateOrder() }
    }
    private(set) var isScanning = true
    private(set) var isConverting = false
    private(set) var completedCount = 0
    var errorMessage: String?

    func scan(_ folder: URL) async {
        do {
            files = try await service.files(in: folder)
            try Task.checkCancellation()
            updateOrder()
        } catch is CancellationError {
            // Closing the sheet cancels enumeration without presenting an error.
        } catch {
            errorMessage = error.localizedDescription
        }
        isScanning = false
    }

    func convert(_ folder: URL) async -> ImportedImagePDF? {
        guard !isConverting, !orderedFiles.isEmpty else { return nil }
        isConverting = true
        completedCount = 0
        errorMessage = nil
        defer { isConverting = false }
        do {
            let data = try await service.makePDF(from: orderedFiles, in: folder) { [weak self] count in
                await self?.setProgress(count)
            }
            try Task.checkCancellation()
            return ImportedImagePDF(data: data, name: folder.lastPathComponent)
        } catch is CancellationError {
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func setProgress(_ count: Int) {
        completedCount = count
    }

    private func updateOrder() {
        orderedFiles = ImageImportOrdering.sorted(files, by: sortKey, direction: direction)
    }
}

struct ImageImportView: View {
    let folder: URL
    let onComplete: (ImportedImagePDF) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var model = ImageImportModel()
    @State private var conversionTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ImageImportControls(model: model, folderName: folder.lastPathComponent)
                    .padding()
                if model.isScanning {
                    ProgressView("Reading Folder…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if model.orderedFiles.isEmpty {
                    ContentUnavailableView(
                        "No Images",
                        systemImage: "photo",
                        description: Text("No supported images were found in this folder.")
                    )
                } else {
                    List(Array(model.orderedFiles.enumerated()), id: \.element.id) { index, file in
                        ImageImportRow(number: index + 1, file: file)
                    }
                }
                ImageImportStatus(model: model)
                    .padding()
            }
            .navigationTitle("Import Images")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        conversionTask?.cancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import as PDF") {
                        conversionTask = Task {
                            if let result = await model.convert(folder), !Task.isCancelled {
                                onComplete(result)
                            }
                        }
                    }
                    .disabled(model.isScanning || model.isConverting || model.orderedFiles.isEmpty)
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 560, idealWidth: 680, minHeight: 420, idealHeight: 560)
#endif
        .interactiveDismissDisabled(model.isConverting)
        .task { await model.scan(folder) }
        .onDisappear { conversionTask?.cancel() }
    }
}

private struct ImageImportControls: View {
    @Bindable var model: ImageImportModel
    let folderName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(folderName).font(.headline)
            Text("Images directly inside this folder will become PDF pages in the order below.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ViewThatFits(in: .horizontal) {
                HStack {
                    ImageSortKeyPicker(selection: $model.sortKey)
                    ImageSortDirectionPicker(selection: $model.direction)
                }
                VStack(alignment: .leading) {
                    ImageSortKeyPicker(selection: $model.sortKey)
                    ImageSortDirectionPicker(selection: $model.direction)
                }
            }
            .disabled(model.isScanning || model.isConverting)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ImageSortKeyPicker: View {
    @Binding var selection: ImageSortKey

    var body: some View {
        Picker("Sort By", selection: $selection) {
            ForEach(ImageSortKey.allCases) { key in
                Text(key.title).tag(key)
            }
        }
        .pickerStyle(.menu)
    }
}

private struct ImageSortDirectionPicker: View {
    @Binding var selection: ImageSortDirection

    var body: some View {
        Picker("Order", selection: $selection) {
            ForEach(ImageSortDirection.allCases) { direction in
                Text(direction.title).tag(direction)
            }
        }
        .pickerStyle(.menu)
    }
}

private struct ImageImportRow: View {
    let number: Int
    let file: ImageImportFile

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number, format: .number)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.headline)
                    .textSelection(.enabled)
                ImageFileDate(title: "Creation Date", date: file.creationDate)
                ImageFileDate(title: "Modification Date", date: file.modificationDate)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ImageFileDate: View {
    let title: LocalizedStringResource
    let date: Date?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            if let date {
                Text(date, format: .dateTime.year().month().day().hour().minute().second())
            } else {
                Text("Unknown")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

private struct ImageImportStatus: View {
    let model: ImageImportModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = model.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
            if model.isConverting {
                ProgressView(value: Double(model.completedCount), total: Double(model.orderedFiles.count)) {
                    Text("Converting images: \(model.completedCount) / \(model.orderedFiles.count)")
                }
            } else if !model.isScanning {
                Text("Images: \(model.orderedFiles.count)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
