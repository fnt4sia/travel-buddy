import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @ObservedObject private var meetupStore = MeetupStore.shared

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                statsSection
                aboutSection
                languageSection
                interestSection
                if viewModel.hasSocialMedia { socialMediaSection }
            }
            .padding(.horizontal, ProfileMetrics.Layout.screenPadding)
            .padding(.top, 16)
            .padding(.bottom, ProfileMetrics.Layout.bottomSafeInset)
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Your travel identity")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()

                Button(action: viewModel.editTapped) {
                    Label("Edit", systemImage: "square.and.pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.brandPrimary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background(AppColors.accentSurface, in: Capsule())
                        .overlay(Capsule().stroke(AppColors.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            identityPanel
        }
    }

    private var identityPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                ProfileAvatar(imageName: viewModel.profile.profileImageName, size: 92)
                    .overlay(
                        RoundedRectangle(cornerRadius: ProfileMetrics.Avatar.cornerRadius, style: .continuous)
                            .stroke(.white.opacity(0.7), lineWidth: 2)
                    )

                Spacer()

                countryBadge
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(viewModel.profile.name)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    Text("\(viewModel.profile.age)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.brandPrimary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.white, in: Capsule())
                }

                Text(identitySubtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: AppColors.brandPrimary.opacity(0.20), radius: 18, x: 0, y: 10)
    }

    private var identitySubtitle: String {
        "From \(viewModel.profile.country). Speaks \(languageSummary)."
    }

    private var languageSummary: String {
        let languages = Array(viewModel.profile.languages.prefix(2))
        guard !languages.isEmpty else { return "languages to be added" }

        let suffix = viewModel.profile.languages.count > 2
            ? " +\(viewModel.profile.languages.count - 2)"
            : ""
        return languages.joined(separator: ", ") + suffix
    }

    private var countryBadge: some View {
        VStack(spacing: 5) {
            Text(viewModel.profile.languageFlag)
                .font(.system(size: 24))
            Text(viewModel.profile.countryCode)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.20), lineWidth: 1)
        )
    }

    private var statsSection: some View {
        HStack(spacing: 10) {
            ProfileStatTile(
                systemImage: "calendar.badge.plus",
                value: "\(meetupStore.createdGroupsCount)",
                title: meetupStore.createdGroupsCount == 1 ? "Event created" : "Events created"
            )

            ProfileStatTile(
                systemImage: "clock",
                value: CurrentUserProfileStore.memberSinceText,
                title: "Member since"
            )

            ProfileStatTile(
                systemImage: "globe.asia.australia.fill",
                value: viewModel.profile.countryCode,
                title: "Origin"
            )
        }
    }

    private var aboutSection: some View {
        profileCard(icon: "person.fill", title: "About") {
            Text(viewModel.profile.aboutMe)
                .font(.system(size: ProfileMetrics.Font.body, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var languageSection: some View {
        profileCard(icon: "translate", title: "Languages spoken") {
            FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(viewModel.profile.languages, id: \.self) { language in
                    LanguageChip(language: language)
                }
            }
        }
    }

    private var interestSection: some View {
        profileCard(icon: "heart.circle.fill", title: "Interests") {
            FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(viewModel.profile.interests, id: \.self) { interest in
                    InterestChip(interest: interest)
                }
            }
        }
    }

    private var socialMediaSection: some View {
        profileCard(icon: "network", title: "Social media") {
            VStack(alignment: .leading, spacing: 8) {
                if let instagram = viewModel.instagramHandle {
                    SocialMediaRow(platform: .instagram, handle: instagram)
                }
                if let twitter = viewModel.twitterHandle {
                    SocialMediaRow(platform: .twitter, handle: twitter)
                }
            }
        }
    }

    private func profileCard<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.brandPrimary)
                    .frame(width: 30, height: 30)
                    .background(AppColors.accentSurface, in: Circle())

                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)

                Spacer()
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }
}

private struct ProfileStatTile: View {
    let systemImage: String
    let value: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.brandPrimary)
                .frame(width: 30, height: 30)
                .background(AppColors.accentSurface, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .padding(12)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    ProfileView()
}
