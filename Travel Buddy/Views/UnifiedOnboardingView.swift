import CoreLocation
import SwiftUI

enum OnboardingStep {
    case welcome
    case nameInput
    case profileDetails
    case locationPermission
    case locationConfirmed
}

struct UnifiedOnboardingView: View {
    @State private var currentStep: OnboardingStep = .welcome
    @State private var realName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var ageText = ""
    @State private var countryOrigin = CurrentUserProfileStore.defaultCountry
    @State private var selectedInterests = Set(
        CurrentUserProfileStore.defaultInterests
    )
    @State private var selectedLanguages = Set(
        CurrentUserProfileStore.defaultLanguages
    )
    @State private var city: String?
    @State private var userLocation: CLLocation?
    @State private var keyboardHeight: CGFloat = 0
    @State private var mascotIdle = false
    @State private var mascotsAreOffscreen = false
    @State private var accountError: String?
    @State private var isSavingProfile = false
    @ObservedObject private var supabaseService = SupabaseService.shared
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var locationViewModel = LocationPermissionViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            backgroundView
                .ignoresSafeArea()

            GlobeRepresentable(location: userLocation)
                .equatable()
                .frame(height: 1200)
                .ignoresSafeArea(edges: .top)
                .offset(y: globeOffset)
                .allowsHitTesting(false)
                .zIndex(0)

            mascotLayer
                .ignoresSafeArea()

            if currentStep == .welcome {
                VStack(spacing: 0) {
                    Spacer()
                    welcomeContent
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                        .zIndex(100)
                    Spacer()
                        .frame(height: 200)
                }
            } else {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 220)

                    titleView
                        .frame(maxWidth: .infinity, alignment: currentStep == .locationConfirmed ? .center : .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    Spacer()

                    VStack(spacing: 0) {
                        headerView
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 12)

                        formContent
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 32)
                    }
                    .padding(.bottom, keyboardHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(AppColors.formBackground)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(AppColors.formBorder, lineWidth: 1)
                            )
                    )
                    .ignoresSafeArea()

                    Spacer().frame(height: 140)
                    Spacer().frame(height: 32)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 5.8).repeatForever(autoreverses: true)) {
                mascotIdle = true
            }
        }
        .onChange(of: currentStep) { _, newStep in
            let shouldMoveOffscreen = newStep != .welcome
            withAnimation(.easeInOut(duration: shouldMoveOffscreen ? 1.15 : 0.85)) {
                mascotsAreOffscreen = shouldMoveOffscreen
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = max(0, frame.height - 150)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }

    // MARK: - Form content

    @ViewBuilder
    private var formContent: some View {
        switch currentStep {
        case .welcome:
            EmptyView()
        case .nameInput:
            nameInputFormContent
        case .profileDetails:
            profileDetailsFormContent
        case .locationPermission:
            locationPermissionFormContent
        case .locationConfirmed:
            locationConfirmedFormContent
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        if currentStep != .locationConfirmed {
            HStack {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppColors.primaryText)
                }

                Spacer()

                Text(stepLabel)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)

                Spacer()

                if currentStep == .locationPermission {
                    Button(action: {
                        CurrentUserProfileStore.ensureMemberSince()
                        withAnimation(.easeInOut(duration: 0.6)) {
                            currentStep = .locationConfirmed
                        }
                    }) {
                        Text("Skip")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                } else {
                    Color.clear.frame(width: 32, height: 18)
                }
            }
        }
    }

    // MARK: - Title

    @ViewBuilder
    private var titleView: some View {
        switch currentStep {
        case .welcome:
            EmptyView()
        case .nameInput:
            Text("Create your\nGloob profile")
                .font(.largeTitle).fontWeight(.bold)
                .foregroundColor(AppColors.primaryText)
        case .profileDetails:
            Text("Set your\ntravel vibe")
                .font(.largeTitle).fontWeight(.bold)
                .foregroundColor(AppColors.primaryText)
        case .locationPermission:
            Text("Enable your\nLocation 📍")
                .font(.largeTitle).fontWeight(.bold)
                .foregroundColor(AppColors.primaryText)
        case .locationConfirmed:
            VStack(alignment: .center, spacing: 4) {
                Text("Hi, \(CurrentUserProfileStore.currentProfile().name).")
                    .font(.largeTitle).fontWeight(.bold)
                    .foregroundColor(AppColors.primaryText)
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Text("Welcome to ")
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundColor(AppColors.primaryText)
                        Text(city ?? "your city")
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var stepLabel: String {
        switch currentStep {
        case .welcome: return ""
        case .nameInput: return "Account - 1 of 3"
        case .profileDetails: return "Profile - 2 of 3"
        case .locationPermission: return "Location - 3 of 3"
        case .locationConfirmed: return ""
        }
    }

    // MARK: - Form screens

    private var nameInputFormContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            onboardingTextField(
                title: "Real name",
                placeholder: "Your full name",
                text: $realName,
                keyboardType: .default,
                textContentType: .name,
                autocapitalization: .words
            )

            onboardingTextField(
                title: "Username",
                placeholder: "gloobmate",
                text: $username,
                keyboardType: .default,
                textContentType: .username,
                autocapitalization: .never
            )

            onboardingTextField(
                title: "Email",
                placeholder: "you@example.com",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never
            )

            if let accountError {
                Text(accountError)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: continueFromAccountStep) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isAccountReady ? AppColors.accent : AppColors.accentDisabled)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .disabled(!isAccountReady)
        }
    }

    private var profileDetailsFormContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Age")
                        .font(.headline).foregroundColor(AppColors.primaryText)
                    TextField("21", text: $ageText)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(AppColors.textFieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.textFieldBorder, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Country origin")
                        .font(.headline).foregroundColor(AppColors.primaryText)

                    Picker(selection: $countryOrigin) {
                        ForEach(CurrentUserProfileStore.availableCountries) { country in
                            Text("\(country.flag) \(country.name)")
                                .tag(country.name)
                        }
                    } label: {
                        countryPickerLabel
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.primaryText)
                }

                onboardingChoiceSection(
                    title: "Interests",
                    options: CurrentUserProfileStore.availableInterests,
                    selection: selectedInterests,
                    onTap: { interest in
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                            if selectedInterests.contains(interest) { selectedInterests.remove(interest) }
                            else { selectedInterests.insert(interest) }
                        }
                    }
                )

                onboardingChoiceSection(
                    title: "Languages spoken",
                    options: CurrentUserProfileStore.availableLanguages,
                    selection: selectedLanguages,
                    onTap: { language in
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                            if selectedLanguages.contains(language) { selectedLanguages.remove(language) }
                            else { selectedLanguages.insert(language) }
                        }
                    }
                )

                Button(action: {
                    continueFromProfileStep()
                }) {
                    Text(isSavingProfile ? "Saving..." : "Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProfileDetailsReady ? AppColors.accent : AppColors.accentDisabled)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .disabled(!isProfileDetailsReady || isSavingProfile)
            }
            .padding(.bottom, 4)
        }
        .frame(maxHeight: 470)
    }

    private var locationPermissionFormContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location access allows you to find recommended local activities and groups of people that are relevant to you.")
                .foregroundColor(AppColors.primaryText.opacity(0.7))
                .font(.body)

            Button(action: {
                Task { await locationPermissionTapped() }
            }) {
                Text(locationViewModel.isLoading ? "Finding location..." : "Allow location access")
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
            _ = saveProfileForOnboarding()
            Task { @MainActor in
                _ = await syncProfileToSupabaseIfPossible()
            }
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

    // MARK: - Welcome screen

    private var welcomeContent: some View {
        VStack(spacing: 12) {
            Text("Welcome to Gloob  !")
                .font(.title).fontWeight(.bold)
                .foregroundColor(AppColors.primaryText)

            Text("Recommendations and friends\nbased on your preference.")
                .font(.subheadline)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.6)) { currentStep = .nameInput }
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

    @discardableResult
    private func syncProfileToSupabaseIfPossible() async -> Bool {
        guard supabaseService.isConfigured else { return true }

        do {
            try await supabaseService.signInWithCurrentProfile()
            accountError = nil
            return true
        } catch {
            accountError = error.localizedDescription
            print("Supabase profile upsert failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Helpers

    private func onboardingTextField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType,
        textContentType: UITextContentType?,
        autocapitalization: TextInputAutocapitalization
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.primaryText)

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .padding()
                .background(AppColors.textFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.textFieldBorder, lineWidth: 1)
                )
        }
    }

    private func onboardingChoiceSection(
        title: String,
        options: [String],
        selection: Set<String>,
        onTap: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline).foregroundColor(AppColors.primaryText)
            FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button { onTap(option) } label: {
                        OnboardingChoiceChip(title: option, isSelected: selection.contains(option))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func locationPermissionTapped() async {
        _ = saveProfileForOnboarding()
        await locationViewModel.allowLocationTapped()
        if locationViewModel.navigateToConfirm {
            city = locationViewModel.city
            userLocation = locationViewModel.location
            withAnimation(.easeInOut(duration: 0.6)) { currentStep = .locationConfirmed }
        }
    }

    private var parsedAge: Int? {
        guard let age = Int(ageText.trimmingCharacters(in: .whitespacesAndNewlines)),
              (13...100).contains(age) else { return nil }
        return age
    }

    private var selectedCountryOption: CurrentUserProfileStore.CountryOption? {
        CurrentUserProfileStore.countryOption(named: countryOrigin)
    }

    private var countryPickerLabel: some View {
        HStack(spacing: 10) {
            Text(selectedCountryOption?.flag ?? "🌍")
                .font(.title3)

            Text(selectedCountryOption?.name ?? "Select country")
                .font(.body)
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding()
        .background(AppColors.textFieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.textFieldBorder, lineWidth: 1)
        )
    }

    private var isProfileDetailsReady: Bool {
        parsedAge != nil
            && !countryOrigin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedInterests.isEmpty
            && !selectedLanguages.isEmpty
    }

    private var normalizedUsername: String? {
        SupabaseService.normalizedUsername(username)
    }

    private var normalizedEmail: String? {
        SupabaseService.normalizedEmail(email)
    }

    private var isAccountReady: Bool {
        !realName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && normalizedUsername != nil
            && normalizedEmail != nil
    }

    private func continueFromAccountStep() {
        guard let normalizedUsername, let normalizedEmail else {
            accountError = "Use a valid email and a username with at least 3 letters or numbers."
            return
        }

        CurrentUserProfileStore.saveAccountIdentity(
            username: normalizedUsername,
            realName: realName,
            email: normalizedEmail
        )
        accountError = nil
        withAnimation(.easeInOut(duration: 0.6)) {
            currentStep = .profileDetails
        }
    }

    private func continueFromProfileStep() {
        guard saveProfileForOnboarding() else { return }

        isSavingProfile = true
        Task { @MainActor in
            let didSync = await syncProfileToSupabaseIfPossible()
            isSavingProfile = false

            guard didSync || !supabaseService.isConfigured else { return }

            withAnimation(.easeInOut(duration: 0.6)) {
                currentStep = .locationPermission
            }
        }
    }

    @discardableResult
    private func saveProfileForOnboarding() -> Bool {
        guard let parsedAge else {
            CurrentUserProfileStore.ensureMemberSince()
            return false
        }
        guard let normalizedUsername, let normalizedEmail else {
            accountError = "Use a valid email and a username with at least 3 letters or numbers."
            return false
        }
        CurrentUserProfileStore.saveOnboardingProfile(
            username: normalizedUsername,
            realName: realName,
            email: normalizedEmail,
            age: parsedAge,
            country: countryOrigin,
            interests: orderedSelection(selectedInterests, options: CurrentUserProfileStore.availableInterests),
            languages: orderedSelection(selectedLanguages, options: CurrentUserProfileStore.availableLanguages)
        )
        return true
    }

    private func orderedSelection(_ selection: Set<String>, options: [String]) -> [String] {
        let ordered = options.filter { selection.contains($0) }
        let extras = selection.filter { !options.contains($0) }.sorted()
        return ordered + extras
    }

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.6)) {
            switch currentStep {
            case .welcome: break
            case .nameInput: currentStep = .welcome
            case .profileDetails: currentStep = .nameInput
            case .locationPermission: currentStep = .profileDetails
            case .locationConfirmed: currentStep = .locationPermission
            }
        }
    }

    // MARK: - Mascot + background + globe (unchanged)

    private var mascotLayer: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let isWelcomePosition = !mascotsAreOffscreen
            ZStack {
                Image("teal")
                    .resizable().scaledToFit()
                    .frame(width: min(width * 0.58, 276))
                    .rotationEffect(.degrees(isWelcomePosition ? (mascotIdle ? 2 : -2) : -8))
                    .position(x: isWelcomePosition ? width * 0.68 : width * 0.78,
                              y: isWelcomePosition ? 400 : -320)
                    .offset(x: isWelcomePosition ? (mascotIdle ? 6 : -4) : 0,
                            y: isWelcomePosition ? (mascotIdle ? -12 : 8) : 0)

                Image("dark green")
                    .resizable().scaledToFit()
                    .frame(width: min(width * 0.42, 184))
                    .rotationEffect(.degrees(isWelcomePosition ? (mascotIdle ? -4 : -10) : -16))
                    .position(x: isWelcomePosition ? width * 0.29 : width * 0.26,
                              y: isWelcomePosition ? 550 : -260)
                    .offset(x: isWelcomePosition ? (mascotIdle ? -5 : 4) : 0,
                            y: isWelcomePosition ? (mascotIdle ? 9 : -7) : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 1.15), value: mascotsAreOffscreen)
        }
    }

    private var backgroundView: some View {
        let backgroundY: CGFloat = currentStep == .welcome ? 0.38 : 0.62
        return ZStack {
            AppColors.background
            LinearGradient(
                colors: [Color.clear, AppColors.accent.opacity(0.08), AppColors.accent.opacity(0.18)],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [AppColors.accent.opacity(0.22), AppColors.accent.opacity(0.10), Color.clear],
                center: UnitPoint(x: 0.5, y: backgroundY),
                startRadius: 200, endRadius: 300
            )
            RadialGradient(
                colors: [Color.white.opacity(0.65), Color.white.opacity(0.25), Color.clear],
                center: .top, startRadius: 80, endRadius: 450
            )
            .offset(y: -180)
            RadialGradient(
                colors: [Color.black.opacity(0.08), Color.clear],
                center: .top, startRadius: 250, endRadius: 700
            )
            .offset(y: -200)
        }
    }

    private var globeOffset: CGFloat {
        switch currentStep {
        case .welcome: return -250
        case .nameInput, .profileDetails, .locationPermission: return 250
        case .locationConfirmed: return 200
        }
    }
}

// MARK: - Supporting views

private struct OnboardingChoiceChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
            }
            Text(title)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(isSelected ? .white : AppColors.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            isSelected ? AppColors.accent : Color(UIColor.secondarySystemBackground),
            in: Capsule()
        )
        .overlay(Capsule().stroke(isSelected ? AppColors.accent : AppColors.textFieldBorder, lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        UnifiedOnboardingView()
    }
}
