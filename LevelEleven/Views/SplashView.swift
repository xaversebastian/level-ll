// SplashView.swift — LevelEleven
// v1.0 | 2026-03-13 00:21
// - Animated splash screen with logo-mark fade-in and scale
//

import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var logoScale: Double = 0.8
    @State private var wordmarkOpacity: Double = 0
    @State private var finished = false

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Image("logo-mark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)

                Image("logo-wordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)
                    .opacity(wordmarkOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                logoOpacity = 1
                logoScale = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                wordmarkOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    finished = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onFinished()
                }
            }
        }
        .opacity(finished ? 0 : 1)
    }
}

#Preview {
    SplashView {}
}
