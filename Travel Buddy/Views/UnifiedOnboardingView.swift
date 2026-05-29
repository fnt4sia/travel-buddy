//
//  UnifiedOnboardingView.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//

import SwiftUI
import CoreLocation

private let colors = AppColors()

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
    @State private var userLocation: CLLocation?
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var locationViewModel = LocationPermissionViewModel()


    var body: some View {
        ZStack(alignment: .top) {
            backgroundView
                .ignoresSafeArea()

            GlobeRepresentable(location: userLocation)
                .frame(height: 1200)
                .ignoresSafeArea(edges: .top)
                .offset(y: globeOffset)

            // Content overlay
            if currentStep == .welcome {
                VStack(spacing: 0) {
                    Spacer()

                    welcomeContent
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)

                    Spacer()
                        .frame(height: 200)
                }
            } else {
                VStack(spacing: 0) {

                    Spacer()
                        .frame(height: 220)
                    titleView
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    Spacer()

                    // Header
                    VStack(spacing: 0) {

                        headerView
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 12)

                        // Form at bottom with glass effect
                        formContent
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)

                            .padding(.horizontal, 12)
                            .padding(.bottom, 48)
                    }.background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(AppColors.formBackground)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        AppColors.formBorder,
                                        lineWidth: 1
                                    )
                            )
                    )

                    Spacer()
                        .frame(height: 200)
                }
            }
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private var formContent: some View {
        switch currentStep {
        case .welcome:
            EmptyView()
        case .nameInput:
            nameInputFormContent
        case .locationPermission:
            locationPermissionFormContent
        case .locationConfirmed:
            locationConfirmedFormContent
        }
    }

    @ViewBuilder
    private var headerView: some View {
        if currentStep != .locationConfirmed {
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentStep =
                            currentStep == .nameInput ? .welcome : .nameInput
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppColors.primaryText)
                }

                Spacer()

                Text(stepLabel)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        if currentStep == .nameInput {
                            currentStep = .locationPermission
                        } else if currentStep == .locationPermission {
                            currentStep = .locationConfirmed
                        }
                    }
                }) {
                    Text("Skip")
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
        }
    }

    @ViewBuilder
    private var titleView: some View {
        switch currentStep {
        case .welcome:
            EmptyView()
        case .nameInput:
            Text("Let's start your\nadventure!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryText)
        case .locationPermission:
            Text("Enable your Location 📍")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryText)
        case .locationConfirmed:
            VStack(alignment: .center, spacing: 4) {
                Text(
                    "Hi, \(UserDefaults.standard.string(forKey: "userName") ?? "there")."
                )
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryText)

                HStack(spacing: 0) {
                    Text("Welcome to ")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryText)

                    Text(city ?? "your city")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var stepLabel: String {
        switch currentStep {
        case .welcome:
            return ""
        case .nameInput:
            return "Name — 1 of 2"
        case .locationPermission:
            return "Location — 2 of 2"
        case .locationConfirmed:
            return ""
        }
    }

    private var nameInputFormContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("First name")
                .font(.headline)
                .foregroundColor(AppColors.primaryText)

            TextField("How can we address you?", text: $firstName)
                .padding()
                .background(AppColors.textFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.textFieldBorder, lineWidth: 1)
                )

            Button(action: {
                guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty
                else { return }
                UserDefaults.standard.set(firstName, forKey: "userName")
                withAnimation(.easeInOut(duration: 0.6)) {
                    currentStep = .locationPermission
                }
            }) {
                Text("Let's go")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        firstName.isEmpty ? AppColors.accentDisabled : AppColors.accent
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .disabled(firstName.isEmpty)
        }
    }

    private var locationPermissionFormContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(
                "Location access allows you to find recommended local activities and groups of people that are relevant to you."
            )
            .foregroundColor(AppColors.primaryText.opacity(0.7))
            .font(.body)
            .lineLimit(nil)

            Button(action: {
                Task {
                    await locationPermissionTapped()
                }
            }) {
                Text(
                    locationViewModel.isLoading
                        ? "Finding location..." : "Allow location access"
                )
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.accent)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .disabled(locationViewModel.isLoading)
        }
    }

    private var locationConfirmedFormContent: some View {
        Button(action: {
            if let detectedCity = city {
                UserDefaults.standard.set(detectedCity, forKey: "userCity")
            }

            hasOnboarded = true
        }) {
            Text("Start Exploring")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.accent)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
    }

    private var backgroundView: some View {
        if currentStep == .welcome {
            return AnyView(AppColors.welcomeBackground)
        } else {
            return AnyView(AppColors.background)
        }
    }

    private var globeOffset: CGFloat {
        switch currentStep {
        case .welcome:
            return -250
        case .nameInput:
            return 250
        case .locationPermission:
            return 250
        case .locationConfirmed:
            return 200
        }
    }

    private var welcomeContent: some View {
        VStack(spacing: 12) {
            Text("Welcome to VV!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Recommendations and friends\nbased on your preference.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
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
                    .background(AppColors.accent)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
    }

    private func locationPermissionTapped() async {
        await locationViewModel.allowLocationTapped()
        if locationViewModel.navigateToConfirm {
            city = locationViewModel.city
            userLocation = locationViewModel.location
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
