import SwiftUI
import SwiftData
import PhotosUI

struct BodyScanView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Plan.createdAt, order: .reverse) private var plans: [Plan]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @StateObject private var viewModel = BodyScanViewModel()
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var applied = false

    private var gateway: AIGateway { AIGateway.shared }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if !gateway.canUseVisionAI {
                    lockedCard
                } else if let result = viewModel.result {
                    resultContent(result)
                } else {
                    captureContent
                }
                DisclaimerNote()
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .rampBackground()
        .navigationTitle("Body Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Theme.orange)
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showSettings) {
            NavigationStack { AISettingsView() }
        }
        .alert("Priorities applied", isPresented: $applied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your active plan now adds one set to the priority muscle groups.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AI BODY SCAN")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(Theme.orange)
            Text("Find your weak links")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("One clear photo. Muscle balance radar, three coaching priorities, and a one-tap plan adjustment.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var lockedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.orange)
                Text("Cloud vision required")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }
            Text("Body Scan runs on GLM vision through the cloud, or on your own vision-capable API key. Unlock Pro or configure a provider in Settings.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Button("Unlock cloud AI") { showPaywall = true }
                .buttonStyle(PrimaryButtonStyle())
            Button("Open AI settings") { showSettings = true }
                .buttonStyle(SecondaryButtonStyle())
        }
        .cardStyle(padding: 20)
    }

    private var captureContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            PhotosPicker(selection: $viewModel.photoItem, matching: .images, photoLibrary: .shared()) {
                if let preview = viewModel.preview {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.orange)
                        Text("Add a front or side photo")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Stand straight, neutral light, full torso in frame.")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Theme.orange.opacity(0.35), lineWidth: 1)
                    )
                }
            }
            .onChange(of: viewModel.photoItem) { _, newValue in
                Task { await viewModel.loadPhoto(newValue) }
            }

            if viewModel.isAnalyzing {
                analyzingCard
            } else {
                Button("Analyze my physique") {
                    Task { await viewModel.analyze() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.imageData == nil)
                .opacity(viewModel.imageData == nil ? 0.45 : 1.0)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Theme.warning)
                    .cardStyle()
            }

            Text("Photos are sent only when you tap Analyze and are discarded immediately after processing. Nothing is stored.")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var analyzingCard: some View {
        HStack(spacing: 14) {
            ProgressView().tint(Theme.orange)
            VStack(alignment: .leading, spacing: 3) {
                Text("Reading your muscle balance")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("Vision model is checking symmetry and development. 15-30 seconds.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    private func resultContent(_ result: BodyScanResult) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            MuscleRadarChart(scores: result.balance)
                .frame(height: 300)
                .cardStyle()
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Priority fixes", subtitle: result.summary)
                ForEach(result.priorities, id: \.self) { priority in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "target")
                            .foregroundStyle(Theme.orange)
                        Text(priority)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surfaceHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .cardStyle()
            Button("Turn priorities into my plan") {
                apply(result.priorities)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(PlanRepository.activePlan(from: plans) == nil)
            Button("Scan another photo") {
                viewModel.reset()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private func apply(_ priorities: [String]) {
        guard let plan = PlanRepository.activePlan(from: plans) else { return }
        PlanRepository.applyPriorities(priorities, to: plan, exercises: exercises, context: context)
        applied = true
    }
}
