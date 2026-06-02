import SwiftUI

struct ProfileDetailView: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                profileHeader

                infoCard
                    .padding(.top, 44)

                Spacer(minLength: 56)
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
    }

    private var profileHeader: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(red: 0.89, green: 0.89, blue: 0.9))
                .frame(height: 270)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 18,
                        bottomTrailingRadius: 18,
                        topTrailingRadius: 0
                    )
                )

            HStack(alignment: .top) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.black.opacity(0.72))
                        .frame(width: 64, height: 64)
                        .background(.white.opacity(0.8), in: Circle())
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 74)
            .frame(maxHeight: .infinity, alignment: .top)

            HStack(alignment: .bottom, spacing: 14) {
                profileAvatar

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(profile.name)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)

                        Text("• \(profile.age)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black.opacity(0.34))
                    }

                    Text(profile.tagline)
                        .font(.system(size: 18))
                        .foregroundColor(.black.opacity(0.66))
                        .lineLimit(3)
                }
                .padding(.bottom, 12)

                Spacer()

                VStack(spacing: 3) {
                    Text(profile.countryPrefix)
                        .font(.system(size: 27))
                    Text(profile.country)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(.bottom, 17)
            }
            .padding(.horizontal, 16)
            .offset(y: 75)
        }
        .padding(.bottom, 75)
    }

    private var profileAvatar: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(red: 0.9, green: 0.91, blue: 0.92))
            .frame(width: 148, height: 148)
            .overlay {
                Image(systemName: profile.profileImageName)
                    .font(.system(size: 86))
                    .foregroundColor(.black.opacity(0.34))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
        }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 28) {
            sectionTitle("About me", icon: "person.fill")

            Text(aboutMeText)
                .font(.system(size: 18))
                .foregroundColor(.black.opacity(0.66))
                .lineSpacing(1.5)

            sectionTitle("Language", icon: "bubble.left.and.bubble.right.fill")
            tagGrid(profile.languages)

            sectionTitle("Interest", icon: "heart.fill")
            tagGrid(profile.interests)

            sectionTitle("Social Media", icon: "globe")
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("📷")
                    Text("Instagram : @\(instagramHandle)")
                }
                HStack(spacing: 8) {
                    Text("𝕏")
                    Text("Twitter : @\(twitterHandle)")
                }
            }
            .font(.system(size: 17))
            .foregroundColor(.black)
        }
        .padding(.horizontal, 24)
    }

    private var aboutMeText: String {
        "I love exploring new places, trying local food, and meeting new people along the way. Traveling makes me feel alive and gives me new perspectives about the world. Usually I’m the one saying \"let’s just go\" when there’s an adventure involved. I enjoy nature, city walks, hidden cafes, and spontaneous plans."
    }

    private var instagramHandle: String {
        profile.name.lowercased().replacingOccurrences(of: " ", with: "") + "22"
    }

    private var twitterHandle: String {
        let lowered = profile.name.lowercased().replacingOccurrences(of: " ", with: "")
        return lowered == "john" ? "jmark22" : String(lowered.prefix(1)) + "mark22"
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.black)
            Text(title)
                .font(.system(size: 21, weight: .medium))
                .foregroundColor(.black)
        }
    }

    private func tagGrid(_ tags: [String]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(AppColors.accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    ProfileDetailView(profile: UserProfile.profile(for: "John"))
}

private extension UserProfile {
    var tagline: String {
        "Chasing sunsets and new stories 🌍"
    }

    var countryPrefix: String {
        countryFlag
    }
}
