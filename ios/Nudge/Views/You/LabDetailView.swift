import SwiftUI

/// One metric, drawn with light — glow line, soft range band (never red/green
/// judgment), scrub lens, companion annotations.
struct LabDetailView: View {
    @Environment(AppModel.self) private var model
    let series: LabSeries

    @State private var showAnnotations = true
    @State private var explaining = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(series.name)
                        .font(NudgeType.serif(28))
                        .foregroundStyle(Theme.ink)
                    if let latest = series.latest {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(valueString(latest.value))
                                .font(NudgeType.number(36, .bold))
                                .foregroundStyle(Theme.ink)
                            Text(series.unit)
                                .font(NudgeType.rounded(15, .medium))
                                .foregroundStyle(Theme.inkMuted)
                            Spacer()
                            FreshnessChip(date: latest.date)
                        }
                    }
                }
                .padding(.top, 8)

                OrganicSurface(radius: 32) {
                    VStack(alignment: .leading, spacing: 12) {
                        GlowChart(series: series, accent: Theme.sky, height: 220, showAnnotation: showAnnotations)
                        if let bandLabel = series.bandLabel {
                            Text("Soft band: \(bandLabel)")
                                .font(NudgeType.rounded(11.5))
                                .foregroundStyle(Theme.inkMuted)
                        }
                        if series.annotation != nil {
                            Toggle(isOn: $showAnnotations) {
                                Text("Companion annotations")
                                    .font(NudgeType.rounded(13, .medium))
                                    .foregroundStyle(Theme.ink)
                            }
                            .tint(Theme.life)
                        }
                    }
                    .padding(18)
                }

                Button {
                    explaining = true
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .medium))
                        Text("What does this mean for me?")
                            .font(NudgeType.rounded(15, .semibold))
                    }
                    .foregroundStyle(Theme.base)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.ink, in: .capsule)
                }
                .buttonStyle(NudgeButtonStyle())

                ProvenanceChip(text: series.provenance)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $explaining) {
            SeriesExplainSheet(series: series)
                .presentationDetents([.medium, .large])
                .presentationBackground(Theme.base)
        }
    }

    private func valueString(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }
}
