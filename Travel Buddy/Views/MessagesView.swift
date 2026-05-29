import SwiftUI

struct MessagesView: View {
    private let messages = TravelMessage.samples

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                Text("Messages")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.teal)
                    .padding(.top, 44)

                VStack(spacing: 0) {
                    ForEach(messages) { message in
                        MessageRow(message: message)
                    }
                }
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 120)
        }
        .background(Color.white)
    }
}

private struct MessageRow: View {
    let message: TravelMessage

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            AvatarStack(participants: message.participants)
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(message.placeName)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text("• \(message.dateText)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black.opacity(0.34))
                        .lineLimit(1)
                }

                Text(previewText)
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.34))
            }
            .padding(.bottom, 14)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(height: 1)
            }
        }
        .padding(.bottom, 14)
    }

    private var previewText: AttributedString {
        var text = AttributedString("\(message.senderName): \(message.preview)")

        if let range = text.range(of: "\(message.senderName):") {
            text[range].font = .system(size: 16, weight: .bold)
        }

        return text
    }
}

private struct AvatarStack: View {
    let participants: [TravelParticipant]

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(participants.prefix(3).enumerated()), id: \.element.id) { index, participant in
                AvatarCircle(participant: participant)
                    .offset(x: CGFloat(index) * 17)
                    .zIndex(Double(3 - index))
            }
        }
        .frame(width: 78, height: 44, alignment: .leading)
    }
}

private struct AvatarCircle: View {
    let participant: TravelParticipant

    var body: some View {
        Circle()
            .fill(Color(hex: participant.colorHex))
            .frame(width: 42, height: 42)
            .overlay {
                Text(participant.initial)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .overlay {
                Circle()
                    .stroke(Color.white, lineWidth: 3)
            }
    }
}

private extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let red = Double((value >> 16) & 0xff) / 255
        let green = Double((value >> 8) & 0xff) / 255
        let blue = Double(value & 0xff) / 255

        self.init(red: red, green: green, blue: blue)
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}
