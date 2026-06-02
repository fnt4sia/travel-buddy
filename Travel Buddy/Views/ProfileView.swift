import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: ProfileMetrics.Layout.sectionSpacing) {
                header
                aboutSection
                languageSection
                interestSection
                if viewModel.hasSocialMedia { socialMediaSection }
            }
            .padding(.bottom, ProfileMetrics.Layout.bottomSafeInset)
        }
        .background(AppColors.background)
        .ignoresSafeArea(edges: .top)
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            AppColors.coverBackground
                .frame(height: ProfileMetrics.Header.height)
                .clipShape(
                    UnevenRoundedRectangle(
                        bottomLeadingRadius: ProfileMetrics.Header.cornerRadius,
                        bottomTrailingRadius: ProfileMetrics.Header.cornerRadius
                    )
                )

            headerControls
                .padding(.horizontal, ProfileMetrics.Layout.screenPadding)
                .padding(.top, 74)
                .frame(maxHeight: .infinity, alignment: .top)


            identityRow
                .padding(.horizontal, 16)
                .offset(y: ProfileMetrics.Header.infoOffset)
        }
        .padding(.bottom, ProfileMetrics.Header.infoOffset)
    }

    private var headerControls: some View {
        HStack {
            Button(action: viewModel.backTapped) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.72))
                    .frame(width: ProfileMetrics.Header.backButtonSize,
                           height: ProfileMetrics.Header.backButtonSize)
                    .background(.white.opacity(0.7), in: Circle())
                    .overlay { Circle().stroke(.white, lineWidth: 1) }
            }

            Spacer()

            Button("Edit", action: viewModel.editTapped)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppColors.brandTeal, in: Capsule())
                .padding(.top, 6)
        }
        .buttonStyle(.plain)
    }

    private var identityRow: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ProfileAvatar(imageName: viewModel.profile.profileImageName)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(viewModel.profile.name)
                        .font(.system(size: ProfileMetrics.Font.name, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)

                    Text(viewModel.ageText)
                        .font(.system(size: ProfileMetrics.Font.age, weight: .semibold))
                        .foregroundStyle(AppColors.secondaryText)
                }

                Text(viewModel.profile.bio)
                    .font(.system(size: ProfileMetrics.Font.bio))
                    .foregroundStyle(AppColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 24)

            Spacer(minLength: 8)

            countryBadge
                .padding(.bottom, 16)
        }
    }

    private var countryBadge: some View {
        VStack(spacing: 3) {
            Text(viewModel.profile.languageFlag)
                .font(.system(size: ProfileMetrics.Font.flagEmoji))
            Text(viewModel.profile.countryCode)
                .font(.system(size: ProfileMetrics.Font.countryCode, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
        }
    }

    private var aboutSection: some View {
        ProfileSection(icon: "person.fill", title: "About me") {
            Text(viewModel.profile.aboutMe)
                .font(.system(size: ProfileMetrics.Font.body))
                .foregroundStyle(AppColors.secondaryText)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, ProfileMetrics.Layout.screenPadding)
    }

    private var languageSection: some View {
        ProfileSection(icon: "translate", title: "Language") {
            FlowLayout {
                ForEach(viewModel.profile.languages, id: \.self) { language in
                    LanguageChip(language: language)
                }
            }
        }
        .padding(.horizontal, ProfileMetrics.Layout.screenPadding)
    }

    private var interestSection: some View {
        ProfileSection(icon: "heart.circle.fill", title: "Interest") {
            FlowLayout {
                ForEach(viewModel.profile.interests, id: \.self) { interest in
                    InterestChip(interest: interest)
                }
            }
        }
        .padding(.horizontal, ProfileMetrics.Layout.screenPadding)
    }

    private var socialMediaSection: some View {
        ProfileSection(icon: "network", title: "Social Media") {
            VStack(alignment: .leading, spacing: 8) {
                if let instagram = viewModel.instagramHandle {
                    SocialMediaRow(platform: .instagram, handle: instagram)
                }
                if let twitter = viewModel.twitterHandle {
                    SocialMediaRow(platform: .twitter, handle: twitter)
                }
            }
        }
        .padding(.horizontal, ProfileMetrics.Layout.screenPadding)
    }
}

#Preview {
    ProfileView()
}
