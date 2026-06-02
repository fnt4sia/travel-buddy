import SwiftUI

struct ActivityGroupsView: View {
    @StateObject private var viewModel = GroupsViewModel()
    @State private var showDatePicker = false
    @State private var searchPerformed = false

    var body: some View {
        VStack(spacing: 16) {
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
                                    date: .abbreviated,
                                    time: .omitted
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

                    Button(action: {
                        searchPerformed = true
                        viewModel.searchGroups(for: viewModel.selectedDate)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
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
            .padding(.horizontal, 16)
            .padding(.top, 16)

            if searchPerformed {
                if viewModel.availableGroups.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundStyle(AppColors.secondaryText)
                        Text("No groups available")
                            .font(.body)
                            .foregroundStyle(AppColors.secondaryText)
                        Text("Try selecting a different date")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(viewModel.availableGroups) { group in
                                GroupRowView(
                                    group: group,
                                    hasJoined: viewModel.hasJoinedGroup(group),
                                    onJoinTapped: {
                                        viewModel.joinGroup(group)
                                    },
                                    onLeaveTapped: {
                                        viewModel.leaveGroup(group)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 32))
                        .foregroundStyle(AppColors.accent)
                    Text("Select a date and search")
                        .font(.body)
                        .foregroundStyle(AppColors.secondaryText)
                    Text("to find available groups")
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            }

            Spacer()
        }
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheetContent(
                isPresented: $showDatePicker,
                selectedDate: $viewModel.selectedDate
            )
            .presentationDetents([.height(500)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showGroupConfirmation) {
            if let group = viewModel.selectedGroup {
                GroupConfirmationView(group: group)
            }
        }
    }
}

struct GroupRowView: View {
    let group: ActivityGroup
    let hasJoined: Bool
    let onJoinTapped: () -> Void
    let onLeaveTapped: () -> Void
    @State private var showLeaveConfirmation = false
    @State private var pendingAction: PendingAction?
    @State private var selectedMemberProfile: UserProfile?
    @State private var showProfileDetail = false

    private enum PendingAction {
        case join
        case leave
    }

    private enum Slot: Identifiable {
        case member(GroupMember)
        case available

        var id: String {
            switch self {
            case .member(let member):
                return member.id.uuidString
            case .available:
                return UUID().uuidString
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 4) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(leftSlots) { slot in
                        attendeeRow(for: slot)
                    }
                }

                if !rightSlots.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(rightSlots) { slot in
                            attendeeRow(for: slot)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Spacer(minLength: 0)

                    Button(action: {
                        withAnimation(
                            .spring(response: 0.35, dampingFraction: 0.75)
                        ) {
                            if hasJoined {
                                pendingAction = .leave
                            } else if !group.isFull {
                                pendingAction = .join
                            }
                        }
                    }) {
                        Text(actionTitle)
                            .font(.system(size: 18, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(width: 80, height: 36)
                            .background(actionBackground)
                            .foregroundStyle(actionForeground)
                            .clipShape(Capsule())
                            .shadow(
                                color: .black.opacity(0.18),
                                radius: 14,
                                x: 0,
                                y: 8
                            )
                    }
                    .disabled(group.isFull && !hasJoined)

                    Text("Max. \(group.maxCapacity) People")
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .frame(maxWidth: .infinity)

                    Spacer(minLength: 0)
                }
                .frame(width: 100)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .background(Color(UIColor.systemBackground))
        .border(Color(UIColor.separator), width: 1.5)
        .cornerRadius(16)
        .sheet(isPresented: $showProfileDetail) {
            if let profile = selectedMemberProfile {
                ProfileDetailView(profile: profile)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }
        .sheet(isPresented: $showLeaveConfirmation) {
            LeaveGroupConfirmationView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .overlay {
            if let pendingAction {
                GroupActionConfirmationPopup(
                    title: pendingAction == .join
                        ? "Do you want to join this group?"
                        : "Do you want to leave this group?",
                    message: pendingAction == .join
                        ? "Others can see your profile once you join."
                        : "You will be removed from the attendee list.",
                    cancelTitle: "No",
                    confirmTitle: pendingAction == .join ? "Yes" : "Leave",
                    onCancel: {
                        withAnimation(
                            .spring(response: 0.35, dampingFraction: 0.75)
                        ) {
                            self.pendingAction = nil
                        }
                    },
                    onConfirm: {
                        withAnimation(
                            .spring(response: 0.35, dampingFraction: 0.75)
                        ) {
                            self.pendingAction = nil
                        }
                        if pendingAction == .join {
                            onJoinTapped()
                        } else {
                            onLeaveTapped()

                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.2
                            ) {
                                showLeaveConfirmation = true
                            }
                        }
                    }
                )
                .scaleEffect(1.0)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.8)
                            .combined(with: .opacity),
                        removal: .scale(scale: 0.9)
                            .combined(with: .opacity)
                    )
                )
            }
        }
    }

    private var actionTitle: String {
        if hasJoined { return "Leave" }
        if group.isFull { return "Full" }
        return "Join"
    }

    private var actionBackground: Color {
        if hasJoined { return Color.red.opacity(0.9)}
        if group.isFull { return Color.gray.opacity(0.28) }
        return AppColors.accent
    }

    private var actionForeground: Color {
        if hasJoined { return .white }
        if group.isFull { return .gray }
        return .white
    }

    private func firstName(for fullName: String) -> String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }

    private var slots: [Slot] {
        (0..<group.maxCapacity).map { index in
            if index < group.members.count {
                return .member(group.members[index])
            } else {
                return .available
            }
        }
    }

    private var leftSlots: [Slot] {
        switch group.maxCapacity {
        case 4:
            return Array(slots.prefix(2))
        default:
            return Array(slots.prefix(min(3, slots.count)))
        }
    }

    private var rightSlots: [Slot] {
        switch group.maxCapacity {
        case 4:
            return Array(slots.dropFirst(2))
        default:
            return Array(slots.dropFirst(3))
        }
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
            .overlay(
                Capsule()
                    .stroke(Color(UIColor.systemGray3), lineWidth: 1.5)
            )
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
            .overlay(
                Capsule()
                    .stroke(Color(UIColor.systemGray3), lineWidth: 1.5)
            )
            .clipShape(Capsule())
        }
    }

    private func memberColor(for colorName: String) -> Color {
        switch colorName {
        case "blue": return Color.blue
        case "green": return Color.green
        case "purple": return Color.purple
        case "orange": return Color.orange
        case "red": return Color.red
        case "yellow": return Color.yellow
        case "cyan": return Color.cyan
        case "teal": return AppColors.accent
        default: return Color.gray
        }
    }

    private func firstInitial(for fullName: String) -> String {
        String(fullName.split(separator: " ").first?.prefix(1) ?? "")
    }
}

struct LeaveGroupConfirmationView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.red,
                        Color.red.opacity(0.8),
                    ]
                ),
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
                                Image(
                                    systemName: "person.crop.circle.badge.minus"
                                )
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

                        Text(
                            "Your reservation has been cancelled and you have been removed from the attendee list."
                        )
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
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
        .frame(maxWidth: UIScreen.main.bounds.width * 0.85)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 12)
        .padding(.horizontal, 20)
    }
}

struct JoinGroupConfirmationPopup: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text("Do you want to join this group?")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primaryText)

                Text("Others can see your profile once you join.")
                    .font(.body)
                    .foregroundStyle(AppColors.secondaryText)

                HStack(spacing: 10) {
                    Button(action: onCancel) {
                        Text("No")
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(UIColor.systemGray5))
                            .foregroundStyle(AppColors.primaryText)
                            .clipShape(Capsule())
                    }

                    Button(action: onConfirm) {
                        Text("Yes")
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
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 12)
            .padding(.horizontal, 20)
        }
    }
}

struct GroupConfirmationView: View {
    let group: ActivityGroup
    @Environment(\.dismiss) var dismiss
    @State private var selectedMemberProfile: UserProfile?
    @State private var showProfileDetail = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.accent, AppColors.accent.opacity(0.8),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(AppColors.accent.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .offset(x: -60, y: -40)

                            Circle()
                                .fill(AppColors.accent.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .offset(x: 70, y: 50)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.accent)
                                            .frame(width: 75, height: 75)

                                        Image(systemName: "checkmark")
                                            .font(
                                                .system(size: 40, weight: .bold)
                                            )
                                            .foregroundStyle(.white)
                                    }
                                )
                        }
                        .frame(height: 180)

                        VStack(spacing: 8) {
                            Text("Your spot is confirmed!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text(group.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text(group.address)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(2)

                            Text(
                                group.date.formatted(
                                    date: .long,
                                    time: .omitted
                                )
                            )
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Other attendees:")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)

                            VStack(spacing: 10) {
                                ForEach(Array(group.members.prefix(3))) {
                                    member in
                                    Button(action: {
                                        selectedMemberProfile =
                                            UserProfile.profile(
                                                for: member.name
                                            )
                                        showProfileDetail = true
                                    }) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(
                                                    getColor(for: member.color)
                                                )
                                                .frame(width: 36, height: 36)
                                                .overlay(
                                                    Circle().stroke(
                                                        Color.white,
                                                        lineWidth: 1.5
                                                    )
                                                )

                                            Text(member.name)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.white)

                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            AppColors.accent.opacity(0.4)
                                        )
                                        .cornerRadius(12)
                                    }
                                }

                                if group.members.count > 3 {
                                    Button(action: {}) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(
                                                    AppColors.accent.opacity(
                                                        0.6
                                                    )
                                                )
                                                .frame(width: 36, height: 36)
                                                .overlay(
                                                    Circle().stroke(
                                                        Color.white,
                                                        lineWidth: 1.5
                                                    )
                                                )
                                                .overlay(
                                                    Text(
                                                        "+\(group.members.count - 3)"
                                                    )
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                )

                                            Text("More attendees")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.white)

                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            AppColors.accent.opacity(0.4)
                                        )
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding(.top, 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }

                VStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "message.fill")
                            Text("Go to Group Chat")
                        }
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.accent.opacity(0.3))
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }

                    Button(action: { dismiss() }) {
                        Text("Back to Main Page")
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .foregroundStyle(AppColors.primaryText)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .sheet(isPresented: $showProfileDetail) {
            if let profile = selectedMemberProfile {
                ProfileDetailView(profile: profile)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }
    }

    private func getColor(for colorName: String) -> Color {
        switch colorName {
        case "blue": return Color.blue
        case "green": return Color.green
        case "purple": return Color.purple
        case "orange": return Color.orange
        case "red": return Color.red
        case "yellow": return Color.yellow
        case "cyan": return Color.cyan
        case "teal": return AppColors.accent
        default: return Color.gray
        }
    }
}

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

            DatePicker(
                "Choose a date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
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
