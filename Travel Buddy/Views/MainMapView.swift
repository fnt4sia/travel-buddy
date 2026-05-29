//
//  MainMapView.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 29/05/26.
//

import SwiftUI
import MapKit

struct PlaceAnnotation: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let category: PlaceCategory
    let imageName: [String]
}

enum PlaceCategory: String, CaseIterable {
    case activities = "activities"
    case food       = "food"
    case nature     = "nature"

    var icon: String {
        switch self {
        case .activities: return "figure.hiking"
        case .food:       return "fork.knife"
        case .nature:     return "leaf"
        }
    }
}

// da dummy
extension PlaceAnnotation {
    static let sampleData: [PlaceAnnotation] = [
        PlaceAnnotation(
            name: "Ubud Monkey Forest",
            address: "Jl. Monkey Forest, Ubud, Kecamatan Ubud, Kabupaten Gianyar, Bali 80571, Indonesia",
            description: "The sanctuary is a popular tourist attraction. It includes numerous species of plants and trees as well as three temples and numerous visitor facilities. The forest lies within the village of Padangtegal and is managed by Mandala Suci Wenara Wana Management.",
            coordinate: CLLocationCoordinate2D(latitude: -8.5195, longitude: 115.2622),
            category: .nature,
            imageName: ["monkey-forest"]
        ),
        PlaceAnnotation(
            name: "Tegallalang Rice Terraces",
            address: "Tegallalang, Kecamatan Tegallalang, Kabupaten Gianyar, Bali, Indonesia",
            description: "Iconic terraced rice paddies carved into the hillsides north of Ubud, maintained by a traditional Balinese cooperative irrigation system known as subak, a UNESCO-listed cultural landscape.",
            coordinate: CLLocationCoordinate2D(latitude: -8.4394, longitude: 115.2799),
            category: .nature,
            imageName: ["rice-field"]
        ),
        PlaceAnnotation(
            name: "Apple Developer Academy",
            address: "Park23 Creative Hub, Jl. Kediri 1st floor, Tuban, Kuta, Badung Regency, Bali 80361",
            description: "A world-class coding and design academy empowering students to build apps for the Apple ecosystem.",
            coordinate: CLLocationCoordinate2D(latitude: -8.6259257, longitude: 115.1576691),
            category: .activities,
            imageName: ["apple-dev"]
        )
    ]
}

struct ThumbnailAnnotationView: View {
    let imageName: String
    let isSelected: Bool

    private let size: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(isSelected ? 0.35 : 0.2),
                            radius: isSelected ? 8 : 4, x: 0, y: 2)

                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .padding(4)
                    .foregroundStyle(AppColors.accent)
            }
            .frame(width: size, height: size)
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

            Triangle()
                .fill(Color.white)
                .frame(width: 14, height: 8)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
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

struct PlaceholderImage: View {
    let imageName: String
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
            Image(imageName)
                .resizable()
                .scaledToFill()
                .foregroundStyle(AppColors.accent.opacity(0.6))
        }
    }
}

struct PlaceDetailSheet: View {
    let place: PlaceAnnotation
    @StateObject private var groupsViewModel = GroupsViewModel()
    @State private var showDatePicker = false
    @State private var searchPerformed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color(UIColor.separator))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Place Details
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

                    // category badge
                    Label(place.category.rawValue.capitalized, systemImage: place.category.icon)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppColors.accent.opacity(0.12))
                        .foregroundStyle(AppColors.accent)
                        .clipShape(Capsule())
                        .padding(.horizontal, 20)

                    // for image
                    TabView {
                        ForEach(place.imageName, id: \.self) { sym in
                            PlaceholderImage(imageName: sym)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .padding(.horizontal, 20)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: 200)

                    // description text
                    Text(place.description)
                        .font(.body)
                        .foregroundStyle(AppColors.primaryText.opacity(0.85))
                        .lineSpacing(4)
                        .padding(.horizontal, 20)

                    // Available Meetups Section
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available Meetups")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.primaryText)
                            
                            if searchPerformed && !groupsViewModel.availableGroups.isEmpty {
                                Text(groupsViewModel.selectedDate.formatted(date: .long, time: .omitted))
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.primaryText)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Date Picker Section
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Button(action: { showDatePicker = true }) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundStyle(AppColors.accent)
                                        Text(searchPerformed ? groupsViewModel.selectedDate.formatted(date: .abbreviated, time: .omitted) : "Select your available date")
                                            .foregroundStyle(AppColors.primaryText)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(20)
                                }

                                Button(action: {
                                    searchPerformed = true
                                    groupsViewModel.searchGroups(for: groupsViewModel.selectedDate)
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
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Groups List
                        if searchPerformed {
                            if groupsViewModel.availableGroups.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 20))
                                        .foregroundStyle(AppColors.secondaryText)
                                    Text("No groups available")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(groupsViewModel.availableGroups) { group in
                                        GroupRowView(
                                            group: group,
                                            hasJoined: groupsViewModel.hasJoinedGroup(group),
                                            onJoinTapped: {
                                                groupsViewModel.joinGroup(group)
                                            },
                                            onLeaveTapped: {
                                                groupsViewModel.leaveGroup(group)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppColors.accent)
                                Text("Select a date to see groups")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheetContent(isPresented: $showDatePicker, selectedDate: $groupsViewModel.selectedDate)
                .presentationDetents([.height(500)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $groupsViewModel.showGroupConfirmation) {
            if let group = groupsViewModel.selectedGroup {
                GroupConfirmationView(group: group)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }
    }
}

struct FilterMenuView: View {
    @Binding var selectedFilter: PlaceCategory?
    @Binding var isShowing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(PlaceCategory.allCases, id: \.self) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = (selectedFilter == category) ? nil : category
                        isShowing = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: category.icon)
                            .frame(width: 20)
                            .foregroundStyle(
                                selectedFilter == category ? AppColors.accent : AppColors.secondaryText
                            )
                        Text(category.rawValue)
                            .font(.body)
                            .foregroundStyle(
                                selectedFilter == category ? AppColors.accent : AppColors.primaryText
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

struct MainMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -8.5069, longitude: 115.2624),
        span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
    )
    @State private var selectedPlace: PlaceAnnotation? = nil
    @State private var showFilterMenu = false
    @State private var selectedFilter: PlaceCategory? = nil
    @State private var locationName: String = UserDefaults.standard.string(forKey: "userCity") ?? "Ubud"

    private var visibleAnnotations: [PlaceAnnotation] {
        guard let filter = selectedFilter else { return PlaceAnnotation.sampleData }
        return PlaceAnnotation.sampleData.filter { $0.category == filter }
    }

    var body: some View {
        ZStack(alignment: .top) {
    
            Map(coordinateRegion: $region,
                interactionModes: .all,
                annotationItems: visibleAnnotations) { place in
                MapAnnotation(coordinate: place.coordinate) {
                    ThumbnailAnnotationView(
                        imageName: place.imageName.first ?? "mappin",
                        isSelected: selectedPlace?.id == place.id
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selectedPlace = (selectedPlace?.id == place.id) ? nil : place
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation { selectedPlace = nil }
            }

            VStack(spacing: 0) {
                headerOverlay
                Spacer()
            }

            if showFilterMenu {
                VStack {
                    HStack {
                        Spacer()
                        FilterMenuView(selectedFilter: $selectedFilter, isShowing: $showFilterMenu)
                            .padding(.top, 72)
                            .padding(.trailing, 16)
                    }
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)))
                .zIndex(10)
                .onTapGesture { withAnimation { showFilterMenu = false } }
            }
        }

        .sheet(item: $selectedPlace) { place in
            PlaceDetailSheet(place: place)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
        }
        .animation(.easeInOut(duration: 0.25), value: showFilterMenu)
    }


    private var headerOverlay: some View {
        HStack(alignment: .center) {
            HStack(spacing: 0) {
                Text("You're in ")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primaryText)
                Text(locationName)
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
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(selectedFilter != nil ? AppColors.accent : AppColors.primaryText)
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
}

#Preview {
    MainMapView()
}
