import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var healthKit = HealthKitService.shared

    @State private var step = 0
    @State private var goal = "Build Muscle"
    @State private var experience = "Beginner"
    @State private var location = "Gym"
    @State private var days = 3
    @State private var isGenerating = false

    private var totalSteps: Int { 5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
            footer
        }
        .padding(24)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("RepRamp")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.orange)
                Spacer()
                Text("\(step + 1)/\(totalSteps)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceHigh)
                    Capsule()
                        .fill(Theme.orange)
                        .frame(width: geometry.size.width * CGFloat(step + 1) / CGFloat(totalSteps))
                }
            }
            .frame(height: 6)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            questionBlock(title: "What are you training for?", subtitle: "Your plan adapts to your goal.") {
                optionGrid(options: PlanTemplates.goals, selection: $goal)
            }
        case 1:
            questionBlock(title: "How long have you been lifting?", subtitle: "We set volume and load jumps to match.") {
                optionGrid(options: PlanTemplates.experienceLevels, selection: $experience)
            }
        case 2:
            questionBlock(title: "Where do you train?", subtitle: "We pick exercises you can actually do.") {
                optionGrid(options: PlanTemplates.locations, selection: $location)
            }
        case 3:
            questionBlock(title: "How many days per week?", subtitle: "Start realistic. You can change this anytime.") {
                optionGrid(options: PlanTemplates.dayOptions.map { "\($0) days" }, selection: Binding(
                    get: { "\(days) days" },
                    set: { days = Int($0.split(separator: " ").first ?? "3") ?? 3 }
                ))
            }
        default:
            questionBlock(title: "Connect Apple Health?", subtitle: "Optional. RepRamp reads sleep and HRV to trim intensity when you are under-recovered, and saves your workouts.") {
                VStack(spacing: 12) {
                    healthRow(icon: "heart.text.square.fill", title: "Sleep + HRV recovery", detail: "Adjusts today's recommendation")
                    healthRow(icon: "figure.strengthtraining.traditional", title: "Workouts to Apple Health", detail: "Keeps your rings accurate")
                }
            }
        }
    }

    private func questionBlock<Content: View>(title: String, subtitle: String, @ViewBuilder options: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            options()
        }
    }

    private func optionGrid(options: [String], selection: Binding<String>) -> some View {
        VStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection.wrappedValue = option
                } label: {
                    HStack {
                        Text(option)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        if selection.wrappedValue == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.orange)
                        }
                    }
                    .padding(18)
                    .background(selection.wrappedValue == option ? Theme.orange.opacity(0.18) : Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selection.wrappedValue == option ? Theme.orange : Theme.separator, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option)
                .accessibilityAddTraits(selection.wrappedValue == option ? .isSelected : [])
            }
        }
    }

    private func healthRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.orange)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Text(detail).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if step < totalSteps - 1 {
                Button("Continue") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { step += 1 }
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button {
                    Task { await finishOnboarding() }
                } label: {
                    HStack {
                        if isGenerating { ProgressView().tint(.white) }
                        Text(isGenerating ? "Building your plan..." : "Build my plan")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isGenerating)

                Button("Skip Apple Health") {
                    complete()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            DisclaimerNote()
        }
    }

    private func finishOnboarding() async {
        isGenerating = true
        if healthKit.canRequest {
            await healthKit.requestAuthorization()
        }
        complete()
    }

    private func complete() {
        let answers = PlanQuestionnaire(goal: goal, experience: experience, location: location, daysPerWeek: days)
        let sessions = PlanTemplates.makePlan(from: answers)
        PlanRepository.create(name: PlanTemplates.planName(from: answers), goal: goal, sessions: sessions, source: "builtin", context: context)
        isGenerating = false
        withAnimation { hasOnboarded = true }
    }
}
