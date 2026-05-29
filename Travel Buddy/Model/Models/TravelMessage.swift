import Foundation

struct TravelParticipant: Identifiable {
    let id = UUID()
    let name: String
    let initial: String
    let colorHex: String
}

struct TravelMessage: Identifiable {
    let id = UUID()
    let placeName: String
    let dateText: String
    let senderName: String
    let preview: String
    let participants: [TravelParticipant]

    static let samples: [TravelMessage] = [
        TravelMessage(
            placeName: "Monkey Forest Ubud",
            dateText: "27th July, 2026",
            senderName: "Deco",
            preview: "Hi, My name is Deco. I am from Indonesia. Nice to meet you all",
            participants: [
                TravelParticipant(name: "Deco", initial: "D", colorHex: "78A7B7"),
                TravelParticipant(name: "Ayu", initial: "A", colorHex: "E8A75E"),
                TravelParticipant(name: "Nadia", initial: "N", colorHex: "E8D2C8")
            ]
        ),
        TravelMessage(
            placeName: "Imadji Coffee Kuta",
            dateText: "28th July, 2026",
            senderName: "Maria",
            preview: "Hi, My name is Maria. I am from Malaysia. Nice to meet you all",
            participants: [
                TravelParticipant(name: "Maria", initial: "M", colorHex: "C9804B"),
                TravelParticipant(name: "Lina", initial: "L", colorHex: "E8B86F"),
                TravelParticipant(name: "Sari", initial: "S", colorHex: "EDDED1")
            ]
        )
    ]
}
