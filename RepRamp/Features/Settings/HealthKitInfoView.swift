import SwiftUI

struct HealthKitInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.redHealth)
                    .padding(.top, 24)
                Text("HealthKit Integration")
                    .font(.title.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text("RepRamp connects to Apple Health through the HealthKit framework. Nothing is read until you grant permission, and permission is never required to use the app.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    infoRow(icon: "bed.double.fill", title: "Reads sleep analysis", detail: "Last night's sleep duration")
                    infoRow(icon: "waveform.path.ecg", title: "Reads HRV", detail: "Heart rate variability versus your 30-day baseline")
                    infoRow(icon: "heart.fill", title: "Reads resting heart rate", detail: "Recent resting heart rate")
                    infoRow(icon: "scalemass.fill", title: "Reads body weight", detail: "Most recent body mass")
                    infoRow(icon: "figure.strengthtraining.traditional", title: "Writes workouts", detail: "Completed strength sessions")
                }
                .cardStyle(padding: 20)

                Text("Why? When your sleep or HRV is well below baseline, RampCoach trims today's intensity and explains why. Without permission, recommendations simply use your lifting history only.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                Text("To change access later, open the Health app, tap your profile, then Privacy → Apps → RepRamp.")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)

                DisclaimerNote()
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .rampBackground()
        .navigationTitle("Apple Health (HealthKit)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Theme.orange)
            }
        }
    }

    private func infoRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.redHealth)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }
}
