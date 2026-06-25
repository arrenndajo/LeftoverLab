import SwiftUI
import SwiftData

enum Brand {
    static let accent = Color(red: 0.90, green: 0.45, blue: 0.13)
}

struct InventoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \InventoryItem.dateAdded, order: .reverse) private var items: [InventoryItem]
    @State private var showingAdd = false
    @State private var showingScan = false
    @State private var showingQuickAdd = false
    @State private var editingItem: InventoryItem?
    @State private var expandedCategories: Set<InventoryCategory> = Set(InventoryCategory.allCases)

    @AppStorage("remindRefresh") private var remindRefresh = true
    @State private var showRefreshReminder = false
    @State private var dontRemindAgain = false

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Your kitchen is empty",
                        systemImage: "refrigerator",
                        description: Text("Add ingredients, leftovers, and ready-to-cook meals to start getting recipe ideas.")
                    )
                } else {
                    List {
                        ForEach(InventoryCategory.allCases) { category in
                            let group = items.filter { $0.category == category }
                            if !group.isEmpty {
                                DisclosureGroup(isExpanded: expansion(for: category)) {
                                    ForEach(group) { item in
                                        Button { editingItem = item } label: {
                                            ItemRow(item: item)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .onDelete { delete(group, at: $0) }
                                } label: {
                                    SectionHeader(category: category, count: group.count)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Kitchen")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { showingScan = true } label: {
                        Image(systemName: "doc.text.viewfinder").font(.title3)
                    }
                    .accessibilityLabel("Scan receipt")

                    Menu {
                        Button { showingAdd = true } label: { Label("Add one item", systemImage: "plus") }
                        Button { showingQuickAdd = true } label: { Label("Add several", systemImage: "plus.square.on.square") }
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                    .accessibilityLabel("Add items")
                }
            }
            .sheet(isPresented: $showingAdd) { AddInventoryItemView() }
            .sheet(isPresented: $showingScan) { ScanReceiptView() }
            .sheet(isPresented: $showingQuickAdd) { QuickAddView() }
            .sheet(item: $editingItem) { item in
                AddInventoryItemView(item: item)
            }
            .onChange(of: items.count) { oldCount, newCount in
                guard newCount > oldCount, remindRefresh else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dontRemindAgain = false
                    showRefreshReminder = true
                }
            }
            .sheet(isPresented: $showRefreshReminder) {
                RefreshReminderView(dontRemindAgain: $dontRemindAgain) {
                    if dontRemindAgain { remindRefresh = false }
                    showRefreshReminder = false
                }
            }
        }
        .tint(Brand.accent)
    }

    private func expansion(for category: InventoryCategory) -> Binding<Bool> {
        Binding(
            get: { expandedCategories.contains(category) },
            set: { isOpen in
                if isOpen { expandedCategories.insert(category) }
                else { expandedCategories.remove(category) }
            }
        )
    }

    private func delete(_ group: [InventoryItem], at offsets: IndexSet) {
        for index in offsets { context.delete(group[index]) }
    }
}

extension InventoryCategory {
    var icon: String {
        switch self {
        case .ingredient: "leaf.fill"
        case .leftover: "takeoutbag.and.cup.and.straw.fill"
        case .readyToCook: "microwave.fill"
        }
    }
    var tint: Color {
        switch self {
        case .ingredient: .green
        case .leftover: .orange
        case .readyToCook: .blue
        }
    }
}

private struct SectionHeader: View {
    let category: InventoryCategory
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .foregroundStyle(category.tint)
            Text(category.label)
                .font(.headline)
                .foregroundStyle(.primary)
            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(.quaternary))
            Spacer()
        }
        .textCase(nil)
        .padding(.vertical, 2)
    }
}

private struct ItemRow: View {
    let item: InventoryItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.category.tint.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: item.location.systemImage)
                    .foregroundStyle(item.category.tint)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.body.weight(.medium))
                HStack(spacing: 8) {
                    Text("Qty \(item.quantity)")
                    Text(item.location.label)
                    if let days = item.daysUntilExpiration {
                        Label(expiryText(days), systemImage: "clock")
                            .foregroundStyle(item.isExpiringSoon ? Brand.accent : .secondary)
                            .fontWeight(item.isExpiringSoon ? .semibold : .regular)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !item.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(item.tags) { tag in
                            Text(tag.label)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.quaternary))
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func expiryText(_ days: Int) -> String {
        switch days {
        case ..<0: "Expired"
        case 0: "Today"
        case 1: "1 day"
        default: "\(days) days"
        }
    }
}

private struct RefreshReminderView: View {
    @Binding var dontRemindAgain: Bool
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Brand.accent)
            Text("Item added!")
                .font(.title3.bold())
            Text("Open the What to Cook tab and tap the ↻ refresh button to update your recipe suggestions with the new ingredient.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button { dontRemindAgain.toggle() } label: {
                HStack(spacing: 8) {
                    Image(systemName: dontRemindAgain ? "checkmark.square.fill" : "square")
                        .foregroundStyle(dontRemindAgain ? Brand.accent : .secondary)
                    Text("Do not remind me again")
                    Spacer()
                }
            }
            .foregroundStyle(.primary)

            Button(action: onDismiss) {
                Text("Got it")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Brand.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(24)
        .presentationDetents([.height(380)])
    }
}
