import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WorkoutSessionViewModel
    @State private var showCloseAlert = false

    init(sessionName: String, items: [TodayItem], workouts: [Workout], progress: UserProgress?) {
        _viewModel = StateObject(wrappedValue: WorkoutSessionViewModel(sessionName: sessionName, items: items, workouts: workouts, progress: progress))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                    exerciseCard(index: index, entry: entry)
                }
                DisclaimerNote()
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
            .padding(.bottom, viewModel.restRemaining > 0 ? 96 : 16)
        }
        .rampBackground()
        .safeAreaInset(edge: .top) {
            topBar
        }
        .overlay(alignment: .bottom) { restBar }
        .overlay { rankUpOverlay }
        .fullScreenCover(item: $viewModel.summary) { summary in
            WorkoutSummaryView(summary: summary) {
                viewModel.summary = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { dismiss() }
            }
        }
        .alert("Close this workout?", isPresented: $showCloseAlert) {
            Button("Keep and close", role: .cancel) { dismiss() }
            Button("Discard sets", role: .destructive) {
                viewModel.discard(context: context)
                dismiss()
            }
        } message: {
            Text("Your logged sets are saved. You can keep this session open in history or discard it.")
        }
        .onAppear { viewModel.startIfNeeded(context: context) }
    }

    private var topBar: some View {
        HStack {
            Button {
                if viewModel.hasCompletedSet {
                    showCloseAlert = true
                } else {
                    viewModel.discard(context: context)
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close workout")
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.sessionName)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("\(viewModel.totalCompletedSets) sets · \(RampFormat.volume(viewModel.volumeSoFar))")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button("Finish") {
                viewModel.finish(context: context)
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(viewModel.hasCompletedSet ? Theme.orange : Theme.textTertiary)
            .disabled(!viewModel.hasCompletedSet)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Theme.background.opacity(0.95))
    }

    private func exerciseCard(index: Int, entry: SessionEntry) -> some View {
        let done = entry.completedSets >= entry.targetSets
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.exercise.name)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Target \(entry.targetSets) × \(entry.targetReps) · \(entry.exercise.displayEquipment.capitalized)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if entry.isPR {
                    Text("PR")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Theme.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.warning.opacity(0.15))
                        .clipShape(Capsule())
                }
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                }
            }

            if let lastWeight = entry.lastWeight, let lastReps = entry.lastReps {
                Text("Last time: \(RampFormat.weight(lastWeight)) × \(lastReps)")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }

            HStack(spacing: 12) {
                if entry.exercise.equipment.lowercased() == "body only" {
                    valueBox(title: "LOAD", value: "Bodyweight", sub: nil)
                } else {
                    stepperBox(
                        title: "WEIGHT",
                        value: RampFormat.weightNumber(entry.weight),
                        unit: "lb",
                        decrease: { viewModel.adjustWeight(index: index, delta: -1) },
                        increase: { viewModel.adjustWeight(index: index, delta: 1) }
                    )
                }
                stepperBox(
                    title: "REPS",
                    value: "\(entry.reps)",
                    unit: nil,
                    decrease: { viewModel.adjustReps(index: index, delta: -1) },
                    increase: { viewModel.adjustReps(index: index, delta: 1) }
                )
            }

            HStack(spacing: 6) {
                ForEach(0..<max(entry.targetSets, entry.completedSets), id: \.self) { setIndex in
                    Circle()
                        .fill(setIndex < entry.completedSets ? Theme.orange : Theme.surfaceHigh)
                        .frame(width: 10, height: 10)
                }
                Text("\(entry.completedSets)/\(max(entry.targetSets, entry.completedSets)) sets")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.leading, 4)
                Spacer()
            }

            Button {
                viewModel.completeSet(index: index, context: context)
            } label: {
                Label(done ? "Log another set" : "Log set \(entry.completedSets + 1)", systemImage: "checkmark")
            }
            .buttonStyle(done ? AnyButtonStyle(SecondaryButtonStyle()) : AnyButtonStyle(PrimaryButtonStyle()))
            .accessibilityLabel("Log set for \(entry.exercise.name)")
        }
        .cardStyle()
        .opacity(done ? 0.85 : 1.0)
    }

    private func stepperBox(title: String, value: String, unit: String?, decrease: @escaping () -> Void, increase: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Button(action: decrease) {
                Image(systemName: "minus")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 44, height: 56)
            }
            .accessibilityLabel("Decrease \(title.lowercased())")
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.textTertiary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    if let unit {
                        Text(unit)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            Button(action: increase) {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundStyle(Theme.orange)
                    .frame(width: 44, height: 56)
            }
            .accessibilityLabel("Increase \(title.lowercased())")
        }
        .background(Theme.surfaceHigh)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func valueBox(title: String, value: String, sub: String?) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(Theme.surfaceHigh)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var restBar: some View {
        if viewModel.restRemaining > 0 {
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundStyle(Theme.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest \(RampFormat.clock(viewModel.restRemaining))")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Get ready for the next set")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button("Skip") { viewModel.skipRest() }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.orange)
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Theme.orange.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var rankUpOverlay: some View {
        if viewModel.showRankUp {
            ZStack {
                Theme.background.opacity(0.94).ignoresSafeArea()
                VStack(spacing: 20) {
                    RankBadgeView(rank: viewModel.newRank, size: 120)
                    Text("RANK UP")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.rankColor(viewModel.newRank))
                    Text("You reached \(viewModel.newRank.title).")
                        .font(.headline)
                        .foregroundStyle(Theme.textSecondary)
                    Button("Keep training") {
                        viewModel.showRankUp = false
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 40)
                }
            }
            .transition(.opacity)
        }
    }
}

struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        make = { configuration in AnyView(style.makeBody(configuration: configuration)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        make(configuration)
    }
}
