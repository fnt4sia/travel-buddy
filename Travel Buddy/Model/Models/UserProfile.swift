import Foundation

struct UserProfile: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
    let interests: [String]
    let languages: [String]
    let country: String
    let profileImageName: String
    let countryFlag: String
    let isFavorite: Bool
}

// Mock profiles for group members
extension UserProfile {
    static let mockProfiles: [String: UserProfile] = [
        "Agustina Juan": UserProfile(
            name: "Agustina Juan",
            age: 22,
            interests: ["Photography", "Museums", "Music"],
            languages: ["Indonesian", "English"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            countryFlag: "🇮🇩",
            isFavorite: false
        ),
        "Rani": UserProfile(
            name: "Rani",
            age: 24,
            interests: ["Travel", "Food", "Art"],
            languages: ["Indonesian", "Chinese"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            countryFlag: "🇮🇩",
            isFavorite: false
        ),
        "Jody": UserProfile(
            name: "Jody",
            age: 26,
            interests: ["Hiking", "Photography", "Cooking"],
            languages: ["English", "Indonesian"],
            country: "Malaysia",
            profileImageName: "person.crop.square",
            countryFlag: "🇲🇾",
            isFavorite: false
        ),
        "Balqis": UserProfile(
            name: "Balqis",
            age: 23,
            interests: ["Fashion", "Photography", "Museums"],
            languages: ["Indonesian", "English", "Arabic"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            countryFlag: "🇮🇩",
            isFavorite: false
        ),
        "Dodo": UserProfile(
            name: "Dodo",
            age: 25,
            interests: ["Adventure", "Sports", "Music"],
            languages: ["Indonesian", "English"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            countryFlag: "🇮🇩",
            isFavorite: false
        ),
        "Eka": UserProfile(
            name: "Eka",
            age: 27,
            interests: ["Yoga", "Nature", "Meditation"],
            languages: ["Indonesian"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            countryFlag: "🇮🇩",
            isFavorite: false
        ),
        "Fira": UserProfile(
            name: "Fira",
            age: 21,
            interests: ["Shopping", "Dining", "Photography"],
            languages: ["Indonesian", "English"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            countryFlag: "🇮🇩",
            isFavorite: false
        ),
        "John": UserProfile(
            name: "John",
            age: 25,
            interests: ["Photography", "Museums", "Music"],
            languages: ["English", "Indonesian"],
            country: "Malaysia",
            profileImageName: "person.crop.square",
            countryFlag: "🇲🇾",
            isFavorite: false
        ),
        "Maria": UserProfile(
            name: "Maria",
            age: 23,
            interests: ["Travel", "Photography", "Cooking"],
            languages: ["English", "Spanish", "Indonesian"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            countryFlag: "🇮🇩",
            isFavorite: false
        ),
        "Budi": UserProfile(
            name: "Budi",
            age: 28,
            interests: ["Hiking", "Nature", "Photography"],
            languages: ["Indonesian", "English"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            countryFlag: "🇮🇩",
            isFavorite: false
        ),
        "Siti": UserProfile(
            name: "Siti",
            age: 24,
            interests: ["Art", "Music", "Dance"],
            languages: ["Indonesian", "English"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            countryFlag: "🇮🇩",
            isFavorite: false
        ),
        "Ahmad": UserProfile(
            name: "Ahmad",
            age: 26,
            interests: ["Sports", "Fitness", "Travel"],
            languages: ["Indonesian", "English", "Arabic"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            countryFlag: "🇮🇩",
            isFavorite: false
        ),
    ]
    
    static func profile(for name: String) -> UserProfile {
        return mockProfiles[name] ?? UserProfile(
            name: name,
            age: 24,
            interests: ["Travel", "Photography"],
            languages: ["Indonesian", "English"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            countryFlag: "🇮🇩",
            isFavorite: false
        )
    }
}
