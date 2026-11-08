import SwiftUI
import SwiftData
import Charts

struct ProgressViewScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]
    @Query private var progressList: [UserProgress]
    @StateObject private var viewModel = ProgressViewModel()
    @State private var showBodyScan = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let snapshot = viewModel.snapshot, snapshot.totalWorkouts > 0 {
                    statRow(snapshot)
                    volumeChart(snapshot)
                    muscleChart(snapshot)
                    prList(snapshot)
                } else {
                    EmptyStateView(icon: "chart.bar.xaxis", title: "No training history yet", message: "Log your first workout and your volume, muscle balance and PRs will appear here.")
                }
                bodyScanCard
                DisclaimerNote()
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .rampBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task { reload() }
        .onAppear { reload() }
        .sheet(isPresented: $showBodyScan) {
            NavigationStack { BodyScanView() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("PROGRESS")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(Theme.orange)
            Text("Proof you are ramping")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func statRow(_ snapshot: ProgressSnapshot) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatTile(value: RampFormat.volume(snapshot.thisWeekVolume), label: "This week")
                StatTile(
                    value: snapshot.lastWeekVolume > 0 ? RampFormat.percent(snapshot.weeklyDeltaPercent) : "New",
                    label: "vs last week",
                    tint: snapshot.weeklyDeltaPercent >= 0 ? Theme.success : Theme.warning
                )
            }
            HStack(spacing: 10) {
                StatTile(value: "\(snapshot.totalWorkouts)", label: "Workouts")
                StatTile(value: "\(snapshot.streak)", label: "Day streak", tint: Theme.orange)
                StatTile(value: "\(snapshot.bestStreak)", label: "Best streak")
            }
        }
    }

    private func volumeChart(_ snapshot: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Weekly volume", subtitle: "Total pounds lifted, last 8 weeks")
            Chart(snapshot.weeklyVolumes) { item in
                BarMark(
                    x: .value("Week", item.weekStart, unit: .weekOfYear),
                    y: .value("Volume", item.volume)
                )
                .foregroundStyle(Theme.orange)
                .cornerRadius(5)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                    AxisGridLine().foregroundStyle(Theme.separator)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Theme.separator)
                    AxisValueLabel().foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(height: 170)
        }
        .cardStyle()
    }

    private func muscleChart(_ snapshot: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Muscle balance", subtitle: "Working sets per muscle, last 30 days")
            if snapshot.muscleVolumes.isEmpty {
                Text("Log a few workouts to see your muscle distribution.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Chart(snapshot.muscleVolumes) { item in
                    BarMark(
                        x: .value("Sets", item.sets),
                        y: .value("Muscle", item.muscle)
                    )
                    .foregroundStyle(Theme.orange.opacity(0.85))
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Theme.separator)
                        AxisValueLabel().foregroundStyle(Theme.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(height: CGFloat(max(120, snapshot.muscleVolumes.count * 28))
                )
            }
        }
        .cardStyle()
    }

    private func prList(_ snapshot: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Personal records", subtitle: "Best estimated 1RM per lift")
            if snapshot.personalRecords.isEmpty {
                Text("No PRs yet. They appear automatically as you log sets.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            ForEach(snapshot.personalRecords) { record in
                HStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(Theme.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.exerciseName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(RampFormat.weight(record.weight)) × \(record.reps) · \(RampFormat.dateShort(record.achievedAt))")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text(RampFormat.weight(record.estimated1RM))
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.orange)
                }
                .padding(12)
                .background(Theme.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .cardStyle()
    }

    private var bodyScanCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "viewfinder")
                .font(.title2)
                .foregroundStyle(Theme.orange)
            VStack(alignment: .leading, spacing: 3) {
                Text("AI Body Scan")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("One photo. Muscle balance radar and 3 priorities for next week.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture { showBodyScan = true }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Open AI Body Scan")
    }

    private func reload() {
        viewModel.load(workouts: workouts, progress: progressList.first)
    }
}
