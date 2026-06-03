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
        let instagramHandle: String
        let twitterHandle: String
}

// data dummy before using SwiftData
extension UserProfile {
    static let currentUserMock = UserProfile(
        name: "Mark",
        age: 25,
        interests: ["Photography", "Museums", "Music"],
        languages: ["Malaysia", "Indonesia"],
        country: "Malaysia",
        profileImageName: "mark_profile",
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
    )
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
