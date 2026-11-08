import SwiftUI
import SwiftData

struct PlansView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Plan.createdAt, order: .reverse) private var plans: [Plan]
    @StateObject private var viewModel = PlansViewModel()
    @State private var showNewPlan = false
    @State private var newGoal = PlanTemplates.goals[0]
    @State private var newExperience = PlanTemplates.experienceLevels[0]
    @State private var newLocation = PlanTemplates.locations[0]
    @State private var newDays = 3

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PLANS")
                            .font(.caption.weight(.bold))
                            .tracking(2)
                            .foregroundStyle(Theme.orange)
                        Text("Your training split")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Spacer()
                    Button {
                        showNewPlan = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(Theme.orange)
                            .frame(width: 44, height: 44)
                            .background(Theme.surface)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Create a new plan")
                }

                if plans.isEmpty {
                    EmptyStateView(icon: "list.bullet.rectangle", title: "No plans yet", message: "Tap + to build a plan in seconds. Unlimited plans are free.")
                } else {
                    ForEach(plans) { plan in
                        NavigationLink(destination: PlanDetailView(plan: plan, viewModel: viewModel)) {
                            planRow(plan)
                        }
                        .buttonStyle(.plain)
                    }
                }
                DisclaimerNote()
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .rampBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNewPlan) {
            newPlanSheet
        }
    }

    private func planRow(_ plan: Plan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.name)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(plan.sessions.count) sessions · \(plan.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if plan.isActive {
                    Text("ACTIVE")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(Theme.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.orange.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Button("Make active") {
                        viewModel.setActive(plan, context: context)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                }
            }
            HStack(spacing: 6) {
                ForEach(plan.sessions.prefix(6)) { session in
                    Text(session.dayName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.surfaceHigh)
                        .clipShape(Capsule())
                }
            }
        }
        .cardStyle()
    }

    private var newPlanSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Build a plan")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                    choiceGroup(title: "Goal", options: PlanTemplates.goals, selection: $newGoal)
                    choiceGroup(title: "Experience", options: PlanTemplates.experienceLevels, selection: $newExperience)
                    choiceGroup(title: "Location", options: PlanTemplates.locations, selection: $newLocation)
                    choiceGroup(title: "Days per week", options: PlanTemplates.dayOptions.map { "\($0)" }, selection: Binding(
                        get: { "\(newDays)" },
                        set: { newDays = Int($0) ?? 3 }
                    ))
                }
                .padding(20)
            }
            .rampBackground()
            .navigationTitle("New plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showNewPlan = false }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.create(answers: PlanQuestionnaire(goal: newGoal, experience: newExperience, location: newLocation, daysPerWeek: newDays), context: context)
                        showNewPlan = false
                    }
                    .foregroundStyle(Theme.orange)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func choiceGroup(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            FlowChips(options: options, selection: selection)
        }
    }
}

struct FlowChips: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        VStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    HStack {
                        Text(option)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        if selection == option {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.orange)
                        }
                    }
                    .padding(14)
                    .background(selection == option ? Theme.orange.opacity(0.15) : Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selection == option ? Theme.orange : Theme.separator, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
