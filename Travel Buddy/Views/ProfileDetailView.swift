import SwiftUI

struct ProfileDetailView: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var isFavorite = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [AppColors.accent, AppColors.accent.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(profile.countryFlag)
                        .font(.system(size: 24))
                }
                .padding(20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile Image
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 140, height: 140)
                            
                            Image(systemName: profile.profileImageName)
                                .font(.system(size: 70))
                                .foregroundStyle(AppColors.accent.opacity(0.3))
                        }
                        
                        // Name and Age
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Text(profile.name)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                Text("· \(profile.age)")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        
                        // Favorite button
                        Button(action: { isFavorite.toggle() }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 24))
                                .foregroundStyle(isFavorite ? .red : .white)
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        
                        // Interests Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Interests")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            HStack(spacing: 10) {
                                ForEach(profile.interests, id: \.self) { interest in
                                    Label(interest, systemImage: getInterestIcon(for: interest))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(AppColors.accent.opacity(0.3))
                                        .foregroundStyle(.white)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        
                        // Languages and Countries Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Countries")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            HStack(spacing: 10) {
                                ForEach(profile.languages, id: \.self) { language in
                                    Label(profile.country, systemImage: "flag.fill")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(AppColors.accent.opacity(0.3))
                                        .foregroundStyle(.white)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        
                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                // Detail Button
                Button(action: { dismiss() }) {
                    Text("Detail")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(20)
            }
        }
    }
    
    private func getInterestIcon(for interest: String) -> String {
        switch interest {
        case "Photography": return "camera.fill"
        case "Museums": return "building.2.fill"
        case "Music": return "music.note"
        case "Travel": return "airplane"
        case "Food": return "fork.knife"
        case "Art": return "paintpalette.fill"
        case "Hiking": return "mountain.2.fill"
        case "Cooking": return "flame.fill"
        case "Fashion": return "t.shirt.fill"
        case "Adventure": return "compass.drawing"
        case "Sports": return "figure.basketball"
        case "Yoga": return "figure.yoga"
        case "Nature": return "leaf.fill"
        case "Meditation": return "moon.stars.fill"
        case "Shopping": return "bag.fill"
        case "Dining": return "fork.knife"
        case "Dance": return "music.note.house.fill"
        case "Fitness": return "dumbbell.fill"
        default: return "star.fill"
        }
    }
}

#Preview {
    ProfileDetailView(profile: UserProfile.profile(for: "John"))
}
