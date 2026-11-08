import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isPro = false
    private let purchaseManager = StoreKitManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        purchaseManager.$isPro
            .receive(on: RunLoop.main)
            .assign(to: &$isPro)
    }

    var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}
