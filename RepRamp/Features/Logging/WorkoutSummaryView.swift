import SwiftUI

struct WorkoutSummaryView: View {
    let summary: WorkoutSummary
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.success)
                    Text("Session complete")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(summary.sessionName)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 24)

                if summary.leveledUp {
                    HStack(spacing: 14) {
                        RankBadgeView(rank: summary.rank, size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rank up!")
                                .font(.headline)
                                .foregroundStyle(Theme.rankColor(summary.rank))
                            Text("You are now \(summary.rank.title).")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                    }
                    .cardStyle()
                }

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        StatTile(value: RampFormat.volume(summary.volume), label: "Total volume")
                        StatTile(value: "\(summary.sets)", label: "Working sets")
                    }
                    HStack(spacing: 10) {
                        StatTile(value: RampFormat.clock(Int(summary.duration)), label: "Duration")
                        StatTile(value: "+\(summary.xpGained)", label: "XP earned", tint: Theme.orange)
                    }
                }

                if !summary.personalRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "New personal records", subtitle: "Estimated 1RM beats your previous best.")
                        ForEach(summary.personalRecords, id: \.self) { record in
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(Theme.warning)
                                Text(record)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                            }
                            .padding(12)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Next up")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(summary.streak > 0 ? "\(summary.streak) day streak" : "")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.orange)
                    }
                    Text("Your next weights are already computed. Open the Today tab tomorrow and the work is done for you.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .cardStyle()

                DisclaimerNote()

                Button("Done") { onDone() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .rampBackground()
        .onAppear {
            for index in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.35) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
    }
}
