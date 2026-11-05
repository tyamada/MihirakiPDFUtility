import SwiftUI

struct PDFSplitDialog: View {
    @Binding var isPresented: Bool
    let onConfirm: (SplitDirection) -> Void

    @State private var direction: SplitDirection = .vertical

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Split each selected page into two separate pages.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Direction", selection: $direction) {
                        Text("Left / Right (Vertical cut)").tag(SplitDirection.vertical)
                        Text("Top / Bottom (Horizontal cut)").tag(SplitDirection.horizontal)
                    }
                    .pickerStyle(.inline)
                    .accessibilityLabel("Split Direction")
                }
            }
            .navigationTitle("Split Pages")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Run") {
                        isPresented = false
                        onConfirm(direction)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct PDFCropDialog: View {
    @Binding var isPresented: Bool
    let onConfirm: (CGFloat) -> Void

    @State private var marginPercent: Double = 10.0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Uniformly trim the four margins of each selected page.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Trim Margin")
                            Spacer()
                            Text("\(Int(marginPercent))%")
                                .font(.headline)
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)

                        Slider(
                            value: $marginPercent,
                            in: 0...40,
                            step: 5
                        )
                        .accessibilityLabel("Trim Margin")
                        .accessibilityValue("\(Int(marginPercent))%")
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Crop Pages")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Run") {
                        isPresented = false
                        onConfirm(CGFloat(marginPercent / 100.0))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
