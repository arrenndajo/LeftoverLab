import SwiftUI
import SwiftData
import PhotosUI

private struct ScannedCandidate: Identifiable {
    let id = UUID()
    var name: String
    var category: InventoryCategory = .ingredient
    var include: Bool = true
}

struct ScanReceiptView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var candidates: [ScannedCandidate] = []
    @State private var isProcessing = false

    private var selectedCount: Int { candidates.filter(\.include).count }

    var body: some View {
        NavigationStack {
            Group {
                if isProcessing {
                    ProgressView("Reading receipt…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if candidates.isEmpty {
                    placeholder
                } else {
                    candidateList
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if !candidates.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add \(selectedCount)") { addSelected() }
                            .disabled(selectedCount == 0)
                    }
                }
            }
        }
        .onChange(of: photoItem) { _, newValue in
            Task { await process(newValue) }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 52))
                .foregroundStyle(Brand.accent)
            Text("Scan a grocery receipt").font(.headline)
            Text("Pick a photo of your receipt and we'll pull out the items. You can edit them before adding.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Choose Photo", systemImage: "photo")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Brand.accent))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var candidateList: some View {
        List {
            Section {
                ForEach($candidates) { $candidate in
                    HStack(spacing: 12) {
                        Button { candidate.include.toggle() } label: {
                            Image(systemName: candidate.include ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(candidate.include ? Brand.accent : .secondary)
                        }
                        .buttonStyle(.plain)
                        TextField("Item", text: $candidate.name)
                        Picker("", selection: $candidate.category) {
                            ForEach(InventoryCategory.allCases) { Text($0.label).tag($0) }
                        }
                        .labelsHidden()
                    }
                }
            } header: {
                Text("Detected items — uncheck or edit before adding")
            }
            Section {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Scan a different photo", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
    }

    private func process(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isProcessing = true
        defer { isProcessing = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        let lines = await ReceiptScanner.recognizeText(in: image)
        candidates = ReceiptParser.candidates(from: lines).map { ScannedCandidate(name: $0) }
    }

    private func addSelected() {
        for candidate in candidates where candidate.include {
            let name = candidate.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            context.insert(InventoryItem(name: name, category: candidate.category))
        }
        dismiss()
    }
}
