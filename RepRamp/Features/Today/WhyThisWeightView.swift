import SwiftUI

struct WhyThisWeightView: View {
    let item: TodayItem
    let onFeedback: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var thanks: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if item.suggestion.hasHistory {
                        factorRows
                        feedbackRow
                    } else {
                        firstTimeNote
                    }
                    safetyNote
                    DisclaimerNote()
                }
                .padding(20)
            }
            .rampBackground()
            .navigationTitle("Why this weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.orange)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.exercise.name)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(item.planItem.targetSets) sets × \(item.suggestion.targetReps) reps · \(item.suggestion.targetWeightLB > 0 ? RampFormat.weight(item.suggestion.targetWeightLB) : "Set your own baseline")")
                .font(.subheadline)
                .foregroundStyle(Theme.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var factorRows: some View {
        VStack(spacing: 0) {
            if let entry = item.lastEntry {
                row(icon: "scalemass.fill", title: "Last set", detail: "\(RampFormat.weight(entry.weightLB)) × \(entry.reps) reps")
                Divider().overlay(Theme.separator)
                row(icon: "gauge.with.dots.needle.50percent", title: "Effort (RPE)", detail: entry.rpe.map { String(format: "%.1f / 10", $0) } ?? "Not recorded, assumed 7.5")
                Divider().overlay(Theme.separator)
                row(icon: "calendar", title: "Days since", detail: "\(Calendar.current.dateComponents([.day], from: entry.createdAt, to: .now).day ?? 0) days")
                Divider().overlay(Theme.separator)
            }
            row(icon: "arrow.up.right", title: "Next load", detail: item.suggestion.reason)
            if let caution = item.suggestion.caution {
                Divider().overlay(Theme.separator)
                row(icon: "exclamationmark.triangle.fill", title: "Recovery check", detail: caution)
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func row(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.orange)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
        }
        .padding(14)
    }

    private var feedbackRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Was that weight right?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 10) {
                Button("Too heavy") {
                    onFeedback("tooHeavy")
                    thanks = "Got it. We will trim the next recommendation."
                }
                .buttonStyle(SecondaryButtonStyle())
                Button("Too light") {
                    onFeedback("tooLight")
                    thanks = "Got it. We will add load next time."
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            if let thanks {
                Text(thanks)
                    .font(.caption)
                    .foregroundStyle(Theme.success)
            }
        }
        .cardStyle()
    }

    private var firstTimeNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("First time on this lift")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text("There is no history to ramp from yet. Choose a load where you stop 1-2 reps short of failure at \(item.suggestion.targetReps) reps. Log it once and RepRamp takes over.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .cardStyle()
    }

    private var safetyNote: some View {
        Text("Safety caps: RepRamp never adds more than 5% or 10 lb in one jump, and holds the weight when RPE is above 9.")
            .font(.caption)
            .foregroundStyle(Theme.textTertiary)
    }
}
