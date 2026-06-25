import SwiftUI

struct CuisineSelector: View {
    @Binding var selected: Set<Cuisine>

    private let indian: [Cuisine] = [.northIndian, .southIndian, .gujarati, .maharashtrian, .rajasthani, .northEastern]

    var body: some View {
        DisclosureGroup("Indian Cuisine") {
            ForEach(indian) { row($0) }
        }
        row(.western)
    }

    private func row(_ cuisine: Cuisine) -> some View {
        Button { toggle(cuisine) } label: {
            HStack {
                Text(cuisine.label)
                Spacer()
                if selected.contains(cuisine) {
                    Image(systemName: "checkmark").foregroundStyle(Brand.accent)
                }
            }
        }
        .foregroundStyle(.primary)
    }

    private func toggle(_ cuisine: Cuisine) {
        if selected.contains(cuisine) { selected.remove(cuisine) } else { selected.insert(cuisine) }
    }
}
