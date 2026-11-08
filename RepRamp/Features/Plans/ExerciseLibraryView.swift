import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    let onSelect: (String) -> Void

    @State private var query = ""
    @State private var muscle = ""
    @State private var showCustom = false
    @State private var customName = ""
    @State private var customEquipment = "dumbbell"
    @State private var customMuscle = "chest"

    private var results: [Exercise] {
        Array(ExerciseRepository.search(query: query, in: exercises, muscle: muscle).prefix(200))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chip(title: "All", isOn: muscle.isEmpty) { muscle = "" }
                            ForEach(ExerciseRepository.muscleOptions, id: \.self) { option in
                                chip(title: option.capitalized, isOn: muscle == option) {
                                    muscle = muscle == option ? "" : option
                                }
                            }
                        }
                    }
                    .listRowBackground(Theme.background)
                }

                Section {
                    ForEach(results) { exercise in
                        Button {
                            onSelect(exercise.name)
                            dismiss()
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(exercise.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("\(exercise.primaryMuscle.capitalized) · \(exercise.displayEquipment.capitalized)")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Theme.orange)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("\(results.count) shown · \(exercises.count) total")
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .searchable(text: $query, prompt: "Search exercises")
            .navigationTitle("Exercise library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showCustom = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .foregroundStyle(Theme.orange)
                    .accessibilityLabel("Create custom exercise")
                }
            }
            .sheet(isPresented: $showCustom) {
                customSheet
            }
        }
    }

    private func chip(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isOn ? Color.white : Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isOn ? Theme.orange : Theme.surfaceHigh)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var customSheet: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $customName)
                    Picker("Muscle", selection: $customMuscle) {
                        ForEach(ExerciseRepository.muscleOptions, id: \.self) { option in
                            Text(option.capitalized).tag(option)
                        }
                    }
                    Picker("Equipment", selection: $customEquipment) {
                        ForEach(["barbell", "dumbbell", "cable", "machine", "body only", "other"], id: \.self) { option in
                            Text(option.capitalized).tag(option)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Custom exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCustom = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        _ = ExerciseRepository.createCustom(name: trimmed, muscles: [customMuscle], equipment: customEquipment, context: context)
                        onSelect(trimmed)
                        showCustom = false
                        dismiss()
                    }
                    .disabled(customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundStyle(Theme.orange)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
