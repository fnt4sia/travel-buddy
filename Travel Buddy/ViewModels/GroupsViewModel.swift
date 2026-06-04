import Foundation
import Combine

@MainActor
struct MeetupConflict: Identifiable {
    let id = UUID()
    let message: String
}

@MainActor
final class MeetupStore: ObservableObject {
    static let shared = MeetupStore()
    static let currentUserName = "You"

    @Published private(set) var groups: [ActivityGroup]
    @Published private(set) var joinedGroupIDs: Set<UUID> = []
    @Published private(set) var messagesByGroupID: [UUID: [ChatMessage]]

    private init() {
        let sampleGroups = Self.makeSampleGroups()
        groups = sampleGroups
        messagesByGroupID = Dictionary(
            uniqueKeysWithValues: sampleGroups.map { group in
                (group.id, Self.makeSeedMessages(for: group))
            }
        )
    }

    var joinedGroups: [ActivityGroup] {
        groups
            .filter { joinedGroupIDs.contains($0.id) }
            .sorted { $0.date < $1.date }
    }

    func groups(on date: Date) -> [ActivityGroup] {
        groups
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
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

    @discardableResult
    func join(_ group: ActivityGroup) -> ActivityGroup? {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else {
            return nil
        }

        if !joinedGroupIDs.contains(group.id) {
            guard conflictingJoinedGroup(for: groups[index]) == nil else {
                return nil
            }

            joinedGroupIDs.insert(group.id)

            if !groups[index].members.contains(where: { $0.name == Self.currentUserName }),
               !groups[index].isFull {
                groups[index].members.append(
                    GroupMember(name: Self.currentUserName, color: "teal")
                )
            }
        }

        if messagesByGroupID[group.id] == nil {
            messagesByGroupID[group.id] = Self.makeSeedMessages(for: groups[index])
        }

        return groups[index]
    }

    func leave(_ group: ActivityGroup) {
        joinedGroupIDs.remove(group.id)

        guard let index = groups.firstIndex(where: { $0.id == group.id }) else {
            return
        }

        groups[index].members.removeAll { $0.name == Self.currentUserName }
    }

    @discardableResult
    func createGroup(
        name: String,
        address: String,
        date: Date,
        meetingTime: String,
        maxCapacity: Int,
        price: String
    ) -> ActivityGroup? {
        let group = ActivityGroup(
            name: name,
            address: address,
            date: date,
            maxCapacity: maxCapacity,
            members: [
                GroupMember(name: Self.currentUserName, color: "teal")
            ],
            meetingTime: meetingTime,
            price: price
        )

        guard conflictingJoinedGroup(for: group) == nil else {
            return nil
        }

        groups.insert(group, at: 0)
        joinedGroupIDs.insert(group.id)
        messagesByGroupID[group.id] = [
            ChatMessage(
                groupID: group.id,
                senderName: Self.currentUserName,
                body: "Hi everyone, I created this meetup. See you there!"
            )
        ]

        return group
    }

    func conflictingJoinedGroup(for candidate: ActivityGroup) -> ActivityGroup? {
        joinedGroups.first { joinedGroup in
            joinedGroup.id != candidate.id
                && Calendar.current.isDate(
                    joinedGroup.date,
                    inSameDayAs: candidate.date
                )
                && Self.normalizedPlace(joinedGroup.address)
                    == Self.normalizedPlace(candidate.address)
        }
    }

    func sendMessage(groupID: UUID, body: String) {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else { return }

        messagesByGroupID[groupID, default: []].append(
            ChatMessage(
                groupID: groupID,
                senderName: Self.currentUserName,
                body: trimmedBody
            )
        )
    }

    private static func makeSampleGroups() -> [ActivityGroup] {
        [
            ActivityGroup(
                name: "Morning Adventure",
                address: "Jl. Monkey Forest, Ubud, Kecamatan Ubud",
                date: Calendar.current.date(byAdding: .day, value: 0, to: Date()) ?? Date(),
                maxCapacity: 4,
                members: [
                    GroupMember(name: "Agustinus Juan", color: "blue"),
                    GroupMember(name: "Rani", color: "green"),
                ],
                meetingTime: "09:00 - 15:00 GMT+8",
                price: "Rp25.000"
            ),
            ActivityGroup(
                name: "Sunset Explorer",
                address: "Jl. Raya Ubud No.35, Ubud, Kecamatan Ubud",
                date: Calendar.current.date(byAdding: .day, value: 0, to: Date()) ?? Date(),
                maxCapacity: 7,
                members: [
                    GroupMember(name: "Jody", color: "purple"),
                    GroupMember(name: "Balqis", color: "orange"),
                ],
                meetingTime: "16:00 - 19:00 GMT+8",
                price: "Rp20.000"
            ),
            ActivityGroup(
                name: "Full Group Experience",
                address: "Kelusa, Payangan, Kabupaten Gianyar",
                date: Calendar.current.date(byAdding: .day, value: 0, to: Date()) ?? Date(),
                maxCapacity: 3,
                members: [
                    GroupMember(name: "Dodo", color: "red"),
                    GroupMember(name: "Eka", color: "yellow"),
                    GroupMember(name: "Fira", color: "cyan"),
                ],
                meetingTime: "08:00 - 14:00 GMT+8",
                price: "Rp30.000"
            ),
            ActivityGroup(
                name: "Afternoon Exploration",
                address: "Jl. Kajeng, Ubud, Kecamatan Ubud",
                date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                maxCapacity: 4,
                members: [
                    GroupMember(name: "John", color: "purple"),
                    GroupMember(name: "Maria", color: "blue"),
                ],
                meetingTime: "14:00 - 17:00 GMT+8",
                price: "Rp15.000"
            ),
            ActivityGroup(
                name: "Nature Lovers Walk",
                address: "Jl. Raya Andong, Ubud, Kecamatan Ubud",
                date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                maxCapacity: 5,
                members: [
                    GroupMember(name: "Budi", color: "green"),
                    GroupMember(name: "Siti", color: "orange"),
                    GroupMember(name: "Ahmad", color: "red"),
                ],
                meetingTime: "06:00 - 10:00 GMT+8",
                price: "Rp18.000"
            ),
        ]
    }

    private static func normalizedPlace(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private static func makeSeedMessages(for group: ActivityGroup) -> [ChatMessage] {
        guard let firstMember = group.members.first else {
            return []
        }

        return [
            ChatMessage(
                groupID: group.id,
                senderName: firstMember.name,
                body: "Hi, I am joining \(group.name). Nice to meet you all!",
                sentAt: Calendar.current.date(byAdding: .minute, value: -26, to: Date()) ?? Date()
            ),
            ChatMessage(
                groupID: group.id,
                senderName: group.members.dropFirst().first?.name ?? firstMember.name,
                body: "Let's meet near the entrance before we start.",
                sentAt: Calendar.current.date(byAdding: .minute, value: -12, to: Date()) ?? Date()
            ),
        ]
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

    private let store: MeetupStore
    private var cancellables: Set<AnyCancellable> = []

    init() {
        self.store = MeetupStore.shared

        self.store.$groups
            .sink { [weak self] _ in
                self?.refreshAvailableGroups()
            }
            .store(in: &cancellables)

        self.store.$joinedGroupIDs
            .sink { [weak self] joinedGroupIDs in
                self?.userJoinedGroups = Array(joinedGroupIDs)
            }
            .store(in: &cancellables)

        refreshAvailableGroups()
        userJoinedGroups = Array(self.store.joinedGroupIDs)
    }

    func refreshAvailableGroups() {
        availableGroups = store.groups(on: selectedDate)
    }

    func searchGroups(for date: Date) {
        selectedDate = date
        refreshAvailableGroups()
    }

    @discardableResult
    func joinGroup(_ group: ActivityGroup) -> ActivityGroup? {
        if let conflict = store.conflictingJoinedGroup(for: group) {
            meetupConflict = MeetupConflict(
                message: "You already joined \(conflict.name) on this date at this place. Leave that meetup first before joining another one here."
            )
            return nil
        }

        if let joinedGroup = store.join(group) {
            refreshAvailableGroups()
            return joinedGroup
        }
        return nil
    }

    func leaveGroup(_ group: ActivityGroup) {
        store.leave(group)
        refreshAvailableGroups()
    }

    @discardableResult
    func createGroup(
        name: String,
        address: String,
        date: Date,
        meetingTime: String,
        maxCapacity: Int,
        price: String
    ) -> ActivityGroup? {
        let candidate = ActivityGroup(
            name: name,
            address: address,
            date: date,
            maxCapacity: maxCapacity,
            members: [],
            meetingTime: meetingTime,
            price: price
        )

        if let conflict = store.conflictingJoinedGroup(for: candidate) {
            meetupConflict = MeetupConflict(
                message: "You already joined \(conflict.name) on this date at this place. Leave that meetup first before creating another one here."
            )
            return nil
        }

        guard let createdGroup = store.createGroup(
            name: name,
            address: address,
            date: date,
            meetingTime: meetingTime,
            maxCapacity: maxCapacity,
            price: price
        ) else {
            return nil
        }
        selectedDate = date
        refreshAvailableGroups()
        return createdGroup
    }

    func hasJoinedGroup(_ group: ActivityGroup) -> Bool {
        userJoinedGroups.contains(group.id)
    }
}
