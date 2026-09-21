import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Bindable var model: PDFEditorModel

    @State private var isImporting = false
    @State private var isAppending = false
    @State private var isExporting = false
    @State private var isConfirmingOpen = false
    @State private var isPresentingProperties = false
    @State private var isSettingPassword = false
    @State private var isRequestingPassword = false
    @State private var exportDocument: PDFExportDocument?
    @State private var pendingOpenURL: URL?
    @State private var password = ""
    @State private var passwordMessage: LocalizedStringResource = "Enter the password required to open this PDF."
    @State private var newPassword = ""
    @State private var confirmedPassword = ""
    @State private var newPasswordMessage: LocalizedStringResource = "Enter the new viewing password twice."

    var body: some View {
        NavigationStack {
            Group {
                if model.pages.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("Open a PDF")
                        } icon: {
                            Image(systemName: "doc.richtext")
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Open a PDF")
                    } description: {
                        Text("Choose a PDF to arrange, rotate, or remove pages.")
                    } actions: {
                        Button("Open PDF") {
                            isImporting = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    pageList
                }
            }
            .navigationTitle(model.isModified ? "\(model.displayName) *" : model.displayName)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Save", systemImage: "square.and.arrow.down") {
                        prepareExport()
                    }
                    .disabled(model.document == nil)

                    Menu("Document", systemImage: "folder") {
                        Button("Open", systemImage: "folder") {
                            isImporting = true
                        }

                        Button("Add PDF", systemImage: "doc.badge.plus") {
                            isAppending = true
                        }
                        .disabled(model.document == nil)

                        Divider()

                        Button("Properties", systemImage: "info.circle") {
                            isPresentingProperties = true
                        }
                        .disabled(model.document == nil)

                        Button("Set Password", systemImage: "lock") {
                            isSettingPassword = true
                        }
                        .disabled(model.document == nil)

                        Button("Remove Password", systemImage: "lock.open") {
                            model.setViewingPassword(nil)
                        }
                        .disabled(!model.hasViewingPassword)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Edit Pages", systemImage: "ellipsis.circle") {
                        Button("Select All", systemImage: "checkmark.circle") {
                            model.selectAllPages()
                        }
                        .disabled(!model.canSelectAll)

                        Button("Deselect All", systemImage: "circle") {
                            model.clearSelection()
                        }
                        .disabled(model.selection.isEmpty)

                        Divider()

                        Button("Move Earlier", systemImage: "arrow.up") {
                            model.moveSelectionEarlier()
                        }
                        .disabled(!model.canMoveEarlier)

                        Button("Move Later", systemImage: "arrow.down") {
                            model.moveSelectionLater()
                        }
                        .disabled(!model.canMoveLater)

                        Button("Rotate Left", systemImage: "rotate.left") {
                            model.rotateSelection(by: -90)
                        }
                        .disabled(!model.canEdit)

                        Button("Rotate Right", systemImage: "rotate.right") {
                            model.rotateSelection(by: 90)
                        }
                        .disabled(!model.canEdit)

                        Button("Insert Blank", systemImage: "doc.badge.plus") {
                            model.insertBlankPagesAfterSelection()
                        }
                        .disabled(!model.canEdit)

                        Divider()

                        Button("Delete", systemImage: "trash", role: .destructive) {
                            model.deleteSelection()
                        }
                        .disabled(!model.canDelete)
                    }
                }
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.pdf]) { result in
            if case let .success(url) = result {
                requestOpen(url)
            } else if case let .failure(error) = result {
                presentFileErrorUnlessCancelled(error)
            }
        }
        .fileImporter(isPresented: $isAppending, allowedContentTypes: [.pdf]) { result in
            if case let .success(url) = result {
                if case .passwordRequired = model.append(url) {
                    password = ""
                    passwordMessage = "Enter the password required to open this PDF."
                    isRequestingPassword = true
                }
            } else if case let .failure(error) = result {
                presentFileErrorUnlessCancelled(error)
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .pdf,
            defaultFilename: model.displayName
        ) { result in
            switch result {
            case .success(let url):
                model.didExport(to: url)
                if let pendingOpenURL {
                    openDocument(pendingOpenURL)
                    self.pendingOpenURL = nil
                }
            case .failure(let error):
                presentFileErrorUnlessCancelled(error)
                pendingOpenURL = nil
            }
            exportDocument = nil
        }
        .confirmationDialog(
            "Unsaved Changes",
            isPresented: $isConfirmingOpen,
            titleVisibility: .visible
        ) {
            Button("Save and Open") {
                prepareExport()
            }
            Button("Open Without Saving", role: .destructive) {
                openPendingDocument()
            }
            Button("Cancel", role: .cancel) {
                pendingOpenURL = nil
            }
        } message: {
            Text("Save your changes before opening another PDF?")
        }
        .alert("Password Required", isPresented: $isRequestingPassword) {
            SecureField("Password", text: $password)
            Button("Open") {
                if model.unlockPendingDocument(with: password) {
                    password = ""
                    passwordMessage = "Enter the password required to open this PDF."
                } else {
                    password = ""
                    passwordMessage = "The password is incorrect. Try again."
                    isRequestingPassword = true
                }
            }
            Button("Cancel", role: .cancel) {
                password = ""
                passwordMessage = "Enter the password required to open this PDF."
                model.cancelPendingUnlock()
            }
        } message: {
            Text(passwordMessage)
        }
        .alert("Set Viewing Password", isPresented: $isSettingPassword) {
            SecureField("New Password", text: $newPassword)
            SecureField("Confirm Password", text: $confirmedPassword)
            Button("Set") {
                if !newPassword.isEmpty, newPassword == confirmedPassword {
                    model.setViewingPassword(newPassword)
                    clearNewPasswordFields()
                } else {
                    newPasswordMessage = newPassword.isEmpty
                        ? "The password cannot be empty."
                        : "The passwords do not match."
                    isSettingPassword = true
                }
            }
            Button("Cancel", role: .cancel) {
                clearNewPasswordFields()
            }
        } message: {
            Text(newPasswordMessage)
        }
        .alert("Unable to Complete the Operation", isPresented: errorPresented) {
            Button("OK") {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "An unknown error occurred.")
        }
        .sheet(isPresented: $isPresentingProperties) {
            PDFPropertiesView(pageCount: model.pages.count, metadata: model.metadata) { metadata in
                model.updateMetadata(metadata)
            }
        }
        .onOpenURL { url in
            requestOpen(url)
        }
    }

    private var pageList: some View {
        List(selection: $model.selection) {
            ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, item in
                PDFPageRow(pageNumber: index + 1, page: item.page)
                    .tag(item.id)
            }
            .onMove(perform: model.movePages)
        }
        .environment(\.editMode, .constant(.active))
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    model.errorMessage = nil
                }
            }
        )
    }

    private func prepareExport() {
        do {
            exportDocument = try model.exportDocument()
            isExporting = true
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }

    private func requestOpen(_ url: URL) {
        guard model.isModified else {
            openDocument(url)
            return
        }

        pendingOpenURL = url
        isConfirmingOpen = true
    }

    private func openPendingDocument() {
        guard let pendingOpenURL else { return }
        openDocument(pendingOpenURL)
        self.pendingOpenURL = nil
    }

    private func openDocument(_ url: URL) {
        if case .passwordRequired = model.open(url) {
            password = ""
            passwordMessage = "Enter the password required to open this PDF."
            isRequestingPassword = true
        }
    }

    private func clearNewPasswordFields() {
        newPassword = ""
        confirmedPassword = ""
        newPasswordMessage = "Enter the new viewing password twice."
    }

    private func presentFileErrorUnlessCancelled(_ error: Error) {
        let cocoaError = error as NSError
        guard cocoaError.domain != NSCocoaErrorDomain
                || cocoaError.code != NSUserCancelledError else { return }
        model.errorMessage = error.localizedDescription
    }
}

private struct PDFPropertiesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var metadata: PDFMetadata

    let pageCount: Int
    let onSave: (PDFMetadata) -> Void

    init(pageCount: Int, metadata: PDFMetadata, onSave: @escaping (PDFMetadata) -> Void) {
        self.pageCount = pageCount
        _metadata = State(initialValue: metadata)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("Pages") {
                    Text(pageCount, format: .number)
                }

                TextField("Title", text: $metadata.title)
                TextField("Author", text: $metadata.author)
                TextField("Subject", text: $metadata.subject)
                TextField("Keywords, separated by commas", text: $metadata.keywords)
            }
            .navigationTitle("Document Properties")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onSave(metadata)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct PDFPageRow: View {
    let pageNumber: Int
    let page: PDFPage

    var body: some View {
        HStack(spacing: 16) {
            Image(uiImage: page.thumbnail(of: CGSize(width: 120, height: 160), for: .cropBox))
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 96)
                .background(.white)
                .shadow(radius: 2)
                .accessibilityHidden(true)

            Text("Page \(pageNumber)")
                .font(.headline)

            Spacer()
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Page \(pageNumber)")
    }
}
