import CoreLocation
import Foundation
import Supabase

struct SupabaseMeetupFetchResult {
    let groups: [ActivityGroup]
    let profiles: [UUID: UserProfile]
}

struct SupabaseMessagesFetchResult {
    let messages: [ChatMessage]
    let profiles: [UUID: UserProfile]
}

struct SupabaseMeetupService {
    static let shared = SupabaseMeetupService()

    private static let roomSelectColumns = """
    id,place_id,place_name,title,description,address,meetup_date,starts_at,ends_at,timezone,max_capacity,created_by,created_at,\
    room_members(user_id,role,profile:profiles(id,username,email,real_name,display_name,country,age,interests,languages,about_me,instagram_handle,twitter_handle,gallery_urls,created_at))
    """

    private static let messageSelectColumns = """
    id,room_id,sender_id,body,created_at,\
    sender:profiles(id,username,email,real_name,display_name,country,age,interests,languages,about_me,instagram_handle,twitter_handle,gallery_urls,created_at)
    """

    private var client: SupabaseClient? {
        SupabaseService.shared.client
    }

    var isConfigured: Bool {
        client != nil
    }

    func fetchRooms(
        on date: Date?,
        placeID: String?
    ) async throws -> SupabaseMeetupFetchResult {
        guard let client else {
            return SupabaseMeetupFetchResult(groups: [], profiles: [:])
        }

        let query = client
            .from("meetup_rooms")
            .select(Self.roomSelectColumns)

        if let date {
            _ = query.eq("meetup_date", value: Self.dateString(from: date))
        }

        if let placeID {
            _ = query.eq("place_id", value: placeID)
        }

        let rows: [SupabaseRoomRow] = try await query
            .order("meetup_date")
            .order("starts_at")
            .execute()
            .value

        return Self.fetchResult(from: rows)
    }

    func fetchJoinedRooms(for userID: UUID) async throws -> SupabaseMeetupFetchResult {
        guard let client else {
            return SupabaseMeetupFetchResult(groups: [], profiles: [:])
        }

        let membershipRows: [SupabaseMembershipRoomRow] = try await client
            .from("room_members")
            .select("room_id")
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value

        let roomIDs = membershipRows.map(\.roomID.uuidString)
        guard !roomIDs.isEmpty else {
            return SupabaseMeetupFetchResult(groups: [], profiles: [:])
        }

        let filter = "id.in.(\(roomIDs.joined(separator: ",")))"
        let rows: [SupabaseRoomRow] = try await client
            .from("meetup_rooms")
            .select(Self.roomSelectColumns)
            .or(filter)
            .order("meetup_date")
            .order("starts_at")
            .execute()
            .value

        return Self.fetchResult(from: rows)
    }

    func fetchCreatedRoomIDs(for userID: UUID) async throws -> Set<UUID> {
        guard let client else { return [] }

        let rows: [SupabaseRoomIDRow] = try await client
            .from("meetup_rooms")
            .select("id")
            .eq("created_by", value: userID.uuidString)
            .execute()
            .value

        return Set(rows.map(\.id))
    }

    func createRoom(
        place: PlaceAnnotation?,
        name: String,
        description: String,
        address: String,
        date: Date,
        meetingTime: String,
        maxCapacity: Int
    ) async throws -> ActivityGroup? {
        guard let client else { return nil }
        guard let userID = try await SupabaseService.shared.ensureCurrentUser() else {
            return nil
        }

        if let place {
            try await upsertPlace(place)
        }

        let timeRange = Self.timeRange(from: meetingTime)
        let payload = SupabaseRoomPayload(
            placeID: place?.id,
            placeName: place?.name ?? address,
            title: name,
            description: description,
            address: address,
            meetupDate: Self.dateString(from: date),
            startsAt: timeRange.start,
            endsAt: timeRange.end,
            timezone: Self.timezone(for: place),
            maxCapacity: maxCapacity,
            createdBy: userID
        )

        let rows: [SupabaseRoomRow] = try await client
            .from("meetup_rooms")
            .insert(payload, returning: .representation)
            .select(Self.roomSelectColumns)
            .execute()
            .value

        return Self.fetchResult(from: rows).groups.first
    }

    func joinRoom(_ groupID: UUID) async throws {
        guard let client else { return }
        guard let userID = try await SupabaseService.shared.ensureCurrentUser() else {
            return
        }

        let payload = SupabaseRoomMemberPayload(
            roomID: groupID,
            userID: userID,
            role: "member"
        )

        try await client
            .from("room_members")
            .insert(payload)
            .execute()
    }

    func leaveRoom(_ groupID: UUID) async throws {
        guard let client else { return }
        guard let userID = try await SupabaseService.shared.ensureCurrentUser() else {
            return
        }

        try await client
            .from("room_members")
            .delete()
            .eq("room_id", value: groupID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .execute()
    }

    func fetchMessages(for groupID: UUID) async throws -> SupabaseMessagesFetchResult {
        guard let client else {
            return SupabaseMessagesFetchResult(messages: [], profiles: [:])
        }

        let rows: [SupabaseMessageRow] = try await client
            .from("room_messages")
            .select(Self.messageSelectColumns)
            .eq("room_id", value: groupID.uuidString)
            .order("created_at")
            .execute()
            .value

        var profiles: [UUID: UserProfile] = [:]
        let messages = rows.map { row in
            if let sender = row.sender {
                profiles[sender.id] = sender.userProfile
            }

            return ChatMessage(
                id: row.id,
                groupID: row.roomID,
                senderID: row.senderID,
                senderName: row.sender?.nickname ?? "traveler",
                body: row.body,
                sentAt: Self.dateTime(from: row.createdAt) ?? Date()
            )
        }

        return SupabaseMessagesFetchResult(messages: messages, profiles: profiles)
    }

    func sendMessage(groupID: UUID, body: String) async throws {
        guard let client else { return }
        guard let userID = try await SupabaseService.shared.ensureCurrentUser() else {
            return
        }

        let payload = SupabaseMessagePayload(
            roomID: groupID,
            senderID: userID,
            body: body
        )

        try await client
            .from("room_messages")
            .insert(payload)
            .execute()
    }

    func upsertPlace(_ place: PlaceAnnotation) async throws {
        guard let client else { return }

        let payload = SupabasePlacePayload(
            id: place.id,
            name: place.name,
            address: place.address,
            description: place.description,
            category: place.category.rawValue,
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude,
            rating: place.rating,
            userRatingCount: place.userRatingCount,
            photoURL: place.photoURL?.absoluteString,
            source: "development"
        )

        try await client
            .from("places")
            .upsert(payload, onConflict: "id")
            .execute()
    }

    private static func fetchResult(from rows: [SupabaseRoomRow]) -> SupabaseMeetupFetchResult {
        var profiles: [UUID: UserProfile] = [:]
        let groups = rows.map { row in
            let members = (row.members ?? [])
                .sorted { lhs, rhs in
                    if lhs.role == rhs.role {
                        return lhs.displayName < rhs.displayName
                    }
                    return lhs.role == "host"
                }
                .map { member in
                    if let profile = member.profile {
                        profiles[profile.id] = profile.userProfile
                    }

                    return GroupMember(
                        userID: member.userID,
                        name: member.displayName,
                        color: colorName(for: member.userID)
                    )
                }

            return ActivityGroup(
                id: row.id,
                placeID: row.placeID,
                name: row.title,
                description: row.description,
                address: row.address,
                date: date(from: row.meetupDate, startsAt: row.startsAt) ?? Date(),
                maxCapacity: row.maxCapacity,
                members: members,
                meetingTime: meetingTimeText(
                    startsAt: row.startsAt,
                    endsAt: row.endsAt,
                    timezone: row.timezone
                )
            )
        }

        return SupabaseMeetupFetchResult(groups: groups, profiles: profiles)
    }

    private static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func date(from dateString: String, startsAt: String?) -> Date? {
        let dateParts = dateString.split(separator: "-").compactMap { Int($0) }
        guard dateParts.count == 3 else { return nil }

        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.year = dateParts[0]
        components.month = dateParts[1]
        components.day = dateParts[2]

        if let startsAt {
            let timeParts = startsAt.split(separator: ":").compactMap { Int($0) }
            if timeParts.count >= 2 {
                components.hour = timeParts[0]
                components.minute = timeParts[1]
            }
        }

        return components.calendar?.date(from: components)
    }

    private static func dateTime(from value: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: value) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: value)
    }

    private static func timeRange(from meetingTime: String) -> (start: String?, end: String?) {
        let pattern = #"(\d{1,2}):(\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (nil, nil)
        }

        let range = NSRange(meetingTime.startIndex..., in: meetingTime)
        let matches = regex.matches(in: meetingTime, range: range)
        let values = matches.prefix(2).compactMap { match -> String? in
            guard match.numberOfRanges >= 3,
                  let hourRange = Range(match.range(at: 1), in: meetingTime),
                  let minuteRange = Range(match.range(at: 2), in: meetingTime),
                  let hour = Int(meetingTime[hourRange]) else {
                return nil
            }

            return String(format: "%02d:%@", hour, String(meetingTime[minuteRange]))
        }

        return (values.first, values.dropFirst().first)
    }

    private static func meetingTimeText(
        startsAt: String?,
        endsAt: String?,
        timezone: String
    ) -> String {
        let start = shortTime(startsAt) ?? "TBD"
        let end = shortTime(endsAt)
        let timezoneText = timezone == "America/Los_Angeles" ? "PT" : "GMT+8"

        if let end {
            return "\(start) - \(end) \(timezoneText)"
        }

        return "\(start) \(timezoneText)"
    }

    private static func shortTime(_ value: String?) -> String? {
        guard let value else { return nil }
        let parts = value.split(separator: ":")
        guard parts.count >= 2 else { return nil }
        return "\(parts[0]):\(parts[1])"
    }

    private static func timezone(for place: PlaceAnnotation?) -> String {
        guard let place else { return "Asia/Makassar" }
        return place.id.hasPrefix("cupertino") ? "America/Los_Angeles" : "Asia/Makassar"
    }

    private static func colorName(for userID: UUID) -> String {
        let colors = ["blue", "green", "purple", "orange", "red", "yellow", "cyan", "teal"]
        return colors[abs(userID.uuidString.hashValue) % colors.count]
    }
}

private struct SupabaseRoomRow: Decodable {
    let id: UUID
    let placeID: String?
    let placeName: String?
    let title: String
    let description: String
    let address: String
    let meetupDate: String
    let startsAt: String?
    let endsAt: String?
    let timezone: String
    let maxCapacity: Int
    let createdBy: UUID
    let createdAt: String?
    let members: [SupabaseRoomMemberRow]?

    enum CodingKeys: String, CodingKey {
        case id
        case placeID = "place_id"
        case placeName = "place_name"
        case title
        case description
        case address
        case meetupDate = "meetup_date"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case timezone
        case maxCapacity = "max_capacity"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case members = "room_members"
    }
}

private struct SupabaseRoomMemberRow: Decodable {
    let userID: UUID
    let role: String
    let profile: SupabaseProfileRow?

    var displayName: String {
        profile?.nickname ?? "traveler"
    }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case role
        case profile
    }
}

private struct SupabaseMembershipRoomRow: Decodable {
    let roomID: UUID

    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
    }
}

private struct SupabaseRoomIDRow: Decodable {
    let id: UUID
}

private struct SupabaseMessageRow: Decodable {
    let id: UUID
    let roomID: UUID
    let senderID: UUID
    let body: String
    let createdAt: String
    let sender: SupabaseProfileRow?

    enum CodingKeys: String, CodingKey {
        case id
        case roomID = "room_id"
        case senderID = "sender_id"
        case body
        case createdAt = "created_at"
        case sender
    }
}

private struct SupabaseProfileRow: Decodable {
    let id: UUID
    let username: String?
    let email: String?
    let realName: String?
    let displayName: String?
    let country: String?
    let age: Int?
    let interests: [String]?
    let languages: [String]?
    let aboutMe: String?
    let instagramHandle: String?
    let twitterHandle: String?
    let galleryURLs: [String]?
    let createdAt: String?

    var userProfile: UserProfile {
        let resolvedCountry = country ?? CurrentUserProfileStore.defaultCountry
        let resolvedUsername = nickname
        let resolvedLanguages = languages?.isEmpty == false
            ? languages ?? CurrentUserProfileStore.defaultLanguages
            : CurrentUserProfileStore.defaultLanguages
        let resolvedInterests = interests?.isEmpty == false
            ? interests ?? CurrentUserProfileStore.defaultInterests
            : CurrentUserProfileStore.defaultInterests

        return UserProfile(
            name: resolvedUsername,
            realName: realName ?? resolvedUsername,
            email: email,
            age: age ?? 24,
            interests: resolvedInterests,
            languages: resolvedLanguages,
            country: resolvedCountry,
            profileImageName: "person.crop.square",
            languageFlag: CountryMetadata.flag(for: resolvedCountry),
            isFavorite: false,
            bio: "\(resolvedCountry) origin • \(resolvedLanguages.joined(separator: ", "))",
            aboutMe: aboutMe ?? "Open to meeting travelers and making simple plans together.",
            countryCode: CountryMetadata.code(for: resolvedCountry),
            instagramHandle: instagramHandle,
            twitterHandle: twitterHandle
        )
    }

    var nickname: String {
        username ?? displayName ?? realName ?? "traveler"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case realName = "real_name"
        case displayName = "display_name"
        case country
        case age
        case interests
        case languages
        case aboutMe = "about_me"
        case instagramHandle = "instagram_handle"
        case twitterHandle = "twitter_handle"
        case galleryURLs = "gallery_urls"
        case createdAt = "created_at"
    }
}

private struct SupabaseRoomPayload: Encodable {
    let placeID: String?
    let placeName: String
    let title: String
    let description: String
    let address: String
    let meetupDate: String
    let startsAt: String?
    let endsAt: String?
    let timezone: String
    let maxCapacity: Int
    let createdBy: UUID

    enum CodingKeys: String, CodingKey {
        case placeID = "place_id"
        case placeName = "place_name"
        case title
        case description
        case address
        case meetupDate = "meetup_date"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case timezone
        case maxCapacity = "max_capacity"
        case createdBy = "created_by"
    }
}

private struct SupabaseRoomMemberPayload: Encodable {
    let roomID: UUID
    let userID: UUID
    let role: String

    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
        case userID = "user_id"
        case role
    }
}

private struct SupabaseMessagePayload: Encodable {
    let roomID: UUID
    let senderID: UUID
    let body: String

    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
        case senderID = "sender_id"
        case body
    }
}

private struct SupabasePlacePayload: Encodable {
    let id: String
    let name: String
    let address: String
    let description: String
    let category: String
    let latitude: Double
    let longitude: Double
    let rating: Double?
    let userRatingCount: Int?
    let photoURL: String?
    let source: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case description
        case category
        case latitude
        case longitude
        case rating
        case userRatingCount = "user_rating_count"
        case photoURL = "photo_url"
        case source
    }
}
