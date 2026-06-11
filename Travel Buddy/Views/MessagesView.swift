import SwiftUI

struct MessagesView: View {
    @Binding var chatPath: [UUID]
    @ObservedObject private var store = MeetupStore.shared

    var body: some View {
        NavigationStack(path: $chatPath) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Messages")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(AppColors.accentText)
                        .padding(.top, 44)

                    if store.joinedGroups.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 0) {
                            ForEach(store.joinedGroups) { group in
                                NavigationLink(value: group.id) {
                                    ConversationRow(
                                        group: group,
                                        latestMessage: store.latestMessage(
                                            for: group.id
                                        )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 120)
            }
            .background(AppColors.background)
            .navigationDestination(for: UUID.self) { groupID in
                GroupChatView(groupID: groupID, showsCloseButton: false)
            }
        }
        .task {
            await store.loadJoinedGroups()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppColors.accentText)

            Text("No meetup chats yet")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.primaryText)

            Text("Join or create a meetup to start a room.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }
}

private struct ConversationRow: View {
    let group: ActivityGroup
    let latestMessage: ChatMessage?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            AvatarStack(members: group.members)
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(group.name)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text("• \(dateText)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(1)
                }

                Text(previewText)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }
            .padding(.bottom, 14)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppColors.divider)
                    .frame(height: 1)
            }
        }
        .padding(.bottom, 14)
    }

    private var dateText: String {
        group.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var previewText: AttributedString {
        guard let latestMessage else {
            return AttributedString("Room created")
        }

        var text = AttributedString(
            "\(latestMessage.senderName): \(latestMessage.body)"
        )

        if let range = text.range(of: "\(latestMessage.senderName):") {
            text[range].font = .system(size: 16, weight: .bold)
        }

        return text
    }
}

struct GroupChatView: View {
    let groupID: UUID
    var showsCloseButton = true

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = MeetupStore.shared
    @State private var draftMessage = ""
    @State private var selectedProfile: UserProfile?

    var body: some View {
        VStack(spacing: 0) {
            if let group = store.group(with: groupID) {
                chatHeader(for: group)
                Divider()
                messageList(for: group)
                composer
            } else {
                missingRoom
            }
        }
        .background(AppColors.background)
        .sheet(item: $selectedProfile) { profile in
            ProfileDetailView(profile: profile)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    private func chatHeader(for group: ActivityGroup) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                if showsCloseButton {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.primaryText)
                            .frame(width: 32, height: 32)
                            .background(AppColors.fieldSurface)
                            .clipShape(Circle())
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.primaryText)
                        .lineLimit(1)

                    Text("\(group.meetingTime) • \(group.members.count)/\(group.maxCapacity)")
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(1)
                }

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(group.members) { member in
                        Button {
                            selectedProfile = store.userProfile(with: member.userID)
                                ?? UserProfile.profile(for: member.name)
                        } label: {
                            HStack(spacing: 8) {
                                AvatarCircle(
                                    initial: firstInitial(for: member.name),
                                    colorHex: colorHex(for: member.color),
                                    size: 30
                                )

                                Text(firstName(for: member.name))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.primaryText)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(AppColors.fieldSurface)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, showsCloseButton ? 18 : 10)
        .padding(.bottom, 14)
    }

    private func messageList(for group: ActivityGroup) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(store.messages(for: group.id)) { message in
                        ChatBubble(
                            message: message,
                            isCurrentUser:
                                isCurrentUser(message),
                            onProfileTapped: {
                                selectedProfile = store.userProfile(with: message.senderID)
                                    ?? UserProfile.profile(for: message.senderName)
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .onAppear {
                Task {
                    await store.loadMessages(for: group.id)
                }
                scrollToLatest(in: proxy, groupID: group.id, animated: false)
            }
            .onChange(of: store.messages(for: group.id).count) { _, _ in
                scrollToLatest(in: proxy, groupID: group.id, animated: true)
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Message", text: $draftMessage, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(AppColors.fieldSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.textOnAccent)
                    .frame(width: 42, height: 42)
                    .background(canSend ? AppColors.accent : Color.gray.opacity(0.35))
                    .clipShape(Circle())
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }

    private var missingRoom: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppColors.secondaryText)

            Text("Room unavailable")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.primaryText)

            if showsCloseButton {
                Button("Close") { dismiss() }
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var canSend: Bool {
        !draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendMessage() {
        let body = draftMessage
        draftMessage = ""
        Task {
            await store.sendMessage(groupID: groupID, body: body)
        }
    }

    private func isCurrentUser(_ message: ChatMessage) -> Bool {
        if let senderID = message.senderID,
           senderID == SupabaseService.shared.currentUserID {
            return true
        }

        return message.senderName == MeetupStore.currentUserName
    }

    private func scrollToLatest(
        in proxy: ScrollViewProxy,
        groupID: UUID,
        animated: Bool
    ) {
        guard let latestMessage = store.messages(for: groupID).last else {
            return
        }

        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(latestMessage.id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(latestMessage.id, anchor: .bottom)
        }
    }

    private func firstName(for fullName: String) -> String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }

    private func firstInitial(for fullName: String) -> String {
        String(fullName.prefix(1)).uppercased()
    }
}

private struct ChatBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let onProfileTapped: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer(minLength: 42)
            } else {
                Button(action: onProfileTapped) {
                    AvatarCircle(
                        initial: message.senderInitial,
                        colorHex: colorHex(for: message.senderName),
                        size: 32
                    )
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 5) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Text(message.body)
                    .font(.body)
                    .foregroundStyle(isCurrentUser ? .white : AppColors.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isCurrentUser
                            ? AppColors.accent
                            : AppColors.fieldSurface
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )

                Text(message.sentAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(AppColors.secondaryText)
            }
            .frame(maxWidth: 270, alignment: isCurrentUser ? .trailing : .leading)

            if !isCurrentUser {
                Spacer(minLength: 42)
            }
        }
    }
}

private struct AvatarStack: View {
    let members: [GroupMember]

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(members.prefix(3).enumerated()), id: \.element.id) {
                index,
                member in
                AvatarCircle(
                    initial: String(member.name.prefix(1)).uppercased(),
                    colorHex: colorHex(for: member.color),
                    size: 42
                )
                .offset(x: CGFloat(index) * 17)
                .zIndex(Double(3 - index))
            }
        }
        .frame(width: 78, height: 44, alignment: .leading)
    }
}

private struct AvatarCircle: View {
    let initial: String
    let colorHex: String
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color(hex: colorHex))
            .frame(width: size, height: size)
            .overlay {
                Text(initial)
                    .font(.system(size: size * 0.38, weight: .bold))
                    .foregroundColor(AppColors.textOnAccent)
            }
            .overlay {
                Circle()
                    .stroke(AppColors.textOnAccent, lineWidth: size >= 40 ? 3 : 1.5)
            }
    }
}

private func colorHex(for colorName: String) -> String {
    switch colorName {
    case "blue": return "78A7B7"
    case "green": return "6D9F72"
    case "purple": return "8E6CCB"
    case "orange": return "E8A75E"
    case "red": return "C96B5A"
    case "yellow": return "D9B85F"
    case "cyan": return "66AFC2"
    case "teal": return "0F8F8B"
    default:
        let values = ["B7798A", "7E9D78", "C9804B", "6C86B8"]
        let index = abs(colorName.hashValue) % values.count
        return values[index]
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
        MessagesView(chatPath: .constant([]))
    }
}
