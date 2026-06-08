//
//  LocationConfirmView.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//


import SwiftUI

struct LocationConfirmView: View {
    let city: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Hi, \(CurrentUserProfileStore.currentProfile().name).")
                .font(.largeTitle).bold()
            Text("Welcome to ")
                .font(.largeTitle).bold()
            Text(city)
                .font(.largeTitle).bold()
                .foregroundColor(AppColors.accent)

            Button("Start Exploring") {
                // navigate to main app
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.accent)
            .foregroundColor(AppColors.textOnAccent)
            .clipShape(Capsule())
            .padding(.horizontal)
            Spacer()
        }
    }
}
