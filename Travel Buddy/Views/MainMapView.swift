import MapKit
import SwiftUI

struct MainMapView: View {
    private static let ubudCoordinate = CLLocationCoordinate2D(latitude: -8.5069, longitude: 115.2625)
    private let spots = TravelSpot.ubudSamples

    @State private var cameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: MainMapView.ubudCoordinate,
            distance: 26000,
            heading: 0,
            pitch: 0
        )
    )
    @State private var cameraDistance: CLLocationDistance = 26000
    @State private var selectedCategory: TravelSpotCategory?
    @State private var selectedSpot: TravelSpot?
    @State private var showsFilter = false

    private var showsSpotMarkers: Bool {
        cameraDistance < 11000
    }

    private var filteredSpots: [TravelSpot] {
        guard let selectedCategory = selectedCategory else { return spots }
        return spots.filter { $0.category == selectedCategory }
    }

    private var visibleSpots: [TravelSpot] {
        showsSpotMarkers ? filteredSpots : []
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, interactionModes: .all) {
                ForEach(visibleSpots) { spot in
                    Annotation("", coordinate: spot.coordinate, anchor: .bottom) {
                        Button {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                                selectedSpot = spot
                                showsFilter = false
                            }
                        } label: {
                            SpotMapMarker(
                                spot: spot,
                                isSelected: selectedSpot?.id == spot.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .ignoresSafeArea()
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .onMapCameraChange(frequency: .continuous) { context in
                cameraDistance = context.camera.distance
            }

            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    titleView

                    Spacer()

                    filterButton
                        .overlay(alignment: .topTrailing) {
                            if showsFilter {
                                filterMenu
                                    .offset(y: 58)
                                    .transition(.scale(scale: 0.92, anchor: .topTrailing).combined(with: .opacity))
                            }
                        }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                Spacer()
            }

            if selectedSpot != nil {
                Color.black.opacity(0.36)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
                            selectedSpot = nil
                        }
                    }
            }

            if let selectedSpot = selectedSpot {
                VStack {
                    Spacer()

                    SpotDetailSheet(spot: selectedSpot)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var titleView: some View {
        HStack(spacing: 0) {
            Text("You're in ")
                .foregroundColor(.black)

            Text("Ubud")
                .foregroundColor(.teal)
        }
        .font(.system(size: 34, weight: .bold))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .padding(.top, 8)
        .shadow(color: .white.opacity(0.85), radius: 16, x: 0, y: 8)
    }

    private var filterButton: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                showsFilter.toggle()
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.92), in: Circle())
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    private var filterMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    selectedCategory = nil
                    showsFilter = false
                }
            } label: {
                filterRow("all", isSelected: selectedCategory == nil)
            }

            ForEach(TravelSpotCategory.allCases) { category in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        selectedCategory = category
                        showsFilter = false
                    }
                } label: {
                    filterRow(category.rawValue, isSelected: selectedCategory == category)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 10)
        .frame(width: 188, alignment: .leading)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 28, x: 0, y: 16)
    }

    private func filterRow(_ title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .teal : .black)

            Spacer()
        }
        .frame(height: 44)
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
    }
}

private struct SpotMapMarker: View {
    let spot: TravelSpot
    let isSelected: Bool

    var body: some View {
        VStack(spacing: -2) {
            SpotImageView(url: spot.imageURL, category: spot.category)
                .frame(width: 78, height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white, lineWidth: 3)
                )

            PinTail()
                .fill(.white)
                .frame(width: 26, height: 18)
        }
        .shadow(color: .black.opacity(isSelected ? 0.24 : 0.14), radius: isSelected ? 18 : 12, x: 0, y: 8)
        .scaleEffect(isSelected ? 1.08 : 1)
    }
}

private struct SpotDetailSheet: View {
    let spot: TravelSpot

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.black.opacity(0.16))
                .frame(width: 44, height: 4)
                .padding(.top, 8)

            VStack(spacing: 4) {
                Text(spot.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)

                Text(spot.address)
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.54))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 24)
            }

            SpotImageView(url: spot.imageURL, category: spot.category)
                .frame(height: 244)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Capsule()
                    .fill(Color.teal)
                    .frame(width: 62, height: 3)
                Capsule()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 62, height: 3)
                Capsule()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 62, height: 3)
            }

            Text(spot.description)
                .font(.system(size: 14))
                .foregroundColor(.black)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 28, x: 0, y: -12)
    }
}

private struct SpotImageView: View {
    let url: URL
    let category: TravelSpotCategory

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure(_):
                fallback
            case .empty:
                fallback
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            @unknown default:
                fallback
            }
        }
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: fallbackColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: fallbackSymbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var fallbackColors: [Color] {
        switch category {
        case .activities:
            return [Color(red: 0.04, green: 0.55, blue: 0.64), Color(red: 0.94, green: 0.45, blue: 0.28)]
        case .food:
            return [Color(red: 0.86, green: 0.27, blue: 0.22), Color(red: 0.97, green: 0.74, blue: 0.33)]
        case .nature:
            return [Color(red: 0.18, green: 0.48, blue: 0.34), Color(red: 0.69, green: 0.78, blue: 0.54)]
        }
    }

    private var fallbackSymbol: String {
        switch category {
        case .activities:
            return "sparkles"
        case .food:
            return "fork.knife"
        case .nature:
            return "leaf.fill"
        }
    }
}

private struct PinTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct MainMapView_Previews: PreviewProvider {
    static var previews: some View {
        MainMapView()
    }
}
