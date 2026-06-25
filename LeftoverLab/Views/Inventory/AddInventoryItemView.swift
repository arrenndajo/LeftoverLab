import SwiftUI
import SwiftData

struct AddInventoryItemView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var item: InventoryItem?

    @State private var name = ""
    @State private var category: InventoryCategory = .ingredient
    @State private var quantity = "1"
    @State private var location: StorageLocation = .fridge
    @State private var hasExpiration = false
    @State private var expirationDate = Date()
    @State private var selectedTags: Set<DietaryTag> = []

    private var isEditing: Bool { item != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(InventoryCategory.allCases) { Text($0.label).tag($0) }
                    }
                    TextField("Quantity", text: $quantity)
                    Picker("Location", selection: $location) {
                        ForEach(StorageLocation.allCases) { Text($0.label).tag($0) }
                    }
                }
                Section("Expiration") {
                    Toggle("Has expiration date", isOn: $hasExpiration)
                    if hasExpiration {
                        DatePicker("Expires", selection: $expirationDate, displayedComponents: .date)
                    }
                }
                Section("Tags") {
                    ForEach(DietaryTag.allCases) { tag in
                        Button { toggle(tag) } label: {
                            HStack {
                                Text(tag.label)
                                Spacer()
                                if selectedTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    private func loadIfEditing() {
        guard let item, name.isEmpty else { return }
        name = item.name
        category = item.category
        quantity = item.quantity
        location = item.location
        if let date = item.expirationDate {
            hasExpiration = true
            expirationDate = date
        }
        selectedTags = Set(item.tags)
    }

    private func toggle(_ tag: DietaryTag) {
        if selectedTags.contains(tag) { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalQuantity = quantity.isEmpty ? "1" : quantity
        let finalExpiration = hasExpiration ? expirationDate : nil

        if let item {
            item.name = trimmedName
            item.category = category
            item.quantity = finalQuantity
            item.location = location
            item.expirationDate = finalExpiration
            item.tags = selectedTags.sorted { $0.rawValue < $1.rawValue }
        } else {
            context.insert(InventoryItem(
                name: trimmedName,
                category: category,
                quantity: finalQuantity,
                location: location,
                expirationDate: finalExpiration,
                tags: Array(selectedTags)
            ))
        }
        dismiss()
    }
}
