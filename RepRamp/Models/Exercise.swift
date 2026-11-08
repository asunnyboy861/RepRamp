import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var muscleGroupsRaw: String
    var equipment: String
    var isCustom: Bool
    var instructions: String
    var level: String
    var category: String
    var force: String

    init(name: String, muscleGroups: [String], equipment: String, isCustom: Bool = false, instructions: String = "", level: String = "intermediate", category: String = "strength", force: String = "") {
        self.id = UUID()
        self.name = name
        self.muscleGroupsRaw = muscleGroups.joined(separator: ",")
        self.equipment = equipment
        self.isCustom = isCustom
        self.instructions = instructions
        self.level = level
        self.category = category
        self.force = force
    }

    var muscleGroups: [String] {
        muscleGroupsRaw.split(separator: ",").map { String($0) }
    }

    var primaryMuscle: String {
        muscleGroups.first ?? "full body"
    }

    var displayEquipment: String {
        equipment.isEmpty ? "bodyweight" : equipment
    }
}
