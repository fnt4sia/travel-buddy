//
//  ContentView.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 20/05/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var showsOnboardingIntro = true

    var body: some View {
        if hasOnboarded {
            MainTabView()
        } else if showsOnboardingIntro {
            OnboardingIntroView()
                .task {
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation(.easeInOut(duration: 0.45)) {
                        showsOnboardingIntro = false
                    }
                }
        } else {
            NavigationStack {
                UnifiedOnboardingView()
            }
        }
    }
}

private struct OnboardingIntroView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColors.accentSurface,
                    AppColors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                AnimatedGIFView(assetName: "gloob", repeatCount: 1)
                    .frame(width: 168, height: 168)
                    .accessibilityHidden(true)

                Text("Gloob")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppColors.brandPrimary,
                                AppColors.brandSecondary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    ContentView()
}
