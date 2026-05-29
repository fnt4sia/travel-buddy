import SwiftUI

struct ProfileView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                profileHeader
                aboutSection
                    .padding(.top, 42)

                Spacer(minLength: 120)
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
    }

    private var profileHeader: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(red: 0.84, green: 0.84, blue: 0.84))
                .frame(height: 270)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 18,
                        bottomTrailingRadius: 18,
                        topTrailingRadius: 0
                    )
                )


            HStack(alignment: .bottom, spacing: 14) {
                defaultAvatar

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("Fitra")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)

                        Text("• 25")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black.opacity(0.34))
                    }

                    Text("I love 67")
                        .font(.system(size: 18))
                        .foregroundColor(.black.opacity(0.66))
                }
                .padding(.bottom, 12)

                Spacer()

                VStack(spacing: 3) {
                    Text("")
                        .font(.system(size: 27))
                    Text("ID")
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

    private var defaultAvatar: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(red: 0.9, green: 0.91, blue: 0.92))
            .frame(width: 148, height: 148)
            .overlay {
                Image(systemName: "person.crop.square.fill")
                    .font(.system(size: 86))
                    .foregroundColor(.black.opacity(0.34))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
    }

    private var aboutSection: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "person.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 8) {
                Text("About me")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundColor(.black)

                Text("I love exploring new places, trying local food, and meeting new people along the way. Traveling makes me feel alive and gives me new perspectives about the world. Usually the one saying “let’s just go” when there’s an adventure involved. I enjoy nature, city walks, hidden cafes, and spontaneous plans.")
                    .font(.system(size: 18))
                    .foregroundColor(.black.opacity(0.66))
                    .lineSpacing(1.5)
            }
        }
        .padding(.horizontal, 24)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
