import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Creator.dateAdded) private var creators: [Creator]
    @State private var showingAdd = false
    @AppStorage("selectedCuisines") private var rawCuisines = ""
    @AppStorage("dietInclusions") private var rawDiet = ""
    @AppStorage("preferNutritious") private var preferNutritious = true

    private var cuisineSelection: Binding<Set<Cuisine>> {
        Binding(get: { Cuisine.decode(rawCuisines) }, set: { rawCuisines = Cuisine.encode($0) })
    }
    private var diet: Set<DietInclusion> { DietInclusion.decode(rawDiet) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("You're vegetarian by default. Turn on anything you also eat.")
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach(DietInclusion.allCases) { item in
                        Button { toggleDiet(item) } label: {
                            HStack {
                                Text(item.label)
                                Spacer()
                                if diet.contains(item) {
                                    Image(systemName: "checkmark").foregroundStyle(Brand.accent)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Food Preferences")
                }

                Section {
                    Toggle("Show only nutritious meals", isOn: $preferNutritious)
                } header: {
                    Text("Nutrition")
                } footer: {
                    Text("Keeps protein- and fiber-rich dishes; hides refined, low-fiber ones like instant noodles or cheese toast.")
                }

                Section("Cuisine Preferences") {
                    CuisineSelector(selected: cuisineSelection)
                }

                Section("Favorite YouTube Creators") {
                    if creators.isEmpty {
                        Text("Add YouTube cooks you love — we'll link their version of each recipe.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        ForEach(creators) { creator in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(creator.name).font(.body.weight(.medium))
                                if !creator.channelURL.isEmpty {
                                    Text(creator.channelURL).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }

                    Button { showingAdd = true } label: {
                        Label("Add Creator", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Preferences")
            .sheet(isPresented: $showingAdd) { AddCreatorView() }
        }
    }

    private func toggleDiet(_ item: DietInclusion) {
        var set = diet
        if set.contains(item) { set.remove(item) } else { set.insert(item) }
        rawDiet = DietInclusion.encode(set)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(creators[index]) }
    }
}

private struct AddCreatorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var channelURL = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Creator") {
                    TextField("Name (e.g. Ranveer Brar)", text: $name)
                    TextField("Channel link (optional)", text: $channelURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Add Creator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        context.insert(Creator(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            channelURL: channelURL.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        dismiss()
    }
}
