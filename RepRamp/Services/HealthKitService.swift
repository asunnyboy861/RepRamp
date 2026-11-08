import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    @Published var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published var isAuthorized = false
    @Published var sleepHours: Double?
    @Published var hrvAverage: Double?
    @Published var hrvBaseline: Double?
    @Published var restingHeartRate: Double?
    @Published var bodyWeightLB: Double?
    @Published var recoveryFactor: Double = 1.0
    @Published var recoveryNote: String?

    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
        if let rhr = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { types.insert(rhr) }
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) { types.insert(weight) }
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        [HKObjectType.workoutType()]
    }

    var canRequest: Bool { isAvailable }

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
            await refresh()
        } catch {
            isAuthorized = false
        }
    }

    func refresh() async {
        guard isAvailable else { return }
        isAuthorized = store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
        let sleep = await fetchSleepHours()
        let hrv = await fetchAverage(typeIdentifier: .heartRateVariabilitySDNN, days: 1)
        let baseline = await fetchAverage(typeIdentifier: .heartRateVariabilitySDNN, days: 30)
        let rhr = await fetchAverage(typeIdentifier: .restingHeartRate, days: 7)
        let weight = await fetchLatest(typeIdentifier: .bodyMass)

        sleepHours = sleep
        hrvAverage = hrv
        hrvBaseline = baseline
        restingHeartRate = rhr
        bodyWeightLB = weight.map { $0 * 2.20462 }

        var factor = 1.0
        var notes: [String] = []
        if let sleep {
            if sleep < 5 {
                factor = min(factor, 0.65)
                notes.append("only \(String(format: "%.1f", sleep))h sleep")
            } else if sleep < 6 {
                factor = min(factor, 0.8)
                notes.append("\(String(format: "%.1f", sleep))h sleep")
            }
        }
        if let hrv, let baseline, baseline > 0, hrv < baseline * 0.85 {
            factor = min(factor, 0.8)
            notes.append("HRV below baseline")
        }
        recoveryFactor = factor
        if notes.isEmpty {
            recoveryNote = nil
        } else if factor < 0.7 {
            recoveryNote = "Recovery is low: \(notes.joined(separator: ", ")). Intensity trimmed today."
        } else {
            recoveryNote = "Recovery signal: \(notes.joined(separator: ", ")). Keep an eye on it."
        }
    }

    func saveWorkout(start: Date, end: Date) async {
        guard isAvailable, isAuthorized else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        do {
            try await builder.beginCollection(at: start)
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {
            return
        }
    }

    private func fetchSleepHours() async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let start = Calendar.current.date(byAdding: .hour, value: -30, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
        let samples = await query(type: type, predicate: predicate, limit: 40)
        let recent = samples.filter { $0.endDate > Calendar.current.date(byAdding: .hour, value: -18, to: .now) ?? .now }
        let asleep = recent.compactMap { $0 as? HKCategorySample }.filter {
            switch $0.value {
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                 HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                 HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                return true
            default:
                return false
            }
        }
        guard !asleep.isEmpty else { return nil }
        let total = asleep.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        return total / 3600
    }

    private func fetchAverage(typeIdentifier: HKQuantityTypeIdentifier, days: Int) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: typeIdentifier) else { return nil }
        let start = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
        let samples = await query(type: type, predicate: predicate, limit: 200)
        let values = samples.compactMap { sample -> Double? in
            guard let quantitySample = sample as? HKQuantitySample else { return nil }
            switch typeIdentifier {
            case .heartRateVariabilitySDNN:
                return quantitySample.quantity.doubleValue(for: .secondUnit(with: .milli))
            case .restingHeartRate:
                return quantitySample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            case .bodyMass:
                return quantitySample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            default:
                return nil
            }
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func fetchLatest(typeIdentifier: HKQuantityTypeIdentifier) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: typeIdentifier) else { return nil }
        let start = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
        let samples = await query(type: type, predicate: predicate, limit: 10)
        guard let sample = samples.first as? HKQuantitySample else { return nil }
        if typeIdentifier == .bodyMass {
            return sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
        }
        return nil
    }

    private func query(type: HKSampleType, predicate: NSPredicate?, limit: Int) async -> [HKSample] {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: limit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }
    }
}
