//
//  ProfileView.swift
//  LevelEleven
//
//  Version: 3.0  |  2026-03-12
//
//  Profilverwaltung: Liste aller Profile mit Swipe-to-Delete und Edit.
//  Tipp auf ein Profil setzt es als aktives Profil. Plus-Button öffnet ProfileEditorView.
//  ProfileEditorView (in dieser Datei) erlaubt Erstellen und Bearbeiten:
//  Name, Emoji-Avatar (Grid-Picker), Alter/Gewicht/Geschlecht, ADHS-Flag,
//  persönliches Limit (1–11) und Toleranzwerte je Substanz (Stepper 0–11).
//
//  Updates v3.0:
//  - Flat rows on warm cream background matching HomeView
//  - Removed card chrome and shadows
//  - Consistent section headers with accent bars
//  - DS.screenPadding everywhere
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddProfile = false
    @State private var editingProfile: Profile?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    sectionHeader("Profiles")
                    
                    ForEach(Array(appState.profiles.enumerated()), id: \.element.id) { idx, profile in
                        if idx > 0 { thinDivider }
                        profileRow(profile)
                    }
                    
                    thinDivider

                    Button {
                        showAddProfile = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accent)
                                .frame(width: 22)
                            
                            Text("Add Profile")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.accent)
                            
                            Spacer()
                        }
                        .padding(.horizontal, DS.screenPadding)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .pressFeedback()
                }
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
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
                // Left accent line for active profile
                RoundedRectangle(cornerRadius: 2)
                    .fill(profile.isActive ? Color.accent : Color.clear)
                    .frame(width: 3, height: 40)
                
                Text(profile.avatarEmoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.subheadline.bold())
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
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .foregroundStyle(.primary)
        .buttonStyle(.plain)
        .pressFeedback()
        .contextMenu {
            Button {
                editingProfile = profile
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                appState.deleteProfile(profile.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var thinDivider: some View {
        Divider()
            .padding(.leading, 54)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, color: Color = .secondary) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: 16)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(color)
            Spacer()
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.top, 22)
        .padding(.bottom, 8)
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

    private func editorSectionHeader(_ title: String, color: Color = .secondary) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: 16)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(color)
            Spacer()
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    basicInfoSection
                    physiologySection
                    tolerancesSection
                }
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
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
        VStack(spacing: 0) {
            editorSectionHeader("Basic Info", color: Color.accent)

            // Name field
            HStack {
                Text("Name")
                    .font(.subheadline)
                Spacer()
                TextField("Name", text: $name)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)

            Divider().padding(.leading, 54)

            // Avatar picker
            Button {
                showEmojiPicker = true
            } label: {
                HStack {
                    Text("Avatar")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(avatarEmoji)
                        .font(.largeTitle)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .pressFeedback()
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
                                .padding(.horizontal, DS.screenPadding)
                            
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
                                                    ? Color.accent.opacity(0.15) 
                                                    : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 10)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, DS.screenPadding)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
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
        VStack(spacing: 0) {
            editorSectionHeader("Physiology", color: Color.accent)

            // Age
            VStack(spacing: 4) {
                HStack {
                    Text("Age")
                        .font(.subheadline)
                    Spacer()
                    Text("\(age) years")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(age) },
                    set: { age = Int($0) }
                ), in: 16...80, step: 1)
                .tint(Color.accent)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 10)

            Divider().padding(.leading, 54)

            // Weight
            VStack(spacing: 4) {
                HStack {
                    Text("Weight")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(weightKg)) kg")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $weightKg, in: 40...150, step: 1)
                    .tint(Color.accent)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 10)

            Divider().padding(.leading, 54)

            // Sex
            HStack {
                Text("Sex")
                    .font(.subheadline)
                Spacer()
                Picker("Sex", selection: $sex) {
                    ForEach(BiologicalSex.allCases, id: \.self) { s in
                        Text(s.displayName).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 10)

            Divider().padding(.leading, 54)

            // ADHD
            Toggle(isOn: $hasADHD) {
                Text("Has ADHD")
                    .font(.subheadline)
            }
            .tint(Color.accent)
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 10)

            Divider().padding(.leading, 54)

            // SSRIs
            VStack(alignment: .leading, spacing: 2) {
                Toggle(isOn: $takeSSRI) {
                    Text("Takes SSRIs")
                        .font(.subheadline)
                }
                .tint(Color.accent)
                Text("Increases serotonin syndrome risk with MDMA/LSD")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 10)

            Divider().padding(.leading, 54)

            // Personal Limit
            VStack(spacing: 4) {
                HStack {
                    Text("Personal Limit")
                        .font(.subheadline)
                    Spacer()
                    Text("Level \(personalLimit)")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.accent)
                }
                Slider(value: Binding(
                    get: { Double(personalLimit) },
                    set: { personalLimit = Int($0) }
                ), in: 1...11, step: 1)
                .tint(Color.accent)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 10)
        }
    }
    
    private var tolerancesSection: some View {
        VStack(spacing: 0) {
            editorSectionHeader("Tolerances", color: Color.accent)

            Text("Tolerance decays over time with abstinence. Effective level shown when lower than peak.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.screenPadding)
                .padding(.bottom, 8)

            ForEach(Array(Substances.all.enumerated()), id: \.element.id) { idx, substance in
                if idx > 0 { Divider().padding(.leading, 54) }

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
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(substance.shortName)
                            .font(.subheadline)
                        if isDecaying {
                            HStack(spacing: 4) {
                                Text("Peak: \(peakLevel) → Eff: \(effectiveLevel)")
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
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 8)
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
