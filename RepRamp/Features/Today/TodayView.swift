import SwiftUI
import SwiftData

struct TodayView: View {
    @Binding var showSettings: Bool
    @Environment(\.modelContext) private var context
    @Query(sort: \Plan.createdAt, order: .reverse) private var plans: [Plan]
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]
    @Query private var progressList: [UserProgress]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @StateObject private var viewModel = TodayViewModel()
    @ObservedObject private var healthKit = HealthKitService.shared
    @State private var activeSession: ActiveSession?
    @State private var whyItem: TodayItem?
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let snapshot = viewModel.snapshot {
                    rankStrip(snapshot)
                    if let note = snapshot.recoveryNote {
                        recoveryCard(note)
                    }
                    heroCard(snapshot)
                    restOfSession(snapshot)
                    startButton(snapshot)
                } else {
                    EmptyStateView(icon: "calendar.badge.plus", title: "No plan yet", message: "Create a plan from the Plans tab to see today's targets.")
                }
                DisclaimerNote()
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .rampBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if healthKit.canRequest { await healthKit.refresh() }
            reload()
        }
        .onAppear { reload() }
        .sheet(item: $whyItem) { item in
            WhyThisWeightView(item: item, onFeedback: { feedback in
                applyFeedback(feedback, to: item)
            })
        }
        .fullScreenCover(item: $activeSession) { session in
            WorkoutSessionView(sessionName: session.name, items: session.items, workouts: workouts, progress: progressList.first)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(Theme.orange)
                Text(Date.now, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Settings")
        }
    }

    private func rankStrip(_ snapshot: TodaySnapshot) -> some View {
        HStack(spacing: 14) {
            RankBadgeView(rank: snapshot.rank, size: 46)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(snapshot.rank.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.rankColor(snapshot.rank))
                    Text("\(snapshot.totalXP) XP")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    if snapshot.streak > 0 {
                        Label("\(snapshot.streak)d streak", systemImage: "flame.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.orange)
                    }
                }
                XPBarView(fraction: snapshot.xpFraction)
                Text(snapshot.rank == .legend ? "Max rank reached" : "\(snapshot.xpToNext) XP to next rank")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func recoveryCard(_ note: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .foregroundStyle(Theme.warning)
                .font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text("Apple Health recovery")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.warning)
                Text(note)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func heroCard(_ snapshot: TodaySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(snapshot.sessionName, systemImage: "figure.strengthtraining.traditional")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.orange)
                Spacer()
                if snapshot.finishedToday {
                    Label("Done today", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.success)
                }
            }
            if let hero = snapshot.items.first {
                Text(hero.exercise.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                heroNumbers(hero)
                Text(hero.suggestion.reason)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                if let caution = hero.suggestion.caution {
                    Text(caution)
                        .font(.caption)
                        .foregroundStyle(Theme.warning)
                }
                HStack {
                    Button("Show me why") { whyItem = hero }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.orange)
                    Spacer()
                    if let lastWeight = hero.lastWeight {
                        Text("Last: \(RampFormat.weight(lastWeight)) × \(hero.lastReps ?? 0)")
                            .font(.caption)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            } else {
                Text("Rest day")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .cardStyle(padding: 20)
    }

    private func heroNumbers(_ item: TodayItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if item.suggestion.targetWeightLB > 0 {
                Text(RampFormat.weightNumber(item.suggestion.targetWeightLB))
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("lb")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
                Text("↑")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.orange)
            } else {
                Text("SET YOUR BASELINE")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.orange)
            }
            Spacer()
            Text("\(item.planItem.targetSets) × \(item.suggestion.targetReps)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Target \(item.planItem.targetSets) sets of \(item.suggestion.targetReps) reps at \(RampFormat.weight(item.suggestion.targetWeightLB))")
    }

    private func restOfSession(_ snapshot: TodaySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Up next", subtitle: snapshot.planName)
            ForEach(snapshot.items.dropFirst()) { item in
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.exercise.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(item.planItem.targetSets) × \(item.suggestion.targetReps) · \(item.exercise.displayEquipment.capitalized)")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text(item.suggestion.targetWeightLB > 0 ? RampFormat.weight(item.suggestion.targetWeightLB) : "Baseline")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(item.suggestion.targetWeightLB > 0 ? Theme.textPrimary : Theme.orange)
                }
                .padding(14)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func startButton(_ snapshot: TodaySnapshot) -> some View {
        Button {
            activeSession = ActiveSession(name: snapshot.sessionName, items: snapshot.items)
        } label: {
            Label(snapshot.finishedToday ? "Train again" : "Start workout", systemImage: "play.fill")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(snapshot.items.isEmpty)
        .padding(.top, 4)
    }

    private func reload() {
        viewModel.load(
            plans: plans,
            workouts: workouts,
            progress: progressList.first,
            exercises: exercises,
            recoveryFactor: healthKit.recoveryFactor,
            recoveryNote: healthKit.recoveryNote,
            context: context
        )
    }

    private func applyFeedback(_ feedback: String, to item: TodayItem) {
        guard let entry = item.lastEntry else { return }
        WorkoutRepository.setFeedback(entry, feedback: feedback, context: context)
        reload()
    }
}

struct ActiveSession: Identifiable {
    let id = UUID()
    let name: String
    let items: [TodayItem]
}
