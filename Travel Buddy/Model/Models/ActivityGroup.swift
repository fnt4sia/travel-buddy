import Foundation

struct ActivityGroup: Identifiable {
    static let minimumCapacity = 4
    static let maximumCapacity = 8

    let id: UUID
    let name: String
    let description: String
    let address: String
    let date: Date
    let meetingTime: String
    let maxCapacity: Int
    var members: [GroupMember]

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        address: String,
        date: Date,
        maxCapacity: Int,
        members: [GroupMember],
        meetingTime: String
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.address = address
        self.date = date
        self.maxCapacity = min(
            max(maxCapacity, Self.minimumCapacity),
            Self.maximumCapacity
        )
        self.members = members
        self.meetingTime = meetingTime
    }

    var isFull: Bool {
        members.count >= maxCapacity
    }

    var availableSpots: Int {
        max(0, maxCapacity - members.count)
    }
}

struct GroupMember: Identifiable {
    let id: UUID
    let name: String
    let color: String

    init(id: UUID = UUID(), name: String, color: String) {
        self.id = id
        self.name = name
        self.color = color
    }
}
