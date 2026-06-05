import Combine
import Foundation
import Supabase

enum SupabaseIdentityError: LocalizedError {
    case missingConfiguration
    case missingEmail
    case missingUsername
    case usernameTaken

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Supabase URL or publishable key is not configured."
        case .missingEmail:
            return "Enter an email before continuing."
        case .missingUsername:
            return "Enter a username before continuing."
        case .usernameTaken:
            return "That username is already taken."
        }
    }
}

@MainActor
final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    @Published private(set) var currentUserID: UUID?
    @Published private(set) var lastErrorMessage: String?

    let client: SupabaseClient?

    var isConfigured: Bool {
        client != nil
    }

    private init() {
        guard
            let url = Self.configuredURL,
            let key = Self.configuredPublishableKey
        else {
            client = nil
            currentUserID = Self.savedProfileID
            return
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        currentUserID = Self.savedProfileID
    }

    @discardableResult
    func signInWithCurrentProfile() async throws -> UUID? {
        let profile = CurrentUserProfileStore.currentProfile()
        return try await signInWithEmail(
            email: profile.email,
            username: profile.name,
            realName: profile.realName,
            age: profile.age,
            country: profile.country,
            interests: profile.interests,
            languages: profile.languages,
            aboutMe: profile.aboutMe,
            instagramHandle: profile.instagramHandle,
            twitterHandle: profile.twitterHandle
        )
    }

    @discardableResult
    func signInWithEmail(
        email: String?,
        username: String?,
        realName: String,
        age: Int?,
        country: String,
        interests: [String],
        languages: [String],
        aboutMe: String?,
        instagramHandle: String?,
        twitterHandle: String?
    ) async throws -> UUID? {
        guard let client else {
            lastErrorMessage = SupabaseIdentityError.missingConfiguration.localizedDescription
            return nil
        }

        guard let email = Self.normalizedEmail(email) else {
            lastErrorMessage = SupabaseIdentityError.missingEmail.localizedDescription
            throw SupabaseIdentityError.missingEmail
        }

        guard let username = Self.normalizedUsername(username) else {
            lastErrorMessage = SupabaseIdentityError.missingUsername.localizedDescription
            throw SupabaseIdentityError.missingUsername
        }

        let existingByEmail = try await profileRow(email: email, client: client)
        if let existingByUsername = try await profileRow(username: username, client: client),
           existingByUsername.id != existingByEmail?.id {
            lastErrorMessage = SupabaseIdentityError.usernameTaken.localizedDescription
            throw SupabaseIdentityError.usernameTaken
        }

        let userID = existingByEmail?.id ?? UUID()
        let payload = SupabaseProfilePayload(
            id: userID,
            username: username,
            email: email,
            realName: realName,
            displayName: username,
            avatarURL: nil,
            profileImageURL: nil,
            country: country,
            age: age,
            interests: interests,
            languages: languages,
            aboutMe: aboutMe,
            instagramHandle: instagramHandle,
            twitterHandle: twitterHandle,
            galleryURLs: []
        )

        try await client
            .from("profiles")
            .upsert(payload, onConflict: "id")
            .execute()

        Self.savedProfileID = userID
        currentUserID = userID
        lastErrorMessage = nil
        return userID
    }

    @discardableResult
    func ensureCurrentUser() async throws -> UUID? {
        if let currentUserID {
            try await upsertLocalProfile(userID: currentUserID)
            return currentUserID
        }

        if let savedID = Self.savedProfileID {
            currentUserID = savedID
            try await upsertLocalProfile(userID: savedID)
            return savedID
        }

        return try await signInWithCurrentProfile()
    }

    func upsertCurrentProfile() async throws {
        guard client != nil else { return }
        guard let userID = currentUserID ?? Self.savedProfileID else {
            _ = try await signInWithCurrentProfile()
            return
        }

        try await upsertLocalProfile(userID: userID)
    }

    private func upsertLocalProfile(userID: UUID) async throws {
        guard let client else { return }

        let profile = CurrentUserProfileStore.currentProfile()
        let username = Self.normalizedUsername(profile.name) ?? "traveler"
        let email = Self.normalizedEmail(profile.email)
            ?? "\(username)-\(userID.uuidString.prefix(8))@gloob.dev"

        let payload = SupabaseProfilePayload(
            id: userID,
            username: username,
            email: email,
            realName: profile.realName,
            displayName: username,
            avatarURL: nil,
            profileImageURL: nil,
            country: profile.country,
            age: profile.age,
            interests: profile.interests,
            languages: profile.languages,
            aboutMe: profile.aboutMe,
            instagramHandle: profile.instagramHandle,
            twitterHandle: profile.twitterHandle,
            galleryURLs: []
        )

        try await client
            .from("profiles")
            .upsert(payload, onConflict: "id")
            .execute()

        Self.savedProfileID = userID
        currentUserID = userID
        lastErrorMessage = nil
    }

    func signOut() {
        Self.savedProfileID = nil
        currentUserID = nil
        lastErrorMessage = nil
    }

    private func profileRow(
        email: String,
        client: SupabaseClient
    ) async throws -> SupabaseIdentityRow? {
        let rows: [SupabaseIdentityRow] = try await client
            .from("profiles")
            .select("id,email,username")
            .eq("email", value: email)
            .execute()
            .value
        return rows.first
    }

    private func profileRow(
        username: String,
        client: SupabaseClient
    ) async throws -> SupabaseIdentityRow? {
        let rows: [SupabaseIdentityRow] = try await client
            .from("profiles")
            .select("id,email,username")
            .eq("username", value: username)
            .execute()
            .value
        return rows.first
    }

    static func normalizedEmail(_ value: String?) -> String? {
        let trimmed = value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        guard trimmed.contains("@"), trimmed.contains(".") else { return nil }
        return trimmed
    }

    static func normalizedUsername(_ value: String?) -> String? {
        var text = value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        while text.hasPrefix("@") {
            text.removeFirst()
        }

        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._")
        let scalars = text.unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(scalar) : "_"
        }
        let username = String(scalars)
            .replacingOccurrences(of: "_+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "._"))
        return username.count >= 3 ? username : nil
    }

    private static var savedProfileID: UUID? {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: Keys.profileID) else {
                return nil
            }
            return UUID(uuidString: rawValue)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.uuidString, forKey: Keys.profileID)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.profileID)
            }
        }
    }

    private static var configuredURL: URL? {
        guard let rawValue = infoValue(for: "SupabaseURL"),
              !rawValue.contains("YOUR_PROJECT_REF"),
              let url = URL(string: rawValue) else {
            return nil
        }
        return url
    }

    private static var configuredPublishableKey: String? {
        guard let rawValue = infoValue(for: "SupabasePublishableKey"),
              !rawValue.contains("YOUR_SUPABASE"),
              !rawValue.isEmpty else {
            return nil
        }
        return rawValue
    }

    private static func infoValue(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private enum Keys {
        static let profileID = "supabaseProfileID"
    }
}

private struct SupabaseIdentityRow: Decodable {
    let id: UUID
    let email: String?
    let username: String?
}

private struct SupabaseProfilePayload: Encodable {
    let id: UUID
    let username: String
    let email: String
    let realName: String
    let displayName: String
    let avatarURL: String?
    let profileImageURL: String?
    let country: String
    let age: Int?
    let interests: [String]
    let languages: [String]
    let aboutMe: String?
    let instagramHandle: String?
    let twitterHandle: String?
    let galleryURLs: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case realName = "real_name"
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case profileImageURL = "profile_image_url"
        case country
        case age
        case interests
        case languages
        case aboutMe = "about_me"
        case instagramHandle = "instagram_handle"
        case twitterHandle = "twitter_handle"
        case galleryURLs = "gallery_urls"
    }
}
