import Foundation

struct ChatMessage: Identifiable {
    let id: UUID
    let groupID: UUID
    let senderID: UUID?
    let senderName: String
    let body: String
    let sentAt: Date

    init(
        id: UUID = UUID(),
        groupID: UUID,
        senderID: UUID? = nil,
        senderName: String,
        body: String,
        sentAt: Date = Date()
    ) {
        self.id = id
        self.groupID = groupID
        self.senderID = senderID
        self.senderName = senderName
        self.body = body
        self.sentAt = sentAt
    }

    var senderInitial: String {
        String(senderName.prefix(1)).uppercased()
    }
}
