import Foundation

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published private(set) var snapshot: ProgressSnapshot?

    func load(workouts: [Workout], progress: UserProgress?) {
        snapshot = ProgressAnalytics.snapshot(workouts: workouts, streak: progress?.streak ?? 0, bestStreak: progress?.bestStreak ?? 0)
    }
}
