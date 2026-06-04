import Foundation

struct UserProfile: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
    let interests: [String]
    let languages: [String]
    let country: String
    let profileImageName: String
    let languageFlag: String
    let isFavorite: Bool
    let bio: String
    let aboutMe: String
    let countryCode: String
    let instagramHandle: String?
    let twitterHandle: String?
}

extension UserProfile {
    static var currentUserMock: UserProfile {
        CurrentUserProfileStore.currentProfile()
    }
}

enum CurrentUserProfileStore {
    static let availableInterests = [
        "Travel",
        "Food",
        "Nature",
        "Photography",
        "Hiking",
        "Museums",
        "Music",
        "Art",
        "Shopping",
        "Fitness",
        "Adventure"
    ]

    static let availableLanguages = [
        "English",
        "Indonesian",
        "Malay",
        "Mandarin",
        "Spanish",
        "French",
        "Japanese",
        "Korean"
    ]

    static let defaultInterests = ["Food", "Nature", "Travel"]
    static let defaultLanguages = ["English"]

    private enum Keys {
        static let name = "userName"
        static let age = "profileAge"
        static let country = "profileCountryOrigin"
        static let interests = "profileInterests"
        static let languages = "profileLanguages"
        static let memberSince = "profileMemberSince"
    }

    static func currentProfile() -> UserProfile {
        let defaults = UserDefaults.standard
        let name = clean(defaults.string(forKey: Keys.name)) ?? "You"
        let age = defaults.integer(forKey: Keys.age)
        let country = clean(defaults.string(forKey: Keys.country)) ?? "Indonesia"
        let interests = decodedArray(
            defaults.string(forKey: Keys.interests),
            fallback: defaultInterests
        )
        let languages = decodedArray(
            defaults.string(forKey: Keys.languages),
            fallback: defaultLanguages
        )

        return UserProfile(
            name: name,
            age: age > 0 ? age : 24,
            interests: interests,
            languages: languages,
            country: country,
            profileImageName: "person.crop.square",
            languageFlag: CountryMetadata.flag(for: country),
            isFavorite: false,
            bio: "\(country) origin • \(languages.joined(separator: ", "))",
            aboutMe: aboutText(interests: interests, languages: languages),
            countryCode: CountryMetadata.code(for: country),
            instagramHandle: nil,
            twitterHandle: nil
        )
    }

    static func saveOnboardingProfile(
        name: String,
        age: Int,
        country: String,
        interests: [String],
        languages: [String]
    ) {
        let defaults = UserDefaults.standard
        defaults.set(clean(name) ?? "You", forKey: Keys.name)
        defaults.set(age, forKey: Keys.age)
        defaults.set(clean(country) ?? "Indonesia", forKey: Keys.country)
        defaults.set(encodedArray(cleanedList(interests)), forKey: Keys.interests)
        defaults.set(encodedArray(cleanedList(languages)), forKey: Keys.languages)
        ensureMemberSince()
    }

    static func ensureMemberSince() {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: Keys.memberSince) == nil else { return }
        defaults.set(ISO8601DateFormatter().string(from: Date()), forKey: Keys.memberSince)
    }

    static var memberSinceDate: Date {
        let defaults = UserDefaults.standard
        if let rawValue = defaults.string(forKey: Keys.memberSince),
           let date = ISO8601DateFormatter().date(from: rawValue) {
            return date
        }

        let now = Date()
        defaults.set(ISO8601DateFormatter().string(from: now), forKey: Keys.memberSince)
        return now
    }

    static var memberSinceText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: memberSinceDate)
    }

    private static func aboutText(interests: [String], languages: [String]) -> String {
        let interestText = interests.prefix(3).joined(separator: ", ")
        let languageText = languages.joined(separator: ", ")
        return "I am here to find meetups that match \(interestText.lowercased()) and connect with travelers who speak \(languageText)."
    }

    private static func clean(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func cleanedList(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values.compactMap { value in
            guard let cleaned = clean(value), !seen.contains(cleaned) else { return nil }
            seen.insert(cleaned)
            return cleaned
        }
    }

    private static func encodedArray(_ values: [String]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let encoded = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return encoded
    }

    private static func decodedArray(_ rawValue: String?, fallback: [String]) -> [String] {
        guard let rawValue,
              let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return fallback
        }

        let cleaned = cleanedList(decoded)
        return cleaned.isEmpty ? fallback : cleaned
    }
}

private enum CountryMetadata {
    static func flag(for country: String) -> String {
        switch country.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "indonesia": return "🇮🇩"
        case "malaysia": return "🇲🇾"
        case "united states", "usa", "us", "america": return "🇺🇸"
        case "singapore": return "🇸🇬"
        case "australia": return "🇦🇺"
        case "japan": return "🇯🇵"
        case "south korea", "korea": return "🇰🇷"
        case "china": return "🇨🇳"
        case "france": return "🇫🇷"
        case "spain": return "🇪🇸"
        default: return "🌍"
        }
    }

    static func code(for country: String) -> String {
        switch country.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "indonesia": return "IDN"
        case "malaysia": return "MYS"
        case "united states", "usa", "us", "america": return "USA"
        case "singapore": return "SGP"
        case "australia": return "AUS"
        case "japan": return "JPN"
        case "south korea", "korea": return "KOR"
        case "china": return "CHN"
        case "france": return "FRA"
        case "spain": return "ESP"
        default:
            return String(country.prefix(3)).uppercased()
        }
    }
}

// Mock profiles for group members
extension UserProfile {
    static let mockProfiles: [String: UserProfile] = [
        "Agustinus Juan": UserProfile(
            name: "Agustinus Juan",
            age: 22,
            interests: ["Photography", "Museums", "Music"],
            languages: ["Indonesian", "English"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            languageFlag: "🇮🇩",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        ),
        "Rani": UserProfile(
            name: "Rani",
            age: 24,
            interests: ["Travel", "Food", "Art"],
            languages: ["Indonesian", "Chinese"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            languageFlag: "🇮🇩",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        ),
        "Jody": UserProfile(
            name: "Jody",
            age: 26,
            interests: ["Hiking", "Photography", "Cooking"],
            languages: ["English", "Indonesian"],
            country: "Malaysia",
            profileImageName: "person.crop.square",
            languageFlag: "🇲🇾",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        ),
        "Balqis": UserProfile(
            name: "Balqis",
            age: 23,
            interests: ["Fashion", "Photography", "Museums"],
            languages: ["Indonesian", "English", "Arabic"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            languageFlag: "🇮🇩",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        ),
        "Dodo": UserProfile(
            name: "Dodo",
            age: 25,
            interests: ["Adventure", "Sports", "Music"],
            languages: ["Indonesian", "English"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            languageFlag: "🇮🇩",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        ),
        "Eka": UserProfile(
            name: "Eka",
            age: 27,
            interests: ["Yoga", "Nature", "Meditation"],
            languages: ["Indonesian"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            languageFlag: "🇮🇩",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        ),
        "Fira": UserProfile(
            name: "Fira",
            age: 21,
            interests: ["Shopping", "Dining", "Photography"],
            languages: ["Indonesian", "English"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            languageFlag: "🇮🇩",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        ),
        "John": UserProfile(
            name: "John",
            age: 25,
            interests: ["Photography", "Museums", "Music"],
            languages: ["English", "Indonesian"],
            country: "Malaysia",
            profileImageName: "person.crop.square",
            languageFlag: "🇲🇾",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        ),
        "Maria": UserProfile(
            name: "Maria",
            age: 23,
            interests: ["Travel", "Photography", "Cooking"],
            languages: ["English", "Spanish", "Indonesian"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            languageFlag: "🇮🇩",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        ),
        "Budi": UserProfile(
            name: "Budi",
            age: 28,
            interests: ["Hiking", "Nature", "Photography"],
            languages: ["Indonesian", "English"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            languageFlag: "🇮🇩",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        ),
        "Siti": UserProfile(
            name: "Siti",
            age: 24,
            interests: ["Art", "Music", "Dance"],
            languages: ["Indonesian", "English"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            languageFlag: "🇮🇩",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        ),
        "Ahmad": UserProfile(
            name: "Ahmad",
            age: 26,
            interests: ["Sports", "Fitness", "Travel"],
            languages: ["Indonesian", "English", "Arabic"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            languageFlag: "🇮🇩",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        ),
    ]
    
    static func profile(for name: String) -> UserProfile {
        let currentProfile = CurrentUserProfileStore.currentProfile()
        if name == "You" || name == currentProfile.name {
            return currentProfile
        }

        return mockProfiles[name] ?? UserProfile(
            name: name,
            age: 24,
            interests: ["Travel", "Photography"],
            languages: ["Indonesian", "English"],
            country: "Indonesia",
            profileImageName: "person.crop.square",
            languageFlag: "🇮🇩",
            isFavorite: false,
            bio: "Chasing sunsets and new stories 🌍",
            aboutMe: """
            I love exploring new places, trying local food, and meeting new people \
            along the way. Traveling makes me feel alive and gives me new perspectives \
            about the world. Usually the one saying “let’s just go” when there’s an \
            adventure involved. I enjoy nature, city walks, hidden cafes, and \
            spontaneous plans.
            """,
            countryCode: "MYS",
            instagramHandle: "@markjohn22",
            twitterHandle: "@jmark22"

        )
    }
}
