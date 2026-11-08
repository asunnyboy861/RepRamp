import SwiftUI
import SwiftData
import PhotosUI

struct CoachView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @StateObject private var viewModel = CoachViewModel()
    @ObservedObject private var gateway = AIGateway.shared
    @State private var showPaywall = false
    @State private var showAISettings = false
    @State private var savedNotice = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statusCard
                if let draft = viewModel.draft {
                    draftCard(draft)
                } else {
                    generatorCard
                    screenshotCard
                }
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.warning)
                        .cardStyle()
                }
                DisclaimerNote()
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .rampBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showAISettings) { NavigationStack { AISettingsView() } }
        .alert("Plan created", isPresented: $savedNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("It is now your active plan. Today will show the first session.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("COACH")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(Theme.orange)
            Text("Build the next block")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: gateway.canUseAnyTextAI ? "sparkles" : "exclamationmark.circle")
                .foregroundStyle(gateway.canUseAnyTextAI ? Theme.orange : Theme.warning)
                .font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text(gateway.statusBadge)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(gateway.availabilityMessage)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    private var generatorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "AI plan generator", subtitle: "Four answers. A complete split you can edit.")
            pickerRow(title: "Goal", value: viewModel.goal, options: PlanTemplates.goals) { viewModel.goal = $0 }
            pickerRow(title: "Experience", value: viewModel.experience, options: PlanTemplates.experienceLevels) { viewModel.experience = $0 }
            pickerRow(title: "Location", value: viewModel.location, options: PlanTemplates.locations) { viewModel.location = $0 }
            pickerRow(title: "Days per week", value: "\(viewModel.days)", options: PlanTemplates.dayOptions.map { "\($0)" }) { viewModel.days = Int($0) ?? 4 }

            if viewModel.isGenerating {
                HStack(spacing: 12) {
                    ProgressView().tint(Theme.orange)
                    Text("Building your split...")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                Button("Generate my plan") {
                    Task { await viewModel.generate() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!gateway.canUseAnyTextAI)
                .opacity(gateway.canUseAnyTextAI ? 1.0 : 0.45)
            }

            if !gateway.canUseAnyTextAI {
                unavailableActions
            }
        }
        .cardStyle(padding: 20)
    }

    private var unavailableActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI is not available on this device yet. Apple Intelligence requires iOS 26 and an iPhone 15 Pro or newer.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 10) {
                Button("Unlock cloud AI") { showPaywall = true }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Add my own key") { showAISettings = true }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var screenshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Import a plan screenshot", subtitle: "Snap a coach's plan and RepRamp structures it.")
            PhotosPicker(selection: $viewModel.screenshotItem, matching: .images, photoLibrary: .shared()) {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.screenshotData == nil ? "photo.badge.plus" : "photo.fill")
                        .foregroundStyle(Theme.orange)
                    Text(viewModel.screenshotData == nil ? "Choose a screenshot" : "Screenshot ready")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }
                .padding(14)
                .background(Theme.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .onChange(of: viewModel.screenshotItem) { _, newValue in
                Task { await viewModel.loadScreenshot(newValue) }
            }

            if viewModel.isImporting {
                HStack(spacing: 12) {
                    ProgressView().tint(Theme.orange)
                    Text("Reading the plan...")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                Button("Import plan") {
                    Task { await viewModel.importScreenshot() }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(viewModel.screenshotData == nil || !gateway.canUseVisionAI)
                .opacity((viewModel.screenshotData == nil || !gateway.canUseVisionAI) ? 0.45 : 1.0)
            }

            if !gateway.canUseVisionAI {
                Text("Screenshot import needs a vision-capable cloud engine.")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .cardStyle(padding: 20)
    }

    private func draftCard(_ draft: PlanDraft) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(draft.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(draft.sessions.count) sessions · \(draft.goal)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.orange)
            }
            ForEach(Array(draft.sessions.enumerated()), id: \.offset) { _, session in
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.dayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.orange)
                    ForEach(session.items, id: \.exerciseName) { item in
                        HStack {
                            Text(item.exerciseName)
                                .font(.caption)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("\(item.targetSets)×\(item.targetRepsMin)-\(item.targetRepsMax)")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Button("Use this plan") {
                if viewModel.saveDraft(context: context, exercises: exercises) {
                    savedNotice = true
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            Button("Discard draft") {
                viewModel.draft = nil
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .cardStyle(padding: 20)
    }

    private func pickerRow(title: String, value: String, options: [String], onSelect: @escaping (String) -> Void) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { onSelect(option) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.surfaceHigh)
                .clipShape(Capsule())
            }
        }
    }
}
