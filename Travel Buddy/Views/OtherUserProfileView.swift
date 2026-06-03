//
//  OtherUserProfileView.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 03/06/26.
//

import SwiftUI

struct OtherUserProfileView: View {
    @StateObject private var viewModel: OtherUserProfileViewModel

    @ScaledMetric private var avatarSize: CGFloat = 96

    private let coverHeight: CGFloat = 220
    private let coverCornerRadius: CGFloat = 26

    init(viewModel: OtherUserProfileViewModel = OtherUserProfileViewModel(profile: .otherUserMock)) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: ProfileMetrics.Layout.sectionSpacing) {
                header

                aboutSection
                languageSection
                interestSection
                if viewModel.hasSocials { socialsSection }
                if viewModel.hasGallery { gallerySection }
            }
            .padding(.bottom, ProfileMetrics.Layout.bottomSafeInset)
        }
        .background { backgroundGradient.ignoresSafeArea() }
        .ignoresSafeArea(edges: .top)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.accent.opacity(0.16), AppColors.brandTeal.opacity(0.34)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            coverImage
                .frame(height: coverHeight)
                .frame(maxWidth: .infinity)
                .clipShape(
                    UnevenRoundedRectangle(
                        bottomLeadingRadius: coverCornerRadius,
                        bottomTrailingRadius: coverCornerRadius
                    )
                )

            backButton
                .padding(.horizontal, ProfileMetrics.Layout.screenPadding)
                .padding(.top, 60)
                .frame(maxHeight: .infinity, alignment: .top)

            identityRow
                .padding(.horizontal, ProfileMetrics.Layout.screenPadding)
                .offset(y: avatarSize * 0.5)
        }
        .padding(.bottom, avatarSize * 0.5)
    }

    @ViewBuilder
    private var coverImage: some View {
        if UIImage(named: viewModel.profile.coverImageName) != nil {
            Image(viewModel.profile.coverImageName)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [AppColors.accent.opacity(0.6), AppColors.brandTeal],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var backButton: some View {
        Button(action: viewModel.backTapped) {
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.black.opacity(0.72))
                .frame(width: 56, height: 56)
                .background(.white.opacity(0.8), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }

    private var identityRow: some View {
        HStack(alignment: .bottom, spacing: 14) {
            ProfileAvatar(imageName: viewModel.profile.profileImageName,
                          size: avatarSize,
                          shape: .circle)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(viewModel.profile.name)
                        .font(.title.bold())
                        .foregroundStyle(AppColors.primaryText)

                    Text(viewModel.ageText)
                        .font(.title3)
                        .foregroundStyle(AppColors.secondaryText)
                }

                HStack(spacing: 5) {
                    Text(viewModel.profile.languageFlag)
                    Text(viewModel.locationText)
                        .foregroundStyle(AppColors.secondaryText)
                }
                .font(.subheadline)
            }
            .padding(.top, 16)

            Spacer(minLength: 0)
        }
    }

    private var aboutSection: some View {
        section(icon: "person.fill", title: "About me") {
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.profile.aboutMe)
                    .font(.body)
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(viewModel.isAboutExpanded ? nil : 2)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { viewModel.toggleAbout() }
                } label: {
                    Text(viewModel.isAboutExpanded ? "Read less" : "Read more")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.brandTeal, in: Capsule())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var languageSection: some View {
        section(icon: "translate", title: "Language") {
            FlowLayout {
                ForEach(viewModel.profile.languages, id: \.self) { language in
                    LanguageChip(language: language)
                }
            }
        }
    }

    private var interestSection: some View {
        section(icon: "heart.fill", title: "Interest") {
            FlowLayout {
                ForEach(viewModel.profile.interests, id: \.self) { interest in
                    InterestChip(interest: interest)
                }
            }
        }
    }

    private var socialsSection: some View {
        section(icon: "globe", title: "Socials") {
            FlowLayout {
                if let instagram = viewModel.instagramHandle {
                    SocialTag(platform: .instagram, handle: instagram)
                }
                if let twitter = viewModel.twitterHandle {
                    SocialTag(platform: .twitter, handle: twitter)
                }
            }
        }
    }

    // Gallery is full-bleed, so it uses the header but not the card.
    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: ProfileMetrics.Layout.sectionTitleSpacing) {
            SectionHeader(icon: "photo.on.rectangle", title: "Gallery")
                .padding(.horizontal, ProfileMetrics.Layout.screenPadding)

            GalleryStrip(imageNames: viewModel.galleryImageNames)
        }
    }

    // MARK: - Section helper (header + card)

    private func section<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: ProfileMetrics.Layout.sectionTitleSpacing) {
            SectionHeader(icon: icon, title: title)
            SectionCard { content() }
        }
        .padding(.horizontal, ProfileMetrics.Layout.screenPadding)
    }
}

#Preview {
    OtherUserProfileView()
}
