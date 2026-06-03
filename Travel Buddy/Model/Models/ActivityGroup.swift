import Foundation

struct ActivityGroup: Identifiable {
    let id: UUID
    let name: String
    let address: String
    let date: Date
    let maxCapacity: Int
    var members: [GroupMember]
    let meetingTime: String
    let price: String

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        date: Date,
        maxCapacity: Int,
        members: [GroupMember],
        meetingTime: String,
        price: String
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.date = date
        self.maxCapacity = maxCapacity
        self.members = members
        self.meetingTime = meetingTime
        self.price = price
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
