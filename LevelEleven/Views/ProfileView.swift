//
//  ProfileView.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  Profilverwaltung: Liste aller Profile mit Swipe-to-Delete und Edit.
//  Tipp auf ein Profil setzt es als aktives Profil. Plus-Button öffnet ProfileEditorView.
//  ProfileEditorView (in dieser Datei) erlaubt Erstellen und Bearbeiten:
//  Name, Emoji-Avatar (Grid-Picker), Alter/Gewicht/Geschlecht, ADHS-Flag,
//  persönliches Limit (1–11) und Toleranzwerte je Substanz (Stepper 0–11).
//
//  HINWEIS: Löschen eines Profils entfernt auch alle zugehörigen Doses (AppState.deleteProfile).
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddProfile = false
    @State private var editingProfile: Profile?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Profiles") {
                    ForEach(appState.profiles) { profile in
                        profileRow(profile)
                    }
                    .onDelete(perform: deleteProfiles)
                    
                    Button {
                        showAddProfile = true
                    } label: {
                        Label("Add Profile", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Profiles")
            .sheet(isPresented: $showAddProfile) {
                ProfileEditorView(profile: nil)
                    .environment(appState)
            }
            .sheet(item: $editingProfile) { profile in
                ProfileEditorView(profile: profile)
                    .environment(appState)
            }
        }
    }
    
    private func profileRow(_ profile: Profile) -> some View {
        Button {
            appState.setActiveProfile(profile)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(profile.isActive ? Color.accent.opacity(0.12) : Color.secondary.opacity(0.08))
                        .frame(width: 46, height: 46)
                    Text(profile.avatarEmoji)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.headline)
                    Text("\(profile.age) years · \(Int(profile.weightKg)) kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if profile.isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accent)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, profile.isActive ? 10 : 0)
            .background(
                profile.isActive ? Color.accent.opacity(0.06) : Color.clear,
                in: RoundedRectangle(cornerRadius: DS.chipRadius)
            )
        }
        .foregroundStyle(.primary)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                appState.deleteProfile(profile.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                editingProfile = profile
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
        }
    }
    
    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            appState.deleteProfile(appState.profiles[index].id)
        }
    }
}

struct ProfileEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    let profile: Profile?
    
    @State private var name = ""
    @State private var avatarEmoji = "😎"
    @State private var age = 30
    @State private var weightKg = 70.0
    @State private var sex: BiologicalSex = .male
    @State private var hasADHD = false
    @State private var takeSSRI = false
    @State private var personalLimit = 7
    @State private var tolerances: [String: Int] = [:]
    /// Originale Toleranz-Objekte mit lastUsedDate – wird beim Speichern preserviert
    @State private var existingTolerances: [Tolerance] = []
    @State private var showEmojiPicker = false
    
    // Avatar emoji options – using face emojis that render reliably on all iOS versions
    private let avatarCategories: [(name: String, emojis: [String])] = [
        ("Faces", [
            "😎", "🥰", "😊", "🤓", "🥳", "😏",
            "🤠", "🥸", "😇", "🤩", "😌", "😈"
        ]),
        ("People", [
            "👨🏻", "👨🏼", "👨🏽", "👨🏾", "👨🏿", "😏",
            "👩🏻", "👩🏼", "👩🏽", "👩🏾", "👩🏿", "💀"
        ]),
        ("Vibes", [
            "🔥", "💜", "⚡️", "🌈", "🍀", "🎯",
            "🦄", "🐺", "🦊", "🐱", "🎵", "👑"
        ])
    ]
    
    var isEditing: Bool { profile != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                physiologySection
                tolerancesSection
            }
            .navigationTitle(isEditing ? "Edit Profile" : "New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveProfile() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadProfile)
        }
    }
    
    private var basicInfoSection: some View {
        Section("Basic Info") {
            TextField("Name", text: $name)
            
            Button {
                showEmojiPicker = true
            } label: {
                HStack {
                    Text("Avatar")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(avatarEmoji)
                        .font(.largeTitle)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .sheet(isPresented: $showEmojiPicker) {
                emojiPickerSheet
            }
        }
    }
    
    private var emojiPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(avatarCategories, id: \.name) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 12) {
                                ForEach(category.emojis, id: \.self) { emoji in
                                    Button {
                                        avatarEmoji = emoji
                                        showEmojiPicker = false
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 32))
                                            .frame(width: 48, height: 48)
                                            .background(
                                                avatarEmoji == emoji 
                                                    ? Color.accent.opacity(0.2) 
                                                    : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 10)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showEmojiPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var physiologySection: some View {
        Section("Physiology") {
            HStack {
                Text("Age")
                Spacer()
                Text("\(age) years")
                    .foregroundStyle(.secondary)
            }
            Slider(value: Binding(
                get: { Double(age) },
                set: { age = Int($0) }
            ), in: 16...80, step: 1)
            
            HStack {
                Text("Weight")
                Spacer()
                Text("\(Int(weightKg)) kg")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $weightKg, in: 40...150, step: 1)
            
            Picker("Sex", selection: $sex) {
                ForEach(BiologicalSex.allCases, id: \.self) { s in
                    Text(s.displayName).tag(s)
                }
            }
            
            Toggle("Has ADHD", isOn: $hasADHD)

            VStack(alignment: .leading, spacing: 2) {
                Toggle("Takes SSRIs", isOn: $takeSSRI)
                Text("Increases serotonin syndrome risk with MDMA/LSD")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Personal Limit")
                Spacer()
                Text("Level \(personalLimit)")
                    .foregroundStyle(.secondary)
            }
            Slider(value: Binding(
                get: { Double(personalLimit) },
                set: { personalLimit = Int($0) }
            ), in: 1...11, step: 1)
        }
    }
    
    private var tolerancesSection: some View {
        Section(header: Text("Tolerances"), footer: Text("Tolerance decays over time with abstinence. Effective level shown when lower than peak.").font(.caption)) {
            ForEach(Substances.all) { substance in
                let peakLevel = tolerances[substance.id] ?? 5
                let existing = existingTolerances.first { $0.substanceId == substance.id }
                let effectiveLevel = existing.map { t -> Int in
                    // Use current edited level as base for decay calculation
                    var copy = t; copy.level = peakLevel; return copy.effectiveLevel
                } ?? peakLevel
                let isDecaying = effectiveLevel < peakLevel

                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: substance.category.icon)
                        .foregroundStyle(Color(hex: substance.category.color))
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(substance.shortName)
                        if isDecaying {
                            HStack(spacing: 4) {
                                Text("Peak: \(peakLevel) → Effective: \(effectiveLevel)")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    Spacer()

                    Stepper(
                        "\(peakLevel)",
                        value: Binding(
                            get: { tolerances[substance.id] ?? 5 },
                            set: { tolerances[substance.id] = $0 }
                        ),
                        in: 0...11
                    )
                }
            }
        }
    }
    
    private func loadProfile() {
        guard let p = profile else { return }
        name = p.name
        avatarEmoji = p.avatarEmoji
        age = p.age
        weightKg = p.weightKg
        sex = p.sex
        hasADHD = p.hasADHD
        takeSSRI = p.takeSSRI
        personalLimit = p.personalLimit
        existingTolerances = p.tolerances
        for t in p.tolerances {
            tolerances[t.substanceId] = t.level
        }
    }

    private func saveProfile() {
        // Preserve lastUsedDate from existing tolerances
        let toleranceArray = tolerances.map { substanceId, level -> Tolerance in
            let existing = existingTolerances.first { $0.substanceId == substanceId }
            return Tolerance(substanceId: substanceId, level: level, lastUsedDate: existing?.lastUsedDate)
        }

        if let existing = profile {
            var updated = existing
            updated.name = name.trimmingCharacters(in: .whitespaces)
            updated.avatarEmoji = avatarEmoji
            updated.age = age
            updated.weightKg = weightKg
            updated.sex = sex
            updated.hasADHD = hasADHD
            updated.takeSSRI = takeSSRI
            updated.personalLimit = personalLimit
            updated.tolerances = toleranceArray
            appState.updateProfile(updated)
        } else {
            let newProfile = Profile(
                name: name.trimmingCharacters(in: .whitespaces),
                avatarEmoji: avatarEmoji,
                age: age,
                weightKg: weightKg,
                sex: sex,
                hasADHD: hasADHD,
                takeSSRI: takeSSRI,
                tolerances: toleranceArray,
                personalLimit: personalLimit
            )
            appState.addProfile(newProfile)
        }

        dismiss()
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
}
