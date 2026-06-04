import MapKit
import SwiftUI

// MARK: - Map annotation thumbnail

struct ThumbnailAnnotationView: View {
    let photoURL: URL?
    let category: PlaceCategory
    let isSelected: Bool

    private let size: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(isSelected ? 0.35 : 0.2),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: 2
                    )

                photo
                    .frame(width: size - 8, height: size - 8)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .frame(width: size, height: size)
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.6),
                value: isSelected
            )

            Triangle()
                .fill(Color.white)
                .frame(width: 14, height: 8)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }

    @ViewBuilder
    private var photo: some View {
        if let photoURL {
            AsyncImage(url: photoURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty:
                    ProgressView()
                default:
                    categoryIcon
                }
            }
        } else {
            categoryIcon
        }
    }

    private var categoryIcon: some View {
        Image(systemName: category.icon)
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(AppColors.accent)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Detail sheet
// Shows place info + inline meetup preview.
// "View Meetups" pushes ActivityGroupsView inside the same NavigationStack.

struct PlaceDetailSheet: View {
    let place: PlaceAnnotation

    @StateObject private var groupsViewModel = GroupsViewModel()
    @State private var showDatePicker = false
    @State private var showCreateMeetup = false

    // Route enum lives here so the NavigationStack can push ActivityGroupsView
    enum PlaceRoute: Hashable {
        case meetups
        case detail(UUID)
        case chat(UUID)
    }
    @State private var path: [PlaceRoute] = []

    // Confirmation popup — full-screen so it overlays the whole sheet
    enum PendingConfirmation { case join(ActivityGroup), leave(ActivityGroup) }
    @State private var pendingConfirmation: PendingConfirmation?

    var body: some View {
        // Drag indicator sits outside the NavigationStack so it
        // stays visible even after pushing a child page
        ZStack {
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color(UIColor.separator))
                    .frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                NavigationStack(path: $path) {
                    placeDetailContent
                        .navigationDestination(for: PlaceRoute.self) { route in
                            switch route {

                            case .meetups:
                                ActivityGroupsView(place: place)

                            case .detail(let groupID):
                                if let group = MeetupStore.shared.group(with: groupID) {
                                    GroupDetailView(
                                        group: group,
                                        hasJoined: groupsViewModel.hasJoinedGroup(group),
                                        pendingConfirmation: .constant(nil),
                                        openChat: {
                                            path.append(.chat(groupID))
                                        }
                                    )
                                }

                            case .chat(let groupID):
                                GroupChatView(groupID: groupID, showsCloseButton: false)
                            }
                        }
                }
            }
            .background(Color(UIColor.systemBackground))

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
                            if let joined = groupsViewModel.joinGroup(group) {
                                path = [.chat(joined.id)]
                            }
                        case .leave(let group):
                            groupsViewModel.leaveGroup(group)
                        }
                    }
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheetContent(
                isPresented: $showDatePicker,
                selectedDate: $groupsViewModel.selectedDate
            )
            .presentationDetents([.height(500)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCreateMeetup) {
            CreateMeetupSheet(
                selectedDate: groupsViewModel.selectedDate,
                defaultName: "\(place.name) Meetup",
                defaultAddress: place.address,
                defaultDescription: "Explore \(place.name), meet new people, and keep the plan flexible for the group.",
                onCreate: { name, description, address, date, meetingTime, maxCapacity in
                    if let created = groupsViewModel.createGroup(
                        name: name,
                        description: description,
                        address: address,
                        date: date,
                        meetingTime: meetingTime,
                        maxCapacity: maxCapacity
                    ) {
                        path = [.chat(created.id)]
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert(item: $groupsViewModel.meetupConflict) { conflict in
            Alert(
                title: Text("Already joined here"),
                message: Text(conflict.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Place detail root page (no navigation bar)

    private var placeDetailContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                // Name + address
                VStack(alignment: .leading, spacing: 8) {
                    Text(place.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.primaryText)

                    Text(place.address)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(2)
                }
                .padding(.horizontal, 20)

                // Category badge
                Label(
                    place.category.rawValue.capitalized,
                    systemImage: place.category.icon
                )
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColors.accent.opacity(0.12))
                .foregroundStyle(AppColors.accent)
                .clipShape(Capsule())
                .padding(.horizontal, 20)

                // Photo
                AsyncImage(url: place.photoURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ZStack {
                        Color(UIColor.secondarySystemBackground)
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(AppColors.accent)
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

                // Description
                Text(place.description)
                    .font(.body)
                    .foregroundStyle(AppColors.primaryText.opacity(0.85))
                    .lineSpacing(4)
                    .padding(.horizontal, 20)

                // ── Inline meetup section ──────────────────────────────

                VStack(alignment: .leading, spacing: 12) {

                    // Section header + "View All" button
                    HStack {
                        Text("Available Meetups")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.primaryText)

                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    // Date + Create row
                    HStack(spacing: 12) {
                        Button(action: { showDatePicker = true }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(AppColors.accent)
                                Text(
                                    groupsViewModel.selectedDate.formatted(
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
                            HStack(spacing: 6) {
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
                    .padding(.horizontal, 20)

                    // Groups or empty state
                    if groupsViewModel.availableGroups.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 24))
                                .foregroundStyle(AppColors.secondaryText)
                            Text("No meetups for this date")
                                .font(.caption)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(groupsViewModel.availableGroups) { group in
                                GroupRowView(
                                    group: group,
                                    hasJoined: groupsViewModel.hasJoinedGroup(group),
                                    onJoinTapped: { withAnimation { pendingConfirmation = .join(group) } },
                                    onLeaveTapped: { withAnimation { pendingConfirmation = .leave(group) } },
                                    onCardTapped: { path.append(.detail(group.id)) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .padding(.top, 12)
        }
        .navigationBarHidden(true)
        .onAppear {
            groupsViewModel.refreshAvailableGroups()
        }
    }
}

// MARK: - Filter menu

struct FilterMenuView: View {
    @Binding var selectedFilter: PlaceCategory?
    @Binding var isShowing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(PlaceCategory.allCases, id: \.self) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter =
                            (selectedFilter == category) ? nil : category
                        isShowing = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: category.icon)
                            .frame(width: 20)
                            .foregroundStyle(
                                selectedFilter == category
                                    ? AppColors.accent : AppColors.secondaryText
                            )
                        Text(category.rawValue)
                            .font(.body)
                            .foregroundStyle(
                                selectedFilter == category
                                    ? AppColors.accent : AppColors.primaryText
                            )
                        Spacer()
                        if selectedFilter == category {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                if category != PlaceCategory.allCases.last {
                    Divider().padding(.horizontal, 8)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 4)
        )
        .frame(width: 180)
    }
}

// MARK: - Main map

struct MainMapView: View {
    // onOpenChat removed — chat navigation is owned by ActivityGroupsView
    @StateObject private var viewModel = ExploreViewModel()

    @State private var selectedPlace: PlaceAnnotation? = nil
    @State private var showFilterMenu = false
    @State private var selectedFilter: PlaceCategory? = nil

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $viewModel.cameraPosition) {
                UserAnnotation()

                ForEach(viewModel.places) { place in
                    Annotation("", coordinate: place.coordinate) {
                        ThumbnailAnnotationView(
                            photoURL: place.photoURL,
                            category: place.category,
                            isSelected: selectedPlace?.id == place.id
                        )
                        .onTapGesture {
                            withAnimation(
                                .spring(response: 0.35, dampingFraction: 0.7)
                            ) {
                                selectedPlace =
                                    (selectedPlace?.id == place.id)
                                    ? nil : place
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation { selectedPlace = nil }
            }

            VStack(spacing: 0) {
                headerOverlay
                if viewModel.isLoading {
                    loadingPill
                } else if let message = viewModel.errorMessage {
                    messagePill(message)
                }
                Spacer()
            }

            if showFilterMenu {
                VStack {
                    HStack {
                        Spacer()
                        FilterMenuView(
                            selectedFilter: $selectedFilter,
                            isShowing: $showFilterMenu
                        )
                        .padding(.top, 72)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }
                .transition(
                    .opacity.combined(
                        with: .scale(scale: 0.9, anchor: .topTrailing)
                    )
                )
                .zIndex(10)
                .onTapGesture { withAnimation { showFilterMenu = false } }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    recenterButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 120)
                }
            }
        }
        .task {
            await viewModel.start(filter: selectedFilter)
        }
        .onChange(of: selectedFilter) { _, newValue in
            Task { await viewModel.loadPlaces(filter: newValue) }
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetailSheet(place: place)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
        }
        .animation(.easeInOut(duration: 0.25), value: showFilterMenu)
    }

    // MARK: - Overlays

    private var headerOverlay: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text("You're in ")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primaryText)
                Text(viewModel.locationName)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.accent)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showFilterMenu.toggle()
                    if showFilterMenu { selectedPlace = nil }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.systemBackground).opacity(0.9))
                        .frame(width: 40, height: 40)
                        .shadow(
                            color: .black.opacity(0.12),
                            radius: 6,
                            x: 0,
                            y: 2
                        )

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            selectedFilter != nil
                                ? AppColors.accent : AppColors.primaryText
                        )
                }
            }
            .overlay(alignment: .topTrailing) {
                if selectedFilter != nil {
                    Circle()
                        .fill(AppColors.accent)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            Color(UIColor.systemBackground)
                .opacity(0.88)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
    }

    private var loadingPill: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("Finding great spots near you…")
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Color(UIColor.systemBackground).opacity(0.95),
            in: Capsule()
        )
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        .padding(.top, 12)
    }

    private func messagePill(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(AppColors.secondaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Color(UIColor.systemBackground).opacity(0.95),
                in: Capsule()
            )
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
            .padding(.top, 12)
    }

    private var recenterButton: some View {
        Button {
            viewModel.recenterOnUser()
        } label: {
            ZStack {
                Circle()
                    .fill(Color(UIColor.systemBackground).opacity(0.95))
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
                Image(systemName: "location.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppColors.accent)
            }
        }
    }
}

#Preview {
    MainMapView()
}
