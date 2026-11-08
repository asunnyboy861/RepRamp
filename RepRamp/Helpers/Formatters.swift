import Foundation

enum RampFormat {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func weight(_ value: Double) -> String {
        guard value > 0 else { return "BW" }
        return "\(numberFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))") lb"
    }

    static func weightNumber(_ value: Double) -> String {
        guard value > 0 else { return "0" }
        return numberFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    static func volume(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "\(formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))") lb"
    }

    static func percent(_ value: Double) -> String {
        String(format: "%+.0f%%", value)
    }

    static func dateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    static func clock(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }
}
