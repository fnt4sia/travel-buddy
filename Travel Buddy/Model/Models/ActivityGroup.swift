import Foundation

struct ActivityGroup: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let date: Date
    let maxCapacity: Int
    var members: [GroupMember]
    let meetingTime: String
    let price: String
    
    var isFull: Bool {
        members.count >= maxCapacity
    }
    
    var availableSpots: Int {
        max(0, maxCapacity - members.count)
    }
}

struct GroupMember: Identifiable {
    let id = UUID()
    let name: String
    let color: String
}
