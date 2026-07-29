import SwiftUI
import Charts

/// Charts are drawn, not charted — a luminous line with soft outer glow,
/// under-fill fading to clear, reference ranges as soft gradient bands
/// (never red/green judgment colors), points only on scrub.
struct GlowChart: View {
    let series: LabSeries
    var accent: Color = Theme.sky
    var height: CGFloat = 190
    var compact: Bool = false
    var showAnnotation: Bool = false

    @State private var drawn = false
    @State private var scrub: LabPoint? = nil

    var body: some View {
        ZStack {
            chartBody(glow: true)
                .blur(radius: 6)
                .opacity(0.55)
                .allowsHitTesting(false)
            chartBody(glow: false)
        }
        .frame(height: height)
        .mask(alignment: .leading) {
            Rectangle().scaleEffect(x: drawn ? 1 : 0.001, anchor: .leading)
        }
        .onAppear {
            withAnimation(NudgeSpring.gentle.delay(0.12)) { drawn = true }
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilitySummary)
    }

    @ViewBuilder
    private func chartBody(glow: Bool) -> some View {
        let base = Chart {
            if let band = series.band, !glow, !compact,
               let first = series.points.first?.date, let last = series.points.last?.date {
                RectangleMark(
                    xStart: .value("From", first),
                    xEnd: .value("To", last),
                    yStart: .value("Low", band.lowerBound),
                    yEnd: .value("High", band.upperBound)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [accent.opacity(0.10), accent.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }

            ForEach(series.points) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value(series.name, point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [accent.opacity(glow ? 0 : 0.2), accent.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Date", point.date),
                    y: .value(series.name, point.value)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: glow ? 5.5 : 2.5, lineCap: .round))
                .foregroundStyle(accent)
            }

            if showAnnotation, let annotation = series.annotation, !glow {
                RuleMark(x: .value("Date", annotation.date))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    .foregroundStyle(Theme.inkMuted.opacity(0.4))
                    .annotation(position: .top, alignment: .leading) {
                        Text(annotation.label)
                            .font(NudgeType.rounded(10, .medium))
                            .foregroundStyle(Theme.inkMuted)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial, in: .capsule)
                    }
            }

            if let scrub, !glow {
                RuleMark(x: .value("Date", scrub.date))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Theme.inkMuted.opacity(0.35))
                PointMark(
                    x: .value("Date", scrub.date),
                    y: .value(series.name, scrub.value)
                )
                .symbolSize(110)
                .foregroundStyle(accent)
                .annotation(position: .top) {
                    Text(valueLabel(scrub.value))
                        .font(NudgeType.number(13))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: .capsule)
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8))
                }
            }
        }
        .chartYScale(domain: yDomain)

        if glow || compact {
            base
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
        } else {
            base
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisValueLabel()
                            .font(NudgeType.rounded(10, .medium))
                            .foregroundStyle(Theme.inkMuted.opacity(0.75))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) {
                        AxisGridLine()
                            .foregroundStyle(Theme.inkMuted.opacity(0.12))
                        AxisValueLabel()
                            .font(NudgeType.rounded(10, .medium))
                            .foregroundStyle(Theme.inkMuted.opacity(0.75))
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { _ in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if let date: Date = proxy.value(atX: value.location.x) {
                                            scrub = nearestPoint(to: date)
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(NudgeSpring.ui) { scrub = nil }
                                    }
                            )
                    }
                }
        }
    }

    private var yDomain: ClosedRange<Double> {
        var low = series.points.map(\.value).min() ?? 0
        var high = series.points.map(\.value).max() ?? 1
        if let band = series.band, !compact {
            low = min(low, band.lowerBound)
            high = max(high, band.upperBound)
        }
        let pad = max((high - low) * 0.18, 0.4)
        return (low - pad)...(high + pad)
    }

    private func nearestPoint(to date: Date) -> LabPoint? {
        series.points.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    private func valueLabel(_ value: Double) -> String {
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
        return "\(formatted) \(series.unit)"
    }

    private var accessibilitySummary: String {
        guard let latest = series.latest else { return series.name }
        return "\(series.name), latest \(valueLabel(latest.value)), \(series.points.count) readings"
    }
}
