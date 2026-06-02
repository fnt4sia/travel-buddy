import Foundation

struct ChatMessage: Identifiable {
    let id: UUID
    let groupID: UUID
    let senderName: String
    let body: String
    let sentAt: Date

    init(
        id: UUID = UUID(),
        groupID: UUID,
        senderName: String,
        body: String,
        sentAt: Date = Date()
    ) {
        self.id = id
        self.groupID = groupID
        self.senderName = senderName
        self.body = body
        self.sentAt = sentAt
    }

    var senderInitial: String {
        String(senderName.prefix(1)).uppercased()
    }
}
