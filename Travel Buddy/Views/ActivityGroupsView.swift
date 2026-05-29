import SwiftUI

struct ActivityGroupsView: View {
    @StateObject private var viewModel = GroupsViewModel()
    @State private var showDatePicker = false
    @State private var searchPerformed = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Date Picker Section
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
                            Text(viewModel.selectedDate.formatted(date: .abbreviated, time: .omitted))
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
            
            // Groups List
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
            DatePickerSheetContent(isPresented: $showDatePicker, selectedDate: $viewModel.selectedDate)
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
    @State private var showConfirmation = false
    @State private var selectedMemberProfile: UserProfile?
    @State private var showProfileDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Members grid
            VStack(alignment: .leading, spacing: 10) {
                // First row of members
                HStack(spacing: 10) {
                    ForEach(Array(group.members.prefix(2))) { member in
                        MemberBadge(member: member, onTapped: {
                            selectedMemberProfile = UserProfile.profile(for: member.name)
                            showProfileDetail = true
                        })
                    }
                    Spacer()
                }
                
                // Second row of members (if any)
                if group.members.count > 2 {
                    HStack(spacing: 10) {
                        ForEach(Array(group.members.dropFirst(2).prefix(2))) { member in
                            MemberBadge(member: member, onTapped: {
                                selectedMemberProfile = UserProfile.profile(for: member.name)
                                showProfileDetail = true
                            })
                        }
                        Spacer()
                    }
                }
                
                // Capacity info and status
                HStack {
                    Text("Max. \(group.maxCapacity) People")
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                    
                    Spacer()
                    
                    // Status and Join Button
                    HStack(spacing: 12) {
                        // Availability status
                        if !group.isFull {
                            Text("Available")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppColors.accent.opacity(0.2))
                                .foregroundStyle(AppColors.accent)
                                .cornerRadius(20)
                        }
                        
                        // Join/Full button
                        Button(action: {
                            if hasJoined {
                                onLeaveTapped()
                            } else {
                                showConfirmation = true
                            }
                        }) {
                            if group.isFull && !hasJoined {
                                Text("Full")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.3))
                                    .foregroundStyle(Color.gray)
                                    .cornerRadius(20)
                            } else if hasJoined {
                                Text("Joined")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundStyle(.green)
                                    .cornerRadius(20)
                            } else {
                                Text("Join")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(AppColors.accent)
                                    .foregroundStyle(.white)
                                    .cornerRadius(20)
                            }
                        }
                        .disabled(group.isFull && !hasJoined)
                    }
                }
            }
            .padding(12)
        }
        .padding(12)
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
        .confirmationDialog(
            "Group Confirmation",
            isPresented: $showConfirmation,
            presenting: group,
            actions: { _ in
                Button(role: .destructive, action: { showConfirmation = false }) {
                    Text("Cancel")
                }
                Button(action: {
                    showConfirmation = false
                    onJoinTapped()
                }) {
                    Text("Yes")
                }
            },
            message: { _ in
                Text("Do you want to join this group?")
            }
        )
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

struct MemberBadge: View {
    let member: GroupMember
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            HStack(spacing: 8) {
                Circle()
                    .fill(getColor(for: member.color))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .overlay(
                        Circle()
                            .fill(getColor(for: member.color))
                            .frame(width: 32, height: 32)
                    )
                
                Text(member.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.primaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(20)
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

struct GroupConfirmationView: View {
    let group: ActivityGroup
    @Environment(\.dismiss) var dismiss
    @State private var selectedMemberProfile: UserProfile?
    @State private var showProfileDetail = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [AppColors.accent, AppColors.accent.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Success checkmark with decorative elements
                        ZStack {
                            // Decorative circles
                            Circle()
                                .fill(AppColors.accent.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .offset(x: -60, y: -40)
                            
                            Circle()
                                .fill(AppColors.accent.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .offset(x: 70, y: 50)
                            
                            // Main checkmark
                            VStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        ZStack {
                                            Circle()
                                                .fill(AppColors.accent)
                                                .frame(width: 75, height: 75)
                                            
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 40, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    )
                            }
                        }
                        .frame(height: 180)
                        
                        // Success message
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
                            
                            Text(group.date.formatted(date: .long, time: .omitted))
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                        
                        // Other attendees section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Other attendees:")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            VStack(spacing: 10) {
                                ForEach(Array(group.members.prefix(3))) { member in
                                    Button(action: {
                                        selectedMemberProfile = UserProfile.profile(for: member.name)
                                        showProfileDetail = true
                                    }) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(getColor(for: member.color))
                                                .frame(width: 36, height: 36)
                                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                            
                                            Text(member.name)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.white)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(AppColors.accent.opacity(0.4))
                                        .cornerRadius(12)
                                    }
                                }
                                
                                if group.members.count > 3 {
                                    Button(action: {}) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(AppColors.accent.opacity(0.6))
                                                .frame(width: 36, height: 36)
                                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                                .overlay(
                                                    Text("+\(group.members.count - 3)")
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
                                        .background(AppColors.accent.opacity(0.4))
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
                
                // Action buttons
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
