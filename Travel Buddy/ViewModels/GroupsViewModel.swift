import Foundation
import Combine

@MainActor
class GroupsViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var availableGroups: [ActivityGroup] = []
    @Published var userJoinedGroups: [UUID] = []
    @Published var showGroupConfirmation = false
    @Published var selectedGroup: ActivityGroup?
    
    private let mockGroups = [
        ActivityGroup(
            name: "Morning Adventure",
            address: "Jl. Monkey Forest, Ubud, Kecamatan Ubud",
            date: Calendar.current.date(byAdding: .day, value: 0, to: Date()) ?? Date(),
            maxCapacity: 5,
            members: [
                GroupMember(name: "Agustina Juan", color: "blue"),
                GroupMember(name: "Rani", color: "green"),
            ],
            meetingTime: "09:00 - 15:00 GMT+8",
            price: "Rp25.000"
        ),
        ActivityGroup(
            name: "Sunset Explorer",
            address: "Jl. Raya Ubud No.35, Ubud, Kecamatan Ubud",
            date: Calendar.current.date(byAdding: .day, value: 0, to: Date()) ?? Date(),
            maxCapacity: 5,
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
    
    func searchGroups(for date: Date) {
        let calendar = Calendar.current
        let selectedDateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        availableGroups = mockGroups.filter { group in
            let groupDateComponents = calendar.dateComponents([.year, .month, .day], from: group.date)
            return selectedDateComponents == groupDateComponents
        }
    }
    
    func joinGroup(_ group: ActivityGroup) {
        selectedGroup = group
        showGroupConfirmation = true
        
        // Simulate joining the group
        if let index = availableGroups.firstIndex(where: { $0.id == group.id }) {
            var updatedGroup = availableGroups[index]
            updatedGroup.members.append(GroupMember(name: "You", color: "teal"))
            availableGroups[index] = updatedGroup
            userJoinedGroups.append(group.id)
        }
    }
    
    func leaveGroup(_ group: ActivityGroup) {
        userJoinedGroups.removeAll { $0 == group.id }
        if let index = availableGroups.firstIndex(where: { $0.id == group.id }) {
            var updatedGroup = availableGroups[index]
            updatedGroup.members.removeAll { $0.name == "You" }
            availableGroups[index] = updatedGroup
        }
    }
    
    func hasJoinedGroup(_ group: ActivityGroup) -> Bool {
        userJoinedGroups.contains(group.id)
    }
}
