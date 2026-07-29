import SwiftUI

/// A browsable, searchable library of meals or activities. The full set is on
/// screen to pick from — the user's most-used choices float to the top — while
/// the search field stays pinned at the top for those who'd rather type.
struct LifeLibraryPicker: View {
    @Environment(AppModel.self) private var model
    let kind: CareEntry.Kind
    @Binding var query: String
    /// The currently-chosen item name (so the picker can show a checkmark).
    var selectedName: String
    var onPick: (LifeLibrary.LibraryItem) -> Void

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            searchField

            if trimmedQuery.isEmpty {
                if !usuals.isEmpty {
                    section(title: "Your usuals", items: usuals)
                }
                section(title: kind == .meal ? "The whole menu" : "Everything active", items: catalog)
            } else if filtered.isEmpty {
                VStack(spacing: 6) {
                    Text("No match — keep typing and I'll picture it.")
                        .font(NudgeType.rounded(13))
                        .foregroundStyle(Theme.inkMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                grid(filtered)
            }
        }
    }

    // MARK: Search

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.inkMuted)
            TextField(kind == .meal ? "Search meals, or type your own…" : "Search activities, or type your own…",
                      text: $query)
                .font(NudgeType.rounded(15))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button {
                    query = ""
                    Haptics.tick()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.inkMuted.opacity(0.6))
                }
                .buttonStyle(NudgeButtonStyle())
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(Theme.surface.opacity(0.95), in: .capsule)
        .overlay(Capsule().strokeBorder(Theme.edge.opacity(0.6), lineWidth: 0.9))
    }

    // MARK: Sections

    private func section(title: String, items: [LifeLibrary.LibraryItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Kicker(text: title)
            grid(items)
        }
    }

    private func grid(_ items: [LifeLibrary.LibraryItem]) -> some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items) { item in
                itemTile(item)
            }
        }
    }

    private func itemTile(_ item: LifeLibrary.LibraryItem) -> some View {
        let active = item.name.caseInsensitiveCompare(selectedName) == .orderedSame
        return Button {
            Haptics.tick()
            onPick(item)
        } label: {
            HStack(spacing: 10) {
                Color(.secondarySystemBackground)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(item.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(NudgeType.rounded(13, active ? .semibold : .medium))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(item.group)
                        .font(NudgeType.rounded(10.5, .medium))
                        .foregroundStyle(Theme.inkMuted)
                }
                Spacer(minLength: 0)
                if active {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.life)
                }
            }
            .padding(9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface.opacity(active ? 1 : 0.8), in: .rect(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(active ? Theme.life.opacity(0.4) : Theme.edge.opacity(0.5), lineWidth: 0.9)
            )
        }
        .buttonStyle(NudgeButtonStyle())
    }

    // MARK: Data

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var catalog: [LifeLibrary.LibraryItem] {
        LifeLibrary.library(for: kind)
    }

    private var filtered: [LifeLibrary.LibraryItem] {
        let q = trimmedQuery.lowercased()
        // An exact pick fills the field with the item name — keep the whole
        // menu visible (checkmarked) instead of collapsing to one row.
        if catalog.contains(where: { $0.name.lowercased() == q }) { return catalog }
        return catalog.filter { $0.name.lowercased().contains(q) || $0.group.lowercased().contains(q) }
    }

    /// How often each item has been logged before — drives "most-used first".
    private var usage: [String: Int] {
        var counts: [String: Int] = [:]
        for entry in model.entries where entry.kind == kind {
            counts[entry.title.lowercased(), default: 0] += 1
        }
        return counts
    }

    private var usuals: [LifeLibrary.LibraryItem] {
        catalog
            .filter { (usage[$0.name.lowercased()] ?? 0) > 0 }
            .sorted { (usage[$0.name.lowercased()] ?? 0) > (usage[$1.name.lowercased()] ?? 0) }
            .prefix(4)
            .map { $0 }
    }
}
