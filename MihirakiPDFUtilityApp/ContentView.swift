import PDFKit
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#endif

private struct WrappingHStack: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let result = layoutSubviews(subviews, availableWidth: proposal.width ?? .infinity)
        return CGSize(
            width: proposal.width ?? result.width,
            height: result.height
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layoutSubviews(subviews, availableWidth: bounds.width)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                anchor: .topLeading,
                proposal: .unspecified
            )
        }
    }

    private func layoutSubviews(
        _ subviews: Subviews,
        availableWidth: CGFloat
    ) -> (positions: [CGPoint], width: CGFloat, height: CGFloat) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > 0, currentX + size.width > availableWidth {
                currentX = 0
                currentY += rowHeight + verticalSpacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            usedWidth = max(usedWidth, currentX + size.width)
            currentX += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        return (
            positions,
            usedWidth,
            subviews.isEmpty ? 0 : currentY + rowHeight
        )
    }
}

private enum ThumbnailAction: CaseIterable, Identifiable {
    case open
    case save
    case undo
    case redo
    case insertPDF
    case insertBlankPage
    case delete
    case moveEarlier
    case moveLater
    case rotateLeft
    case rotateRight

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .open: "Open"
        case .save: "Save"
        case .undo: "Undo"
        case .redo: "Redo"
        case .insertPDF: "Insert PDF"
        case .insertBlankPage: "Insert Same-Size Blank Page After"
        case .delete: "Delete"
        case .moveEarlier: "Move Earlier"
        case .moveLater: "Move Later"
        case .rotateLeft: "Rotate Left"
        case .rotateRight: "Rotate Right"
        }
    }

    var systemImage: String {
        switch self {
        case .open: "folder"
        case .save: "square.and.arrow.down"
        case .undo: "arrow.uturn.backward"
        case .redo: "arrow.uturn.forward"
        case .insertPDF, .insertBlankPage: "doc.badge.plus"
        case .delete: "trash"
        case .moveEarlier: "arrow.left"
        case .moveLater: "arrow.right"
        case .rotateLeft: "rotate.left"
        case .rotateRight: "rotate.right"
        }
    }
}

private enum MainViewMode: String, CaseIterable, Identifiable {
    case list
    case thumbnails

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .list: "List"
        case .thumbnails: "Thumbnails"
        }
    }

    var systemImage: String {
        switch self {
        case .list: "list.bullet"
        case .thumbnails: "square.grid.2x2"
        }
    }
}

struct ContentView: View {
    @Bindable var model: PDFEditorModel
    @State private var tipManager = TipManager()
    @State private var viewMode: MainViewMode
    @State private var previewedPageID: PDFPageItem.ID?

    @State private var isImporting = false
    @State private var isImportingFromEmptyState = false
    @State private var isAppending = false
    @State private var isExporting = false
    @State private var isExportingSelection = false
    @State private var isConfirmingOpen = false
    @State private var isPresentingProperties = false
    @State private var isPresentingVersionInformation = false
    @State private var isPresentingHelp = false
    @State private var isPresentingSupport = false
    @State private var isSettingPassword = false
    @State private var isRequestingPassword = false
    @State private var exportDocument: PDFExportDocument?
    @State private var selectionExportDocument: PDFExportDocument?
    @State private var pendingOpenURL: URL?
    @State private var password = ""
    @State private var passwordMessage: LocalizedStringResource = "Enter the password required to open this PDF."
    @State private var newPassword = ""
    @State private var confirmedPassword = ""
    @State private var newPasswordMessage: LocalizedStringResource = "Enter the new viewing password twice."

    init(model: PDFEditorModel) {
        self.model = model
#if os(macOS)
        _viewMode = State(initialValue: .thumbnails)
#else
        _viewMode = State(initialValue: UIDevice.current.userInterfaceIdiom == .pad ? .thumbnails : .list)
#endif
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                Group {
                    if model.pages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.richtext")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)

                        Text("Open a PDF")
                            .font(.title3.weight(.semibold))

                        Text("Choose a PDF to arrange, rotate, or remove pages.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Open PDF") {
                            presentEmptyStateImporter()
                        }
                        .buttonStyle(.borderedProminent)
                        .fileImporter(
                            isPresented: $isImportingFromEmptyState,
                            allowedContentTypes: [.pdf]
                        ) { result in
                            handleOpenImport(result)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    switch viewMode {
                    case .list:
                        pageList
                    case .thumbnails:
                        thumbnailWorkspace
                    }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .id(geometry.size)
            }
            .navigationTitle(model.isModified ? "\(model.displayName) *" : model.displayName)
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button("Save", systemImage: "square.and.arrow.down") {
                        prepareExport()
                    }
                    .disabled(model.document == nil)

                    Button("Document", systemImage: "folder") {
                        isImporting = true
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Picker("View", selection: $viewMode) {
                        ForEach(MainViewMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.systemImage)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.menu)

                    Menu("Edit Pages", systemImage: "ellipsis.circle") {
                        Button("Add PDF", systemImage: "doc.badge.plus") {
                            isAppending = true
                        }
                        .disabled(model.document == nil)

                        Divider()

                        Button("Select All", systemImage: "checkmark.circle") {
                            model.selectAllPages()
                        }
                        .disabled(!model.canSelectAll)

                        Button("Deselect All", systemImage: "circle") {
                            model.clearSelection()
                        }
                        .disabled(model.selection.isEmpty)

                        Button("Save Selection", systemImage: "square.and.arrow.down") {
                            prepareSelectionExport()
                        }
                        .disabled(!model.canEdit)

                        Divider()

                        Button("Move to Beginning", systemImage: "arrow.up.to.line") {
                            model.moveSelectionToBeginning()
                        }
                        .disabled(!model.canMoveEarlier)

                        Button("Move Earlier", systemImage: "arrow.up") {
                            model.moveSelectionEarlier()
                        }
                        .disabled(!model.canMoveEarlier)

                        Button("Move Later", systemImage: "arrow.down") {
                            model.moveSelectionLater()
                        }
                        .disabled(!model.canMoveLater)

                        Button("Move to End", systemImage: "arrow.down.to.line") {
                            model.moveSelectionToEnd()
                        }
                        .disabled(!model.canMoveLater)

                        Button("Reverse Selection", systemImage: "arrow.up.arrow.down") {
                            model.reverseSelectionOrder()
                        }
                        .disabled(!model.canReverseSelection)

                        Button("Rotate Left", systemImage: "rotate.left") {
                            model.rotateSelection(by: -90)
                        }
                        .disabled(!model.canEdit)

                        Button("Rotate Right", systemImage: "rotate.right") {
                            model.rotateSelection(by: 90)
                        }
                        .disabled(!model.canEdit)

                        Button("Duplicate", systemImage: "plus.square.on.square") {
                            model.duplicateSelection()
                        }
                        .disabled(!model.canEdit)

                        Button("Insert Blank Before", systemImage: "doc.badge.plus") {
                            model.insertBlankPagesBeforeSelection()
                        }
                        .disabled(!model.canEdit)

                        Button("Insert Blank After", systemImage: "doc.badge.plus") {
                            model.insertBlankPagesAfterSelection()
                        }
                        .disabled(!model.canEdit)

                        Divider()

                        Button("Delete", systemImage: "trash", role: .destructive) {
                            model.deleteSelection()
                        }
                        .disabled(!model.canDelete)
                    }

                    Menu("Settings", systemImage: "gearshape") {
                        Button("Properties", systemImage: "doc.text.magnifyingglass") {
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

                        Divider()

                        Button("Version Information", systemImage: "info.circle") {
                            isPresentingVersionInformation = true
                        }

                        Button("Help", systemImage: "questionmark.circle") {
                            isPresentingHelp = true
                        }

                        Button("Support the Developer", systemImage: "heart") {
                            isPresentingSupport = true
                        }
                    }
                }
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.pdf]) { result in
            handleOpenImport(result)
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
        .fileExporter(
            isPresented: $isExportingSelection,
            document: selectionExportDocument,
            contentType: .pdf,
            defaultFilename: "\(model.displayName)-selection"
        ) { result in
            if case let .failure(error) = result {
                presentFileErrorUnlessCancelled(error)
            }
            selectionExportDocument = nil
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
            PDFPropertiesView(
                fileName: model.sourceURL?.lastPathComponent ?? model.displayName,
                pageCount: model.pages.count,
                pdfVersion: model.documentDetails.pdfVersion,
                metadata: model.metadata,
                viewerPreferences: model.documentDetails.viewerPreferences
            ) { metadata, viewerPreferences in
                model.updateMetadata(metadata)
                model.updateViewerPreferences(viewerPreferences)
            }
        }
        .sheet(isPresented: $isPresentingVersionInformation) {
            AppVersionInformationView(info: AppVersionInfo())
        }
        .sheet(isPresented: $isPresentingHelp) {
            HelpView()
        }
        .sheet(isPresented: $isPresentingSupport) {
            TipSupportView(tipManager: tipManager)
        }
#if os(macOS)
        .sheet(item: previewedPage) { item in
            PDFPagePreview(page: item.page)
                .frame(minWidth: 720, minHeight: 720)
        }
#else
        .fullScreenCover(item: previewedPage) { item in
            PDFPagePreview(page: item.page)
        }
#endif
        .onOpenURL { url in
            requestOpen(url)
        }
    }

    private var pageList: some View {
#if os(macOS)
        pageListContent
#else
        pageListContent
            .environment(\.editMode, .constant(.active))
#endif
    }

    private var pageListContent: some View {
        List(selection: $model.selection) {
            ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, item in
                PDFPageRow(pageNumber: index + 1, page: item.page)
                    .tag(item.id)
            }
            .onMove(perform: model.movePages)
        }
    }

    private var thumbnailWorkspace: some View {
        VStack(spacing: 0) {
            thumbnailControls
            Divider()

            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 20)],
                    spacing: 24
                ) {
                    ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, item in
                        PDFPageThumbnail(
                            pageNumber: index + 1,
                            page: item.page,
                            isSelected: model.selection.contains(item.id)
                        )
                        .contentShape(.rect)
                        .onTapGesture(count: 2) {
                            previewedPageID = item.id
                        }
                        .onTapGesture {
                            toggleSelection(of: item.id)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var thumbnailControls: some View {
        WrappingHStack(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(ThumbnailAction.allCases) { action in
                thumbnailActionButton(action)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .buttonStyle(.bordered)
        .labelStyle(.titleAndIcon)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func thumbnailActionButton(_ action: ThumbnailAction) -> some View {
        Button {
            perform(action)
        } label: {
            Label(action.title, systemImage: action.systemImage)
        }
        .disabled(!isEnabled(action))
    }

    private func perform(_ action: ThumbnailAction) {
        switch action {
        case .open:
            isImporting = true
        case .save:
            prepareExport()
        case .undo:
            model.undo()
        case .redo:
            model.redo()
        case .insertPDF:
            isAppending = true
        case .insertBlankPage:
            model.insertBlankPagesAfterSelection()
        case .delete:
            model.deleteSelection()
        case .moveEarlier:
            model.moveSelectionEarlier()
        case .moveLater:
            model.moveSelectionLater()
        case .rotateLeft:
            model.rotateSelection(by: -90)
        case .rotateRight:
            model.rotateSelection(by: 90)
        }
    }

    private func isEnabled(_ action: ThumbnailAction) -> Bool {
        switch action {
        case .open:
            true
        case .save, .insertPDF:
            model.document != nil
        case .undo:
            model.canUndo
        case .redo:
            model.canRedo
        case .insertBlankPage, .rotateLeft, .rotateRight:
            model.canEdit
        case .delete:
            model.canDelete
        case .moveEarlier:
            model.canMoveEarlier
        case .moveLater:
            model.canMoveLater
        }
    }

    private var previewedPage: Binding<PDFPageItem?> {
        Binding(
            get: {
                guard let previewedPageID else { return nil }
                return model.pages.first { $0.id == previewedPageID }
            },
            set: { previewedPageID = $0?.id }
        )
    }

    private func toggleSelection(of id: PDFPageItem.ID) {
        if model.selection.contains(id) {
            model.selection.remove(id)
        } else {
            model.selection.insert(id)
        }
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

    private func prepareSelectionExport() {
        do {
            selectionExportDocument = try model.exportSelectionDocument()
            isExportingSelection = true
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

    private func handleOpenImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            requestOpen(url)
        case .failure(let error):
            presentFileErrorUnlessCancelled(error)
        }
    }

    private func presentEmptyStateImporter() {
        Task { @MainActor in
            await Task.yield()
            isImportingFromEmptyState = true
        }
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

private struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Documents") {
                    Label("Use Document to open a PDF.", systemImage: "folder")
                    Label("Use Save to export the edited PDF.", systemImage: "square.and.arrow.down")
                }

                Section("Edit Pages") {
                    Label("Add another PDF from the Edit Pages menu.", systemImage: "doc.badge.plus")
                    Label("Select pages to move, rotate, duplicate, or delete them.", systemImage: "rectangle.stack")
                }

                Section("Settings") {
                    Label("View properties and change PDF metadata.", systemImage: "doc.text.magnifyingglass")
                    Label("Set or remove the PDF viewing password.", systemImage: "lock")
                }
            }
            .navigationTitle("Help")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct AppVersionInformationView: View {
    @Environment(\.dismiss) private var dismiss

    let info: AppVersionInfo

    var body: some View {
        NavigationStack {
            Form {
                Section("Application") {
                    LabeledContent("App Name", value: info.appName)
                    LabeledContent("Version", value: info.versionNumber)
                    LabeledContent("Build", value: info.buildNumber)
                    LabeledContent("Copyright", value: info.copyright)
                }

                Section("License") {
                    Text(info.license)
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Version Information")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct PDFPropertiesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var metadata: PDFMetadata
    @State private var viewerPreferences: PDFViewerPreferences

    let fileName: String
    let pageCount: Int
    let pdfVersion: PDFVersion?
    let onSave: (PDFMetadata, PDFViewerPreferences) -> Void

    init(
        fileName: String,
        pageCount: Int,
        pdfVersion: PDFVersion?,
        metadata: PDFMetadata,
        viewerPreferences: PDFViewerPreferences,
        onSave: @escaping (PDFMetadata, PDFViewerPreferences) -> Void
    ) {
        self.fileName = fileName
        self.pageCount = pageCount
        self.pdfVersion = pdfVersion
        _metadata = State(initialValue: metadata)
        _viewerPreferences = State(initialValue: viewerPreferences)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Overview") {
                    LabeledContent("File Name", value: fileName)

                    LabeledContent("Pages") {
                        Text(pageCount, format: .number)
                    }

                    TextField("Title", text: $metadata.title)
                    TextField("Author", text: $metadata.author)
                    TextField("Subject", text: $metadata.subject)
                    TextField("Keywords, separated by commas", text: $metadata.keywords)
                }

                Section("Details") {
                    LabeledContent("PDF Version", value: displayedPDFVersion)

                    Picker("Page Layout", selection: $viewerPreferences.pageLayout) {
                        ForEach(PDFPageLayout.allCases) { layout in
                            Text(layout.localizedName).tag(layout)
                        }
                    }

                    Toggle("Show Cover", isOn: displaysCover)
                        .disabled(!viewerPreferences.canDisplayCover)

                    LabeledContent("Page Display") {
                        Text(viewerPreferences.pageDisplayStyle.localizedDescription)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker("Scroll Direction", selection: readingDirection) {
                        ForEach(PDFReadingDirection.allCases) { direction in
                            Text(direction.localizedName).tag(direction)
                        }
                    }
                }
            }
            .navigationTitle("Document Properties")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onSave(metadata, viewerPreferences)
                        dismiss()
                    }
                }
            }
        }
    }

    private var displaysCover: Binding<Bool> {
        Binding(
            get: { viewerPreferences.displaysCover },
            set: { viewerPreferences.setDisplaysCover($0) }
        )
    }

    private var displayedPDFVersion: String {
        guard viewerPreferences.pageLayout.requiresPDFVersion15,
              let pdfVersion,
              pdfVersion < PDFVersion(major: 1, minor: 5) else {
            return pdfVersion?.displayName ?? "-"
        }
        return PDFVersion(major: 1, minor: 5).displayName
    }

    private var readingDirection: Binding<PDFReadingDirection> {
        Binding(
            get: { viewerPreferences.readingDirection },
            set: { viewerPreferences.setReadingDirection($0) }
        )
    }
}

private extension PDFPageLayout {
    var localizedName: LocalizedStringResource {
        switch self {
        case .singlePage: "Single Page"
        case .oneColumn: "One Column"
        case .twoColumnLeft: "Two Columns, Left"
        case .twoColumnRight: "Two Columns, Right"
        case .twoPageLeft: "Two Pages, Left"
        case .twoPageRight: "Two Pages, Right"
        }
    }
}

private extension PDFReadingDirection {
    var localizedName: LocalizedStringResource {
        switch self {
        case .leftToRight: "Left to Right"
        case .rightToLeft: "Right to Left"
        }
    }
}

private extension PDFPageDisplayStyle {
    var localizedDescription: LocalizedStringResource {
        switch self {
        case .singlePage:
            "Single Page Display"
        case .singlePageContinuous:
            "Single Page Display, Scrolling Enabled"
        case .facingPagesContinuous:
            "Facing Pages Display, Scrolling Enabled"
        case .facingPagesCoverContinuous:
            "Facing Pages Display, Show Cover, Scrolling Enabled"
        case .facingPages:
            "Facing Pages Display"
        case .facingPagesCover:
            "Facing Pages Display, Show Cover"
        }
    }
}

private struct PDFPageThumbnail: View {
    let pageNumber: Int
    let page: PDFPage
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            thumbnailImage
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .aspectRatio(0.72, contentMode: .fit)
                .background(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isSelected ? Color.accentColor : Color.secondary.opacity(0.25),
                            lineWidth: isSelected ? 4 : 1
                        )
                }
                .clipShape(.rect(cornerRadius: 6))
                .shadow(color: .black.opacity(0.16), radius: 4, y: 2)

            Text("Page \(pageNumber)")
                .font(.callout.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(pageNumber)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("Double-tap twice to open a full-screen preview.")
    }

    private var thumbnailImage: Image {
#if os(macOS)
        Image(nsImage: page.thumbnail(of: CGSize(width: 360, height: 500), for: .cropBox))
#else
        Image(uiImage: page.thumbnail(of: CGSize(width: 360, height: 500), for: .cropBox))
#endif
    }
}

private struct PDFPagePreview: View {
    @Environment(\.dismiss) private var dismiss

    let page: PDFPage

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                previewImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 1200)
                    .background(.white)
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
                    .padding(24)
            }
            .background(.regularMaterial)
            .navigationTitle("PDF Preview")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var previewImage: Image {
        let bounds = page.bounds(for: .cropBox)
        let scale = min(3, 1800 / max(bounds.width, bounds.height))
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
#if os(macOS)
        return Image(nsImage: page.thumbnail(of: size, for: .cropBox))
#else
        return Image(uiImage: page.thumbnail(of: size, for: .cropBox))
#endif
    }
}

private struct PDFPageRow: View {
    let pageNumber: Int
    let page: PDFPage

    var body: some View {
        HStack(spacing: 16) {
            thumbnailImage
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

    private var thumbnailImage: Image {
#if os(macOS)
        Image(nsImage: page.thumbnail(of: CGSize(width: 120, height: 160), for: .cropBox))
#else
        Image(uiImage: page.thumbnail(of: CGSize(width: 120, height: 160), for: .cropBox))
#endif
    }
}

#if os(macOS)
private struct MacPDFWorkspace: View {
    @Bindable var model: PDFEditorModel
    let openDocument: () -> Void

    var body: some View {
        HSplitView {
            MacPDFSidebar(
                pages: model.pages,
                selection: $model.selection,
                movePages: model.movePages,
                openDocument: openDocument
            )
            .frame(minWidth: 220, idealWidth: 260, maxWidth: 340)

            MacPDFPreview(
                pages: model.pages,
                selection: model.selection,
                openDocument: openDocument
            )
            .frame(minWidth: 480, maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct MacPDFSidebar: View {
    let pages: [PDFPageItem]
    @Binding var selection: Set<PDFPageItem.ID>
    let movePages: (IndexSet, Int) -> Void
    let openDocument: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Pages", systemImage: "rectangle.stack")
                    .font(.headline)
                Spacer()
                Text(pages.count, format: .number)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()

            if pages.isEmpty {
                ContentUnavailableView {
                    Label("No PDF Open", systemImage: "doc.richtext")
                } description: {
                    Text("Open a PDF to view its pages.")
                } actions: {
                    Button("Open PDF", action: openDocument)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List(selection: $selection) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        PDFPageRow(pageNumber: index + 1, page: item.page)
                            .tag(item.id)
                    }
                    .onMove(perform: movePages)
                }
                .listStyle(.sidebar)
            }
        }
        .background(.background)
    }
}

private struct MacPDFPreview: View {
    let pages: [PDFPageItem]
    let selection: Set<PDFPageItem.ID>
    let openDocument: () -> Void

    private var selectedPages: [PDFPageItem] {
        pages.filter { selection.contains($0.id) }
    }

    var body: some View {
        if pages.isEmpty {
            ContentUnavailableView {
                Label("Open a PDF", systemImage: "doc.richtext")
            } description: {
                Text("Choose a PDF to arrange, rotate, or remove pages.")
            } actions: {
                Button("Open PDF", action: openDocument)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        } else if selectedPages.isEmpty {
            ContentUnavailableView(
                "No Pages Selected",
                systemImage: "rectangle.stack.badge.minus",
                description: Text("Select one or more pages in the sidebar to preview them.")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 28) {
                    ForEach(selectedPages) { item in
                        MacPDFPreviewPage(page: item.page)
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}

private struct MacPDFPreviewPage: View {
    let page: PDFPage

    var body: some View {
        Image(nsImage: page.thumbnail(of: previewSize, for: .cropBox))
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 760)
            .background(.white)
            .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
            .accessibilityLabel("Selected PDF page preview")
    }

    private var previewSize: CGSize {
        let bounds = page.bounds(for: .cropBox)
        let scale = min(2, 1400 / max(bounds.width, bounds.height))
        return CGSize(width: bounds.width * scale, height: bounds.height * scale)
    }
}
#endif
