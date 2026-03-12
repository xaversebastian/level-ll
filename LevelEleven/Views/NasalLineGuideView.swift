//
//  NasalLineGuideView.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-12
//
//  Fullscreen visual guide for nasal dosing – shows proportional line widths
//  per participant so mg values translate into a concrete spatial reference.
//  Displayed as fullScreenCover before logging a nasal dose (QuickDoseView)
//  or before group logging in BallerModeView.
//
//  Linienbreite: lineWidth = min((amount / substance.commonDose) * 180, 300)
//  Referenzlinie: 180pt = commonDose (typisch ~50mg für Kokain)
//
//  Author: Silja & Xaver
//  Created: 2026-03-12
//

import SwiftUI

struct NasalLineGuideView: View {
    let substance: Substance
    let doses: [(profile: Profile, amount: Double)]
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // MARK: Header
                    VStack(spacing: 6) {
                        Text(substance.name)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Nasal Guide")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    // MARK: Intro
                    Text("Visual reference for line sizing. These are approximate – actual purity affects effects significantly.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // MARK: Dose Lines
                    VStack(spacing: 20) {
                        ForEach(doses, id: \.profile.id) { entry in
                            doseLineRow(profile: entry.profile, amount: entry.amount)
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: Reference Line
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reference")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.leading, 4)

                        referenceLine
                    }
                    .padding(.horizontal, 20)

                    // MARK: Disclaimers
                    VStack(spacing: 8) {
                        disclaimerRow(icon: "exclamationmark.triangle.fill",
                                      text: "Pure substance weight only",
                                      color: .orange)
                        disclaimerRow(icon: "arrow.down.circle.fill",
                                      text: "Purity varies – start smaller than intended",
                                      color: .yellow)
                        disclaimerRow(icon: "cross.circle.fill",
                                      text: "Never share equipment",
                                      color: .red.opacity(0.9))
                    }
                    .padding(.horizontal, 20)

                    // MARK: Confirm Button
                    Button(action: onConfirm) {
                        Label("Understood – Log Dose", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accent, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    // MARK: - Dose Line Row

    private func doseLineRow(profile: Profile, amount: Double) -> some View {
        let lineWidth = lineWidth(for: amount)
        let isHigh = amount > substance.strongDose

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(profile.avatarEmoji)
                    .font(.title3)
                Text(profile.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("~\(Int(amount.rounded())) \(substance.unit.symbol)")
                    .font(.caption.bold())
                    .foregroundStyle(isHigh ? .orange : .white.opacity(0.8))
            }

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.1))
                    .frame(maxWidth: .infinity)
                    .frame(height: 10)

                // Line
                RoundedRectangle(cornerRadius: 3)
                    .fill(isHigh
                          ? LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                          : LinearGradient(colors: [.white, .white.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: lineWidth, height: 10)
            }

            if isHigh {
                Text("Above strong dose – consider splitting")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Reference Line

    private var referenceLine: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.1))
                    .frame(maxWidth: .infinity)
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 180, height: 6)
            }

            HStack {
                Image(systemName: "arrow.left.and.right")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                Text("180pt ≈ common dose (\(Int(substance.commonDose.rounded())) \(substance.unit.symbol))")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Disclaimer Row

    private func disclaimerRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.subheadline)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func lineWidth(for amount: Double) -> Double {
        guard substance.commonDose > 0 else { return 40 }
        return min((amount / substance.commonDose) * 180, 300)
    }
}

#Preview {
    let profile = Profile(
        id: "preview",
        name: "Xaver",
        isActive: true,
        avatarEmoji: "😎",
        age: 31,
        weightKg: 83,
        sex: .male
    )
    let substance = Substances.all.first(where: { $0.id == "cocaine" }) ?? Substances.all[0]
    return NasalLineGuideView(
        substance: substance,
        doses: [(profile: profile, amount: 80)]
    ) {}
}
