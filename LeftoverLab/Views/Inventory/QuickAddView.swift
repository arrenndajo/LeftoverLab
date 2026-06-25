import SwiftUI
import SwiftData

struct QuickAddView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var category: InventoryCategory = .ingredient
    @State private var location: StorageLocation = .fridge

    private var names: [String] {
        text.split(whereSeparator: { $0 == "\n" || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Items") {
                    TextField("rice, dal, onion, tomato…", text: $text, axis: .vertical)
                        .lineLimit(4...10)
                    if !names.isEmpty {
                        Text("\(names.count) item\(names.count == 1 ? "" : "s") detected")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("Applies to all") {
                    Picker("Category", selection: $category) {
                        ForEach(InventoryCategory.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Location", selection: $location) {
                        ForEach(StorageLocation.allCases) { Text($0.label).tag($0) }
                    }
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(names.count)") { save() }.disabled(names.isEmpty)
                }
            }
        }
    }

    private func save() {
        for name in names {
            context.insert(InventoryItem(name: name, category: category, location: location))
        }
        dismiss()
    }
}
