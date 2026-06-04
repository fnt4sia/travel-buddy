//
//  WelcomeView.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//


import SwiftUI

struct WelcomeView: View {
    @State private var navigateToName = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GlobeRepresentable()
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer()

                Text("Welcome to VV!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Recommendations and friends\nbased on your preference.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Button(action: {
                    navigateToName = true
                }) {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accent)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToName) {
            NameInputView()
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
