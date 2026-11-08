import Foundation
import SwiftUI

enum RepRank: Int, CaseIterable, Codable {
    case unranked = 0
    case bronze
    case silver
    case gold
    case platinum
    case diamond
    case master
    case legend

    var title: String {
        switch self {
        case .unranked: return "Unranked"
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .platinum: return "Platinum"
        case .diamond: return "Diamond"
        case .master: return "Master"
        case .legend: return "Legend"
        }
    }

    var color: Color { Theme.rankColor(self) }
}

struct RankChange {
    let xpGained: Int
    let leveledUp: Bool
    let previousRank: RepRank
    let newRank: RepRank
}

enum RankEngine {
    static let thresholds: [Int] = [0, 100, 350, 850, 1750, 3250, 5750, 9500]

    static func rank(for xp: Int) -> RepRank {
        var result = RepRank.unranked
        for (index, threshold) in thresholds.enumerated() where xp >= threshold {
            result = RepRank(rawValue: index) ?? result
        }
        return result
    }

    static func xpProgress(for xp: Int) -> Int {
        let rank = rank(for: xp)
        return max(0, xp - thresholds[rank.rawValue])
    }

    static func xpToNext(for xp: Int) -> Int {
        let rank = rank(for: xp)
        guard rank != .legend else { return 0 }
        return max(1, thresholds[rank.rawValue + 1] - xp)
    }

    static func rankProgressFraction(for xp: Int) -> Double {
        let rank = rank(for: xp)
        guard rank != .legend else { return 1.0 }
        let start = thresholds[rank.rawValue]
        let end = thresholds[rank.rawValue + 1]
        guard end > start else { return 1.0 }
        return min(1.0, max(0.0, Double(xp - start) / Double(end - start)))
    }

    @discardableResult
    static func award(_ amount: Int, to progress: UserProgress) -> RankChange {
        let before = progress.rank
        progress.totalXP += max(0, amount)
        let after = progress.rank
        return RankChange(xpGained: amount, leveledUp: after.rawValue > before.rawValue, previousRank: before, newRank: after)
    }

    static func registerWorkoutDay(_ date: Date, progress: UserProgress) {
        guard let last = progress.lastWorkoutDay else {
            progress.streak = 1
            progress.bestStreak = max(progress.bestStreak, 1)
            progress.lastWorkoutDay = date
            return
        }
        if Calendar.current.isDate(last, inSameDayAs: date) { return }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: last), to: Calendar.current.startOfDay(for: date)).day ?? 0
        progress.streak = days == 1 ? progress.streak + 1 : 1
        progress.bestStreak = max(progress.bestStreak, progress.streak)
        progress.lastWorkoutDay = date
        if progress.streak >= 7 && progress.streak % 7 == 0 {
            _ = award(200, to: progress)
        }
    }
}
