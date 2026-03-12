// LevelGaugeView.swift — LevelEleven
// v2.0 | 2026-03-12 17:18
// - Animated circular gauge with angular gradient and tick marks (0-11)
// - Includes mini variant for compact display
// - Stripped legacy comments, added structured header
//

import SwiftUI

struct LevelGaugeView: View {
    let level: Double
    let color: Color
    
    @State private var animatedLevel: Double = 0
    
    private let size: CGFloat = 220
    private let ringWidth: CGFloat = 22
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size + 40, height: size + 40)
                .blur(radius: 25)
            
            // Outer ring background with subtle gradient
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.gray.opacity(0.15), .gray.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: ringWidth
                )
            
            // Level fill with enhanced gradient
            Circle()
                .trim(from: 0, to: min(animatedLevel / 11.0, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.5),
                            color,
                            color.opacity(0.9),
                            color
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.6), radius: 12, x: 0, y: 4)
            
            // Inner circle
            Circle()
                .fill(Color.appBackground.opacity(0.85))
                .padding(ringWidth + 12)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            
            // Inner subtle ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 1)
                .padding(ringWidth + 12)
            
            // Center content
            VStack(spacing: 2) {
                Text(String(format: "%.1f", animatedLevel))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            // Tick marks - larger and better positioned
            ForEach(0..<12) { i in
                Rectangle()
                    .fill(i <= Int(animatedLevel) ? color : .gray.opacity(0.25))
                    .frame(width: i % 3 == 0 ? 3 : 2, height: i % 3 == 0 ? 14 : 8)
                    .offset(y: -(size / 2 - 6))
                    .rotationEffect(.degrees(Double(i) * 30))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedLevel = level
            }
        }
        .onChange(of: level) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animatedLevel = newValue
            }
        }
    }
}

struct LevelGaugeMiniView: View {
    let level: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.2), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: min(level / 11.0, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text(String(format: "%.0f", level))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(width: 40, height: 40)
    }
}

#Preview {
    VStack(spacing: 40) {
        LevelGaugeView(level: 5.5, color: .orange)
        HStack {
            LevelGaugeMiniView(level: 3, color: .green)
            LevelGaugeMiniView(level: 6, color: .orange)
            LevelGaugeMiniView(level: 9, color: .red)
        }
    }
    .padding()
}
