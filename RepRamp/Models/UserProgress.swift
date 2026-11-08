import Foundation
import SwiftData

@Model
final class UserProgress {
    @Attribute(.unique) var id: UUID
    var totalXP: Int
    var streak: Int
    var bestStreak: Int
    var lastWorkoutDay: Date?
    var lastWeeklyBonusAt: Date?
    var generatedPlanCount: Int

    init() {
        self.id = UUID()
        self.totalXP = 0
        self.streak = 0
        self.bestStreak = 0
        self.lastWorkoutDay = nil
        self.lastWeeklyBonusAt = nil
        self.generatedPlanCount = 0
    }

    var rank: RepRank { RankEngine.rank(for: totalXP) }
    var xpInRank: Int { RankEngine.xpProgress(for: totalXP) }
    var xpForNextRank: Int { RankEngine.xpToNext(for: totalXP) }
}
