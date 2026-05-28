//
//  UnifiedOnboardingView.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//

import SwiftUI

enum OnboardingStep {
    case welcome
    case nameInput
    case locationPermission
    case locationConfirmed
}

struct UnifiedOnboardingView: View {
    @State private var currentStep: OnboardingStep = .welcome
    @State private var firstName = ""
    @State private var city: String?
    @StateObject private var locationViewModel = LocationPermissionViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background color
            Color.white
                .ignoresSafeArea()
            
            // Fixed-size globe that moves down
            GlobeRepresentable()
                .frame(height: 300)
                .ignoresSafeArea(edges: .top)
                .offset(y: globeOffset)
            
            // Content positioned over the globe
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: contentTopSpacing)
                
                // Content based on current step
                Group {
                    switch currentStep {
                    case .welcome:
                        welcomeContent
                    case .nameInput:
                        nameInputContent
                    case .locationPermission:
                        locationPermissionContent
                    case .locationConfirmed:
                        locationConfirmedContent
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Globe Position Animation
    private var globeOffset: CGFloat {
        switch currentStep {
        case .welcome:
            return 0
        case .nameInput:
            return -50
        case .locationPermission:
            return -100
        case .locationConfirmed:
            return -150
        }
    }
    
    // MARK: - Content Top Spacing
    private var contentTopSpacing: CGFloat {
        switch currentStep {
        case .welcome:
            return 100
        case .nameInput:
            return 50
        case .locationPermission:
            return 0
        case .locationConfirmed:
            return -50
        }
    }
    
    // MARK: - Welcome Content
    private var welcomeContent: some View {
        VStack(spacing: 12) {
            Text("Welcome to VV!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text("Recommendations and friends\nbased on your preference.")
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.6)) {
                    currentStep = .nameInput
                }
            }) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Name Input Content
    private var nameInputContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentStep = .welcome
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("Name — 1 of 2")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentStep = .locationPermission
                    }
                }) {
                    Text("Skip")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 12)
            
            Text("Let's start your\nadventure!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
                .frame(height: 24)
            
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
                withAnimation(.easeInOut(duration: 0.6)) {
                    currentStep = .locationPermission
                }
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
    }
    
    // MARK: - Location Permission Content
    private var locationPermissionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentStep = .nameInput
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("Location — 2 of 2")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentStep = .locationConfirmed
                    }
                }) {
                    Text("Skip")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 12)
            
            Text("Enable your Location 📍")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text("Location access allows you to find recommended local activities and groups of people that are relevant to you.")
                .foregroundColor(.black.opacity(0.7))
                .font(.body)
            
            Spacer()
                .frame(height: 24)
            
            Button(action: {
                Task {
                    await locationPermissionTapped()
                }
            }) {
                Text(locationViewModel.isLoading ? "Finding location..." : "Allow location access")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .disabled(locationViewModel.isLoading)
        }
    }
    
    // MARK: - Location Confirmed Content
    private var locationConfirmedContent: some View {
        VStack(spacing: 12) {
            let userName = UserDefaults.standard.string(forKey: "userName") ?? "there"
            let displayCity = city ?? "your city"
            
            Text("Hi, \(userName).")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            HStack(spacing: 0) {
                Text("Welcome to ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text(displayCity)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.teal)
            }
            
            Spacer()
                .frame(height: 24)
            
            Button(action: {
                UserDefaults.standard.set(true, forKey: "hasOnboarded")
            }) {
                Text("Start Exploring")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Location Permission Handler
    private func locationPermissionTapped() async {
        await locationViewModel.allowLocationTapped()
        if locationViewModel.navigateToConfirm {
            city = locationViewModel.city
            withAnimation(.easeInOut(duration: 0.6)) {
                currentStep = .locationConfirmed
            }
        }
    }
}

#Preview {
    NavigationStack {
        UnifiedOnboardingView()
    }
}
