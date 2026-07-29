import SwiftUI

enum YouDestination: Hashable {
    case records
    case category(RecordCategory)
    case labDetail(String)
    case medications
    case medDetail(String)
    case care
    case visitPrep
    case conditions
    case guide
    case life
}

/// "You" — the health story. Story · Insights as one segmented pair, with the
/// conditions overview, discussion guide, and records drawer one tap away.
struct YouView: View {
    @Environment(AppModel.self) private var model
    @State private var section: Section = .story
    @State private var path = NavigationPath()

    enum Section: String, CaseIterable {
        case story = "Story"
        case insights = "Insights"
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LivingGradientView()

                VStack(spacing: 0) {
                    header
                    quickDoors

                    switch section {
                    case .story:
                        StoryTimelineView()
                            .transition(.opacity)
                    case .insights:
                        InsightsHubView()
                            .transition(.opacity)
                    }
                }
            }
            .navigationDestination(for: YouDestination.self) { destination in
                destinationView(destination)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onReceive(NotificationCenter.default.publisher(for: .nudgeOpenConditions)) { _ in
                if path.isEmpty {
                    path.append(YouDestination.conditions)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .nudgeOpenLife)) { _ in
                if path.isEmpty {
                    path.append(YouDestination.life)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            GlassSurface(radius: 24) {
                HStack(spacing: 4) {
                    ForEach(Section.allCases, id: \.self) { item in
                        let selected = section == item
                        Button {
                            Haptics.tick()
                            withAnimation(NudgeSpring.ui) { section = item }
                        } label: {
                            Text(item.rawValue)
                                .font(NudgeType.rounded(13, selected ? .semibold : .medium))
                                .foregroundStyle(selected ? Theme.ink : Theme.inkMuted)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background {
                                    if selected {
                                        Capsule().fill(Theme.surface.opacity(0.9))
                                    }
                                }
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                }
                .padding(4)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    /// The doors that were buried — conditions & plan, the discussion guide,
    /// care team & visits. Present on the surface, calm as chips.
    private var quickDoors: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                door(glyph: model.pathway.glyph, label: model.persona.conditionChip, accent: Theme.warm) {
                    path.append(YouDestination.conditions)
                }
                door(glyph: "text.book.closed", label: "Discussion guide", accent: Theme.gold,
                     badge: model.guideItems.filter { !$0.resolved }.count) {
                    path.append(YouDestination.guide)
                }
                door(glyph: "stethoscope", label: "Care team & visits", accent: Theme.life) {
                    path.append(YouDestination.care)
                }
                door(glyph: "pills", label: "Medications", accent: Theme.sky) {
                    path.append(YouDestination.medications)
                }
                door(glyph: "fork.knife", label: "Life catalog", accent: Theme.rose) {
                    path.append(YouDestination.life)
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func door(glyph: String, label: String, accent: Color,
                      badge: Int = 0, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tick()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: glyph)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(accent)
                Text(label)
                    .font(NudgeType.rounded(12, .medium))
                    .foregroundStyle(Theme.ink)
                if badge > 0 {
                    Text("\(badge)")
                        .font(NudgeType.number(10, .semibold))
                        .foregroundStyle(Theme.base)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accent, in: .capsule)
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: .capsule)
            .overlay(Capsule().strokeBorder(accent.opacity(0.35), lineWidth: 0.9))
        }
        .buttonStyle(NudgeButtonStyle())
    }

    @ViewBuilder
    private func destinationView(_ destination: YouDestination) -> some View {
        ZStack {
            LivingGradientView()
            switch destination {
            case .records:
                RecordsDrawerView()
            case .category(let category):
                RecordCategoryView(category: category)
            case .labDetail(let seriesID):
                if let series = model.series(seriesID) {
                    LabDetailView(series: series)
                }
            case .medications:
                MedicationsView()
            case .medDetail(let medID):
                if let med = model.medications.first(where: { $0.id == medID }) {
                    MedDetailView(medication: med)
                }
            case .care:
                CareTeamView()
            case .visitPrep:
                VisitPrepView()
            case .conditions:
                ConditionOverviewView()
            case .guide:
                DiscussionGuideView()
            case .life:
                LifeCatalogView()
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
