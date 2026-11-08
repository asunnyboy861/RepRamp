import SwiftUI
import SwiftData

struct PlanDetailView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    let plan: Plan
    @ObservedObject var viewModel: PlansViewModel
    @State private var sessions: [PlanSession]
    @State private var libraryTarget: LibraryTarget?
    @State private var showDeleteAlert = false

    init(plan: Plan, viewModel: PlansViewModel) {
        self.plan = plan
        self.viewModel = viewModel
        _sessions = State(initialValue: plan.sessions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                    sessionCard(index: index, session: session)
                }
                DisclaimerNote()
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .rampBackground()
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .foregroundStyle(Theme.textSecondary)
            }
        }
        .onChange(of: sessions) { _, newValue in
            viewModel.update(newValue, plan: plan, context: context)
        }
        .sheet(item: $libraryTarget) { target in
            ExerciseLibraryView { name in
                viewModel.addExercise(named: name, to: target.value, plan: plan, context: context, exercises: exercises)
                sessions = plan.sessions
            }
        }
        .alert("Delete this plan?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.delete(plan, context: context)
            }
        } message: {
            Text("Your logged workouts stay untouched.")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(plan.goal)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.orange)
                Text("\(sessions.count) sessions · \(sessions.reduce(0) { $0 + $1.items.count }) exercises")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if plan.isActive {
                Label("Active", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.success)
            } else {
                Button("Make active") {
                    viewModel.setActive(plan, context: context)
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(width: 130)
            }
        }
    }

    private func sessionCard(index: Int, session: PlanSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(session.dayName)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(session.items.count) lifts")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            ForEach(Array(session.items.enumerated()), id: \.element.id) { itemIndex, item in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.exerciseName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(item.targetSets) × \(item.targetRepsMin)-\(item.targetRepsMax) · rest \(item.restSeconds)s")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Button {
                            adjustSets(session: index, item: itemIndex, delta: -1)
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .accessibilityLabel("Decrease sets for \(item.exerciseName)")
                        Button {
                            adjustSets(session: index, item: itemIndex, delta: 1)
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(Theme.orange)
                        }
                        .accessibilityLabel("Increase sets for \(item.exerciseName)")
                        Button {
                            remove(session: index, item: itemIndex)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .accessibilityLabel("Remove \(item.exerciseName)")
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Theme.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Button {
                libraryTarget = LibraryTarget(value: index)
            } label: {
                Label("Add exercise", systemImage: "plus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.orange)
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
    }

    private func adjustSets(session: Int, item: Int, delta: Int) {
        guard sessions.indices.contains(session), sessions[session].items.indices.contains(item) else { return }
        sessions[session].items[item].targetSets = min(8, max(1, sessions[session].items[item].targetSets + delta))
    }

    private func remove(session: Int, item: Int) {
        guard sessions.indices.contains(session), sessions[session].items.indices.contains(item) else { return }
        sessions[session].items.remove(at: item)
    }
}

struct LibraryTarget: Identifiable {
    let id = UUID()
    let value: Int
}
