//
//  ActivityGroupsView.swift
//  Travel Buddy
//

import SwiftUI

enum GroupPendingConfirmation {
    case join(ActivityGroup)
    case leave(ActivityGroup)
}

// MARK: - Activity Groups View
// Single source of truth for the meetup flow.
// Can be launched standalone (tab bar) or from a place (PlaceDetailSheet).

struct ActivityGroupsView: View {
    let place: PlaceAnnotation?
    let onOpenChat: ((UUID) -> Void)?
    /// Set to true when pushed inside an existing NavigationStack (e.g. PlaceDetailSheet).
    /// Prevents double-nesting NavigationStacks which crashes SwiftUI.
    let isEmbedded: Bool

    @StateObject private var viewModel: GroupsViewModel
    @State private var showDatePicker = false
    @State private var showCreateMeetup = false

    enum GroupRoute: Hashable {
        case detail(UUID)
        case chat(UUID)
        case profile(UUID)
    }
    @State private var path: [GroupRoute] = []

    @State private var pendingConfirmation: GroupPendingConfirmation?

    init(
        place: PlaceAnnotation? = nil,
        isEmbedded: Bool = false,
        onOpenChat: ((UUID) -> Void)? = nil
    ) {
        self.place = place
        self.isEmbedded = isEmbedded
        self.onOpenChat = onOpenChat
        _viewModel = StateObject(wrappedValue: GroupsViewModel(place: place))
    }

    var body: some View {
        if isEmbedded {
            // Pushed inside PlaceDetailSheet's NavigationStack — no wrapper needed
            meetupContent
                .navigationTitle(place.map { "\($0.name) Meetups" } ?? "Meetups")
                .navigationBarTitleDisplayMode(.large)
        } else {
            // Standalone (tab bar) — owns its NavigationStack
            ZStack {
                NavigationStack(path: $path) {
                    meetupContent
                        .navigationTitle("Meetups")
                        .navigationBarTitleDisplayMode(.large)
                        .navigationDestination(for: GroupRoute.self) { route in
                            routeDestination(route)
                        }
                }
                confirmationOverlay
            }
        }
    }

    // MARK: - Shared content

    private var meetupContent: some View {
        VStack(spacing: 0) {
            dateAndCreateRow
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            if viewModel.availableGroups.isEmpty {
                emptyState
            } else {
                groupsList
            }

            Spacer()
        }
        .background(Color(UIColor.systemBackground))
        .onAppear { viewModel.refreshAvailableGroups() }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheetContent(
                isPresented: $showDatePicker,
                selectedDate: $viewModel.selectedDate
            )
            .presentationDetents([.height(500)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCreateMeetup) {
            CreateMeetupSheet(
                selectedDate: viewModel.selectedDate,
                defaultName: place.map { "\($0.name) Meetup" } ?? "New Meetup",
                defaultAddress: place?.address ?? "Selected place",
                defaultDescription: place.map { "Explore \($0.name), meet new people, and keep the plan flexible for the group." } ?? "",
                onCreate: { name, description, address, date, meetingTime, maxCapacity in
                    Task {
                        if let created = await viewModel.createGroup(
                            name: name,
                            description: description,
                            address: address,
                            date: date,
                            meetingTime: meetingTime,
                            maxCapacity: maxCapacity
                        ) {
                            openChat(created.id)
                        }
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert(item: $viewModel.meetupConflict) { conflict in
            Alert(
                title: Text("Already joined here"),
                message: Text(conflict.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    @ViewBuilder
    private func routeDestination(_ route: GroupRoute) -> some View {
        switch route {
        case .profile(let userID):
            let profile = MeetupStore.shared.userProfile(with: userID)
                ?? UserProfile.profile(for: "Traveler")
            let vm = ProfileViewModel(profile: profile)
            ProfileView(viewModel: vm)
        case .detail(let groupID):
            if let group = MeetupStore.shared.group(with: groupID) {
                GroupDetailView(
                    group: group,
                    hasJoined: viewModel.hasJoinedGroup(group),
                    pendingConfirmation: $pendingConfirmation,
                    openChat: { openChat(group.id) },
                    onMemberTapped: { member in
                        if let userID = member.userID {
                            path.append(.profile(userID))
                        }
                    }
                )
            } else {
                ContentUnavailableView(
                    "Meetup not found",
                    systemImage: "calendar.badge.exclamationmark"
                )
            }
        case .chat(let groupID):
            GroupChatView(groupID: groupID, showsCloseButton: false)
        }
    }

    @ViewBuilder
    private var confirmationOverlay: some View {
        if let pending = pendingConfirmation {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)

            GroupActionConfirmationPopup(
                title: {
                    if case .join = pending { return "Join Meetup" }
                    return "Leave Meetup"
                }(),
                message: {
                    if case .join = pending {
                        return "You will be added to this meetup and can access the group chat."
                    }
                    return "You will be removed from the meetup and lose access to the group chat."
                }(),
                cancelTitle: "Back",
                confirmTitle: {
                    if case .join = pending { return "Join" }
                    return "Leave"
                }(),
                onCancel: { withAnimation { pendingConfirmation = nil } },
                onConfirm: {
                    let captured = pending
                    withAnimation { pendingConfirmation = nil }
                    switch captured {
                    case .join(let group):
                        Task {
                            if let joined = await viewModel.joinGroup(group) {
                                openChat(joined.id)
                            }
                        }
                    case .leave(let group):
                        Task {
                            await viewModel.leaveGroup(group)
                        }
                    }
                }
            )
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
    }

    // MARK: - Subviews

    private var dateAndCreateRow: some View {
        VStack(spacing: 12) {
            Text("Select Available Date")
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Button(action: { showDatePicker = true }) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(AppColors.accent)
                        Text(
                            viewModel.selectedDate.formatted(
                                date: .abbreviated, time: .omitted
                            )
                        )
                        .foregroundStyle(AppColors.primaryText)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }

                Button(action: { showCreateMeetup = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Create")
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.accent)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundStyle(AppColors.secondaryText)
            Text("No meetups available")
                .font(.body)
                .foregroundStyle(AppColors.secondaryText)
            Text("Create one for this date")
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var groupsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(viewModel.availableGroups) { group in
                    GroupRowView(
                        group: group,
                        hasJoined: viewModel.hasJoinedGroup(group),
                        onJoinTapped: { withAnimation { pendingConfirmation = .join(group) } },
                        onLeaveTapped: { withAnimation { pendingConfirmation = .leave(group) } },
                        onCardTapped: { path.append(.detail(group.id)) },
                        onMemberTapped: { member in
                            if let userID = member.userID {
                                path.append(.profile(userID))
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    private func openChat(_ groupID: UUID) {
        if let onOpenChat {
            onOpenChat(groupID)
        } else {
            path.append(.chat(groupID))
        }
    }
}

// MARK: - Group Row

struct GroupRowView: View {
    let group: ActivityGroup
    let hasJoined: Bool
    let onJoinTapped: () -> Void
    let onLeaveTapped: () -> Void
    let onCardTapped: () -> Void
    var onMemberTapped: ((GroupMember) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(group.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                        .lineLimit(2)

                    Text(group.description)
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)

                statusBadge
            }

            infoRow

            attendeesAndActionRow
        }
        .padding(12)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.035), radius: 8, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture { onCardTapped() }
    }

    // MARK: Helpers

    private var statusBadge: some View {
        Text(statusTitle)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(statusForeground)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                statusBackground,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(statusBorder, lineWidth: 1)
            )
    }

    private var infoRow: some View {
        HStack(spacing: 8) {
            MeetupInfoPill(icon: "clock", text: group.meetingTime)
        }
    }

    private var attendeesAndActionRow: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -6) {
                    ForEach(Array(group.members.enumerated()), id: \.element.id) { index, member in
                        memberAvatar(for: member)
                            .zIndex(Double(group.members.count - index))
                    }
                }
                .padding(.trailing, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .scrollDisabled(group.members.count <= 7)

            actionButton
        }
    }

    private var actionButton: some View {
        Button {
            if hasJoined {
                onLeaveTapped()
            } else if !group.isFull {
                onJoinTapped()
            }
        } label: {
            Text(actionTitle)
                .font(.system(size: 14, weight: .bold))
                .frame(minWidth: 72)
                .padding(.vertical, 9)
                .padding(.horizontal, 12)
                .background(actionBackground, in: Capsule())
                .foregroundStyle(actionForeground)
        }
        .disabled(group.isFull && !hasJoined)
        .buttonStyle(.plain)
    }

    private var actionTitle: String {
        if hasJoined { return "Leave" }
        if group.isFull { return "Full" }
        return "Join"
    }

    private var actionBackground: Color {
        if hasJoined { return Color.red.opacity(0.9) }
        if group.isFull { return Color.gray.opacity(0.28) }
        return AppColors.accent
    }

    private var actionForeground: Color {
        hasJoined || (!group.isFull) ? .white : .gray
    }

    private var statusTitle: String {
        if hasJoined { return "Joined" }
        if group.isFull { return "Full" }
        return "\(group.availableSpots) left"
    }

    private var statusForeground: Color {
        if hasJoined { return AppColors.joinedStatusText }
        if group.isFull { return AppColors.secondaryText }
        return AppColors.brandPrimary
    }

    private var statusBackground: Color {
        if hasJoined { return AppColors.joinedStatusSurface }
        if group.isFull { return Color(UIColor.systemGray5) }
        return AppColors.accentSurface
    }

    private var statusBorder: Color {
        if hasJoined { return AppColors.warmAccent.opacity(0.45) }
        return AppColors.cardBorder
    }

    private func firstInitial(for fullName: String) -> String {
        String(fullName.split(separator: " ").first?.prefix(1) ?? "")
    }

    private func memberAvatar(for member: GroupMember) -> some View {
        Button {
            onMemberTapped?(member)
        } label: {
            Circle()
                .fill(memberColor(for: member.color))
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(AppColors.surface, lineWidth: 2)
                )
                .overlay(
                    Text(firstInitial(for: member.name))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                )
        }
        .buttonStyle(.plain)
    }

    private func memberColor(for colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "teal": return AppColors.accent
        default: return .gray
        }
    }
}

private struct MeetupInfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppColors.brandPrimary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppColors.accentSurface, in: Capsule())
            .overlay(Capsule().stroke(AppColors.cardBorder, lineWidth: 1))
    }
}

// MARK: - Supporting sheets & popups (unchanged)

struct LeaveGroupConfirmationView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .offset(x: -60, y: -40)

                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .offset(x: 70, y: 50)

                        Circle()
                            .fill(.white)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.crop.circle.badge.minus")
                                    .font(.system(size: 42, weight: .bold))
                                    .foregroundStyle(.red)
                            )
                    }
                    .frame(height: 180)

                    VStack(spacing: 10) {
                        Text("You left the group")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Your reservation has been cancelled and you have been removed from the attendee list.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Button { dismiss() } label: {
                    Text("Back to Groups")
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white)
                        .foregroundStyle(.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}

struct GroupActionConfirmationPopup: View {
    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(message)
                .font(.body)
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(action: onCancel) {
                    Text(cancelTitle)
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(UIColor.systemGray5))
                        .foregroundStyle(AppColors.primaryText)
                        .clipShape(Capsule())
                }

                Button(action: onConfirm) {
                    Text(confirmTitle)
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.accent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .frame(maxWidth: 340)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 12)
        .padding(.horizontal, 20)
    }
}

struct CreateMeetupSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var address: String
    @State private var date: Date
    @State private var meetingTime: String
    @State private var maxCapacity: Int

    let onCreate: (String, String, String, Date, String, Int) -> Void

    init(
        selectedDate: Date,
        defaultName: String = "New Meetup",
        defaultAddress: String,
        defaultDescription: String = "",
        onCreate: @escaping (String, String, String, Date, String, Int) -> Void
    ) {
        _name = State(initialValue: defaultName)
        _description = State(initialValue: defaultDescription)
        _address = State(initialValue: defaultAddress)
        _date = State(initialValue: selectedDate)
        _meetingTime = State(initialValue: "09:00 - 11:00 GMT+8")
        _maxCapacity = State(initialValue: ActivityGroup.minimumCapacity)
        self.onCreate = onCreate
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    field(title: "Title", placeholder: "Sunset walk and dinner", text: $name)
                    descriptionField

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.secondaryText)

                        DatePicker("Date", selection: $date, displayedComponents: [.date])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }

                    field(title: "Time", placeholder: "09:00 - 11:00 GMT+8", text: $meetingTime)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group size")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.secondaryText)

                        Stepper(
                            "\(maxCapacity) people",
                            value: $maxCapacity,
                            in: ActivityGroup.minimumCapacity...ActivityGroup.maximumCapacity
                        )
                            .font(.body)
                            .foregroundStyle(AppColors.primaryText)

                        Text("Meetups need at least \(ActivityGroup.minimumCapacity) people and can have up to \(ActivityGroup.maximumCapacity).")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
                .padding(20)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Create Meetup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(
                            trimmed(name), trimmed(description), trimmed(address),
                            date, trimmed(meetingTime), maxCapacity
                        )
                        dismiss()
                    }
                    .disabled(!canCreate)
                }
            }
        }
    }

    private var canCreate: Bool {
        !trimmed(name).isEmpty && !trimmed(description).isEmpty
            && !trimmed(meetingTime).isEmpty
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func field(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.secondaryText)

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity to do")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.secondaryText)

            TextEditor(text: $description)
                .frame(minHeight: 92)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topLeading) {
                    if trimmed(description).isEmpty {
                        Text("What will the group do together?")
                            .font(.body)
                            .foregroundStyle(AppColors.secondaryText.opacity(0.75))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}

struct GroupDetailView: View {
    let group: ActivityGroup
    let hasJoined: Bool
    @Binding var pendingConfirmation: GroupPendingConfirmation?
    let openChat: () -> Void
    var onMemberTapped: ((GroupMember) -> Void)? = nil

    // Reuse the same slot type logic as GroupRowView for consistent UI
    private enum Slot: Identifiable {
        case member(GroupMember)

        var id: String {
            switch self {
            case .member(let m): return m.id.uuidString
            }
        }
    }

    private var allSlots: [Slot] {
        group.members.map { .member($0) }
    }

    // Same right-first two-column layout as GroupRowView
    private var rightColSlots: [Slot] {
        allSlots.enumerated().filter { $0.offset % 2 == 0 }.map(\.element)
    }
    private var leftColSlots: [Slot] {
        allSlots.enumerated().filter { $0.offset % 2 == 1 }.map(\.element)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(group.name)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(group.description)
                        .font(.body)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 12) {
                    Label(group.meetingTime, systemImage: "clock")
                    Label("\(group.members.count)/\(group.maxCapacity) participants", systemImage: "person.3.fill")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.brandPrimary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.accentSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 14) {
                    Text("People")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.primaryText)

                    HStack(alignment: .top, spacing: 8) {
                        if !leftColSlots.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(leftColSlots) { slot in participantRow(for: slot) }
                            }
                            .frame(maxWidth: .infinity)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(rightColSlots) { slot in participantRow(for: slot) }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(18)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )

                VStack(spacing: 10) {
                    if hasJoined {
                        Button("Open Group Chat") { openChat() }
                            .font(.body)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.accent)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())

                        Button("Leave Meetup") {
                            withAnimation { pendingConfirmation = .leave(group) }
                        }
                        .font(.body)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                    } else {
                        Button(group.isFull ? "Meetup is Full" : "Join Meetup") {
                            guard !group.isFull else { return }
                            withAnimation { pendingConfirmation = .join(group) }
                        }
                        .font(.body)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(group.isFull ? Color.gray.opacity(0.25) : AppColors.accent)
                        .foregroundStyle(group.isFull ? AppColors.secondaryText : .white)
                        .clipShape(Capsule())
                        .disabled(group.isFull)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Meetup")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func participantRow(for slot: Slot) -> some View {
        switch slot {
        case .member(let member):
            HStack(spacing: 10) {
                Circle()
                    .fill(memberColor(for: member.color))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(String(member.name.prefix(1)))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    )
                Text(member.name.split(separator: " ").first.map(String.init) ?? member.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
            .background(Color(UIColor.systemGray5))
            .overlay(Capsule().stroke(Color(UIColor.systemGray3), lineWidth: 1.5))
            .clipShape(Capsule())
            .onTapGesture { onMemberTapped?(member) }
        }
    }

    private func memberColor(for colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "teal": return AppColors.accent
        default: return .gray
        }
    }
}

// JoinMeetupConfirmationView and LeaveMeetupConfirmationView removed — popup is now handled by ActivityGroupsView's ZStack

struct DatePickerSheetContent: View {
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date

    var body: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color(UIColor.separator))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            Text("Select Date")
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            DatePicker("Choose a date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .padding(.horizontal, 16)

            Button(action: { isPresented = false }) {
                Text("Done")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.accent)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            .padding(16)
        }
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    ActivityGroupsView()
}
