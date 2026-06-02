//
//  NameInputView.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//


import SwiftUI

struct NameInputView: View {
    @State private var firstName = ""
    @State private var navigateToLocation = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            GlobeRepresentable()
                .equatable()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {

                Text("Let's start your\nadventure!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 48)
                    .padding(.horizontal, 24)

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text("First name")
                        .font(.headline)
                        .foregroundColor(.black)

                    TextField("How can we address you?", text: $firstName)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    Button(action: {
                        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        UserDefaults.standard.set(firstName, forKey: "userName")
                        navigateToLocation = true
                    }) {
                        Text("Let's go")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(firstName.isEmpty ? Color.teal.opacity(0.4) : Color.teal)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .disabled(firstName.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToLocation) {
            LocationPermissionView()
        }
    }
}

#Preview {
    NavigationStack {
        NameInputView()
    }
}
