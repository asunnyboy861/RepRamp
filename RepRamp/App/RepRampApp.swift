import SwiftUI
import SwiftData

@main
struct RepRampApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Exercise.self, Workout.self, SetEntry.self, Plan.self, UserProgress.self])
        var primaryError = ""
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            primaryError = String(describing: error)
            do {
                container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)])
            } catch {
                fatalError("ModelContainer failed. Primary: \(primaryError) | Memory: \(error)")
            }
        }
        if !primaryError.isEmpty {
            print("RepRamp container fallback: \(primaryError)")
        }
        let context = ModelContext(container)
        ExerciseRepository.seedIfNeeded(context: context)
        let progressCount = (try? context.fetchCount(FetchDescriptor<UserProgress>())) ?? 0
        if progressCount == 0 {
            context.insert(UserProgress())
            try? context.save()
        }
        #if DEBUG
        QASeed.apply(context: context)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
