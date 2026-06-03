import SwiftUI

// MARK: - Activity Groups View
// Single source of truth for the meetup flow.
// Can be launched standalone (tab bar) or from a place (PlaceDetailSheet).

struct ActivityGroupsView: View {
    /// When launched from a place, shows place context and pre-fills meetup defaults.
    let place: PlaceAnnotation?

    @StateObject private var viewModel = GroupsViewModel()
    @State private var showDatePicker = false
    @State private var showCreateMeetup = false

    enum GroupRoute: Hashable {
        case detail(UUID)
        case chat(UUID)
    }
    @State private var path: [GroupRoute] = []

    // Confirmation popup — lifted here so it overlays the full screen, not just one card
    enum PendingConfirmation { case join(ActivityGroup), leave(ActivityGroup) }
    @State private var pendingConfirmation: PendingConfirmation?

    // Convenience init for standalone (tab bar) usage
    init(place: PlaceAnnotation? = nil) {
        self.place = place
    }

    var body: some View {
        ZStack {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                // Date + Create row
                dateAndCreateRow
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // Groups list or empty state
                if viewModel.availableGroups.isEmpty {
                    emptyState
                } else {
                    groupsList
                }

                Spacer()
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle(place.map { "\($0.name) Meetups" } ?? "Meetups")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.refreshAvailableGroups()
            }
            .navigationDestination(for: GroupRoute.self) { route in
                switch route {
                case .detail(let groupID):
                    if let group = viewModel.availableGroups.first(where: { $0.id == groupID }) {
                        GroupDetailView(
                            group: group,
                            hasJoined: viewModel.hasJoinedGroup(group),
                            pendingConfirmation: $pendingConfirmation,
                            openChat: { path.append(.chat(group.id)) }
                        )
                    }
                case .chat(let groupID):
                    GroupChatView(groupID: groupID, showsCloseButton: false)
                }
            }
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
                    defaultAddress: place?.address ?? "Choose a nearby meeting point",
                    onCreate: { name, address, date, meetingTime, maxCapacity, price in
                        if let created = viewModel.createGroup(
                            name: name,
                            address: address,
                            date: date,
                            meetingTime: meetingTime,
                            maxCapacity: maxCapacity,
                            price: price
                        ) {
                            path = [.chat(created.id)]
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
        } // NavigationStack

        // Full-screen confirmation popup
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
                        if let joined = viewModel.joinGroup(group) {
                            path.append(.chat(joined.id))
                        }
                    case .leave(let group):
                        viewModel.leaveGroup(group)
                    }
                }
            )
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }

        } // ZStack
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
            VStack(spacing: 12) {
                ForEach(viewModel.availableGroups) { group in
                    GroupRowView(
                        group: group,
                        hasJoined: viewModel.hasJoinedGroup(group),
                        onJoinTapped: { withAnimation { pendingConfirmation = .join(group) } },
                        onLeaveTapped: { withAnimation { pendingConfirmation = .leave(group) } },
                        onCardTapped: { path.append(.detail(group.id)) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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

    @State private var selectedMemberProfile: UserProfile?
    @State private var showProfileDetail = false

    private enum Slot: Identifiable {
        case member(GroupMember)
        case available(Int)

        var id: String {
            switch self {
            case .member(let m): return m.id.uuidString
            case .available(let i): return "available-\(i)"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primaryText)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                    Text(group.meetingTime)
                }
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
            }

            Divider()

            HStack(alignment: .center, spacing: 4) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(leftSlots) { slot in attendeeRow(for: slot) }
                }

                if !rightSlots.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(rightSlots) { slot in attendeeRow(for: slot) }
                    }
                }

                VStack(spacing: 12) {
                    Spacer(minLength: 0)

                    Button {
                        if hasJoined {
                            onLeaveTapped()
                        } else if !group.isFull {
                            onJoinTapped()
                        }
                    } label: {
                        Text(actionTitle)
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 80, height: 36)
                            .background(actionBackground)
                            .foregroundStyle(actionForeground)
                            .clipShape(Capsule())
                    }
                    .disabled(group.isFull && !hasJoined)
                    .buttonStyle(.plain)

                    Text("Max. \(group.maxCapacity) People")
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .multilineTextAlignment(.center)

                    Spacer(minLength: 0)
                }
                .frame(width: 100)
            }
        }
        .padding(14)
        .background(Color(UIColor.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture { onCardTapped() }
    }

    // MARK: Helpers

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

    private var slots: [Slot] {
        (0..<group.maxCapacity).map { i in
            i < group.members.count ? .member(group.members[i]) : .available(i)
        }
    }

    private var leftSlots: [Slot] { Array(slots.prefix(3)) }
    private var rightSlots: [Slot] { Array(slots.dropFirst(3)) }

    private func firstName(for fullName: String) -> String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }

    private func firstInitial(for fullName: String) -> String {
        String(fullName.split(separator: " ").first?.prefix(1) ?? "")
    }

    @ViewBuilder
    private func attendeeRow(for slot: Slot) -> some View {
        switch slot {
        case .member(let member):
            HStack(spacing: 10) {
                Circle()
                    .fill(memberColor(for: member.color))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(firstInitial(for: member.name))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    )

                Text(firstName(for: member.name))
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
            .onTapGesture {
                selectedMemberProfile = UserProfile.profile(for: member.name)
                showProfileDetail = true
            }

        case .available:
            HStack {
                Text("Available")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
            .background(Color(UIColor.systemGray5))
            .overlay(Capsule().stroke(Color(UIColor.systemGray3), lineWidth: 1.5))
            .clipShape(Capsule())
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
    @State private var address: String
    @State private var date: Date
    @State private var meetingTime: String
    @State private var maxCapacity: Int
    @State private var price: String

    let onCreate: (String, String, Date, String, Int, String) -> Void

    init(
        selectedDate: Date,
        defaultName: String = "New Meetup",
        defaultAddress: String,
        onCreate: @escaping (String, String, Date, String, Int, String) -> Void
    ) {
        _name = State(initialValue: defaultName)
        _address = State(initialValue: defaultAddress)
        _date = State(initialValue: selectedDate)
        _meetingTime = State(initialValue: "09:00 - 11:00 GMT+8")
        _maxCapacity = State(initialValue: 5)
        _price = State(initialValue: "Rp0")
        self.onCreate = onCreate
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    field(title: "Name", placeholder: "Meetup name", text: $name)
                    field(title: "Meeting Point", placeholder: "Address", text: $address)

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
                        Text("Capacity")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.secondaryText)

                        Stepper("\(maxCapacity) people", value: $maxCapacity, in: 2...8)
                            .font(.body)
                            .foregroundStyle(AppColors.primaryText)
                    }

                    field(title: "Price", placeholder: "Rp0", text: $price)
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
                            trimmed(name), trimmed(address), date,
                            trimmed(meetingTime), maxCapacity, trimmed(price)
                        )
                        dismiss()
                    }
                    .disabled(!canCreate)
                }
            }
        }
    }

    private var canCreate: Bool {
        !trimmed(name).isEmpty && !trimmed(address).isEmpty
            && !trimmed(meetingTime).isEmpty && !trimmed(price).isEmpty
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
}

struct GroupDetailView: View {
    let group: ActivityGroup
    let hasJoined: Bool
    // Uses parent's pendingConfirmation so the same full-screen popup appears
    @Binding var pendingConfirmation: ActivityGroupsView.PendingConfirmation?
    let openChat: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(group.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Label(group.meetingTime, systemImage: "clock")
                Label(group.address, systemImage: "mappin")
                Label("\(group.members.count)/\(group.maxCapacity) Participants", systemImage: "person.3")

                Divider()

                Text("Participants").font(.headline)
                ForEach(group.members) { member in Text(member.name) }

                Divider()

                if hasJoined {
                    Button("Leave Meetup") {
                        withAnimation { pendingConfirmation = .leave(group) }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Open Group Chat") { openChat() }

                } else {
                    Button("Join Meetup") {
                        guard !group.isFull else { return }
                        withAnimation { pendingConfirmation = .join(group) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(group.isFull)

                    if group.isFull {
                        Text("This meetup is full")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Meetup")
        .navigationBarTitleDisplayMode(.inline)
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
