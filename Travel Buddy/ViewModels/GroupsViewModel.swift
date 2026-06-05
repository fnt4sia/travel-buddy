import Combine
import Foundation

@MainActor
struct MeetupConflict: Identifiable {
    let id = UUID()
    let message: String
}

@MainActor
final class MeetupStore: ObservableObject {
    static let shared = MeetupStore()

    static var currentUserName: String {
        CurrentUserProfileStore.currentProfile().name
    }

    @Published private(set) var groups: [ActivityGroup] = []
    @Published private(set) var joinedGroupIDs: Set<UUID> = []
    @Published private(set) var createdGroupIDs: Set<UUID> = []
    @Published private(set) var messagesByGroupID: [UUID: [ChatMessage]] = [:]
    @Published private(set) var profilesByUserID: [UUID: UserProfile] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service = SupabaseMeetupService.shared

    private init() {}

    var joinedGroups: [ActivityGroup] {
        groups
            .filter { joinedGroupIDs.contains($0.id) }
            .sorted { $0.date < $1.date }
    }

    var createdGroupsCount: Int {
        createdGroupIDs.count
    }

    func groups(on date: Date, placeID: String? = nil) -> [ActivityGroup] {
        groups
            .filter { group in
                Calendar.current.isDate(group.date, inSameDayAs: date)
                    && (placeID == nil || group.placeID == placeID)
            }
            .sorted { $0.date < $1.date }
    }

    func group(with id: UUID) -> ActivityGroup? {
        groups.first { $0.id == id }
    }

    func messages(for groupID: UUID) -> [ChatMessage] {
        (messagesByGroupID[groupID] ?? [])
            .sorted { $0.sentAt < $1.sentAt }
    }

    func latestMessage(for groupID: UUID) -> ChatMessage? {
        messages(for: groupID).last
    }

    func userProfile(with userID: UUID?) -> UserProfile? {
        guard let userID else { return nil }
        return profilesByUserID[userID]
    }

    func loadAvailableGroups(on date: Date, place: PlaceAnnotation?) async {
        guard service.isConfigured else {
            errorMessage = "Supabase is not configured yet."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await service.fetchRooms(on: date, placeID: place?.id)
            merge(result)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            print("Load available meetups failed: \(error.localizedDescription)")
        }
    }

    func loadJoinedGroups() async {
        guard service.isConfigured else {
            errorMessage = "Supabase is not configured yet."
            return
        }

        do {
            guard let userID = try await SupabaseService.shared.ensureCurrentUser() else {
                return
            }

            let joinedResult = try await service.fetchJoinedRooms(for: userID)
            merge(joinedResult)
            joinedGroupIDs = Set(joinedResult.groups.map(\.id))
            createdGroupIDs = try await service.fetchCreatedRoomIDs(for: userID)

            for groupID in joinedGroupIDs {
                await loadMessages(for: groupID)
            }

            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            print("Load joined meetups failed: \(error.localizedDescription)")
        }
    }

    @discardableResult
    func join(_ group: ActivityGroup) async -> ActivityGroup? {
        if joinedGroupIDs.contains(group.id) {
            return self.group(with: group.id) ?? group
        }

        do {
            try await service.joinRoom(group.id)
            await loadJoinedGroups()
            await loadAvailableGroups(on: group.date, place: nil)
            return self.group(with: group.id) ?? group
        } catch {
            errorMessage = error.localizedDescription
            print("Join meetup failed: \(error.localizedDescription)")
            return nil
        }
    }

    func leave(_ group: ActivityGroup) async {
        do {
            try await service.leaveRoom(group.id)
            joinedGroupIDs.remove(group.id)
            messagesByGroupID[group.id] = []
            await loadJoinedGroups()
            await loadAvailableGroups(on: group.date, place: nil)
        } catch {
            errorMessage = error.localizedDescription
            print("Leave meetup failed: \(error.localizedDescription)")
        }
    }

    @discardableResult
    func createGroup(
        place: PlaceAnnotation?,
        name: String,
        description: String,
        address: String,
        date: Date,
        meetingTime: String,
        maxCapacity: Int
    ) async -> ActivityGroup? {
        do {
            guard let createdGroup = try await service.createRoom(
                place: place,
                name: name,
                description: description,
                address: address,
                date: date,
                meetingTime: meetingTime,
                maxCapacity: maxCapacity
            ) else {
                return nil
            }

            merge(
                SupabaseMeetupFetchResult(
                    groups: [createdGroup],
                    profiles: [:]
                )
            )
            joinedGroupIDs.insert(createdGroup.id)
            createdGroupIDs.insert(createdGroup.id)
            await loadJoinedGroups()
            await loadAvailableGroups(on: date, place: place)
            await loadMessages(for: createdGroup.id)
            return group(with: createdGroup.id) ?? createdGroup
        } catch {
            errorMessage = error.localizedDescription
            print("Create meetup failed: \(error.localizedDescription)")
            return nil
        }
    }

    func conflictingJoinedGroup(for candidate: ActivityGroup) -> ActivityGroup? {
        joinedGroups.first { joinedGroup in
            joinedGroup.id != candidate.id
                && Calendar.current.isDate(
                    joinedGroup.date,
                    inSameDayAs: candidate.date
                )
                && normalizedPlaceKey(for: joinedGroup)
                    == normalizedPlaceKey(for: candidate)
        }
    }

    func loadMessages(for groupID: UUID) async {
        guard service.isConfigured else { return }

        do {
            let result = try await service.fetchMessages(for: groupID)
            messagesByGroupID[groupID] = result.messages
            profilesByUserID.merge(result.profiles) { _, new in new }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            print("Load messages failed: \(error.localizedDescription)")
        }
    }

    func sendMessage(groupID: UUID, body: String) async {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else { return }

        do {
            try await service.sendMessage(groupID: groupID, body: trimmedBody)
            await loadMessages(for: groupID)
        } catch {
            errorMessage = error.localizedDescription
            print("Send message failed: \(error.localizedDescription)")
        }
    }

    private func merge(_ result: SupabaseMeetupFetchResult) {
        var nextGroups = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0) })
        for group in result.groups {
            nextGroups[group.id] = group
        }
        groups = Array(nextGroups.values).sorted { $0.date < $1.date }
        profilesByUserID.merge(result.profiles) { _, new in new }
    }

    private func normalizedPlaceKey(for group: ActivityGroup) -> String {
        if let placeID = group.placeID, !placeID.isEmpty {
            return placeID
        }

        return group.address
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

@MainActor
final class GroupsViewModel: ObservableObject {
    @Published var selectedDate: Date = Date() {
        didSet { refreshAvailableGroups() }
    }
    @Published private(set) var availableGroups: [ActivityGroup] = []
    @Published private(set) var userJoinedGroups: [UUID] = []
    @Published var meetupConflict: MeetupConflict?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let place: PlaceAnnotation?
    private let store: MeetupStore
    private var cancellables: Set<AnyCancellable> = []
    private var refreshTask: Task<Void, Never>?

    init(place: PlaceAnnotation? = nil) {
        self.place = place
        self.store = MeetupStore.shared

        self.store.$groups
            .sink { [weak self] _ in
                self?.applyCurrentFilters()
            }
            .store(in: &cancellables)

        self.store.$joinedGroupIDs
            .sink { [weak self] joinedGroupIDs in
                self?.userJoinedGroups = Array(joinedGroupIDs)
                self?.applyCurrentFilters()
            }
            .store(in: &cancellables)

        self.store.$isLoading
            .assign(to: &$isLoading)

        self.store.$errorMessage
            .assign(to: &$errorMessage)

        applyCurrentFilters()
        userJoinedGroups = Array(self.store.joinedGroupIDs)
    }

    deinit {
        refreshTask?.cancel()
    }

    func refreshAvailableGroups() {
        applyCurrentFilters()
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            await store.loadAvailableGroups(on: selectedDate, place: place)
            applyCurrentFilters()
        }
    }

    func searchGroups(for date: Date) {
        selectedDate = date
        refreshAvailableGroups()
    }

    @discardableResult
    func joinGroup(_ group: ActivityGroup) async -> ActivityGroup? {
        if let conflict = store.conflictingJoinedGroup(for: group) {
            meetupConflict = MeetupConflict(
                message: "You already joined \(conflict.name) on this date at this place. Leave that meetup first before joining another one here."
            )
            return nil
        }

        guard let joinedGroup = await store.join(group) else {
            if let message = store.errorMessage {
                meetupConflict = MeetupConflict(message: message)
            }
            return nil
        }

        refreshAvailableGroups()
        return joinedGroup
    }

    func leaveGroup(_ group: ActivityGroup) async {
        await store.leave(group)
        refreshAvailableGroups()
    }

    @discardableResult
    func createGroup(
        name: String,
        description: String,
        address: String,
        date: Date,
        meetingTime: String,
        maxCapacity: Int
    ) async -> ActivityGroup? {
        let candidate = ActivityGroup(
            placeID: place?.id,
            name: name,
            description: description,
            address: address,
            date: date,
            maxCapacity: maxCapacity,
            members: [],
            meetingTime: meetingTime
        )

        if let conflict = store.conflictingJoinedGroup(for: candidate) {
            meetupConflict = MeetupConflict(
                message: "You already joined \(conflict.name) on this date at this place. Leave that meetup first before creating another one here."
            )
            return nil
        }

        guard let createdGroup = await store.createGroup(
            place: place,
            name: name,
            description: description,
            address: address,
            date: date,
            meetingTime: meetingTime,
            maxCapacity: maxCapacity
        ) else {
            if let message = store.errorMessage {
                meetupConflict = MeetupConflict(message: message)
            }
            return nil
        }

        selectedDate = date
        refreshAvailableGroups()
        return createdGroup
    }

    func hasJoinedGroup(_ group: ActivityGroup) -> Bool {
        userJoinedGroups.contains(group.id)
    }

    private func applyCurrentFilters() {
        availableGroups = store.groups(on: selectedDate, placeID: place?.id)
    }
}
