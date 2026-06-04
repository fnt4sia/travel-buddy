//
//  ExploreViewModel.swift
//  Travel Buddy
//
//  Drives MainMapView: resolves the user's current location, centers the map on
//  it, and loads place recommendations from Google Places for the selected
//  category (or all categories when no filter is active).
//

import Combine
import CoreLocation
import MapKit
import SwiftUI

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var places: [PlaceAnnotation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var locationName: String
    @Published var cameraPosition: MapCameraPosition

    /// Best-known center for the map / place queries.
    private(set) var center: CLLocationCoordinate2D

    private let placesService: PlacesService
    private let locationService: LocationService

    // Badung fallback for development fixtures when nothing else is known.
    private static let fallbackCenter = CLLocationCoordinate2D(latitude: -8.6833, longitude: 115.1667)

    convenience init() {
        self.init(
            placesService: PlacesService.shared,
            locationService: LocationService.shared
        )
    }

    init(
        placesService: PlacesService,
        locationService: LocationService
    ) {
        self.placesService = placesService
        self.locationService = locationService

        let start = Self.savedCoordinate() ?? Self.fallbackCenter
        self.center = start
        self.cameraPosition = .region(Self.region(for: start))
        self.locationName = UserDefaults.standard.string(forKey: "userCity") ?? "Ubud"
    }

    // MARK: - Lifecycle

    /// Called when the map appears: refresh the live location, then load places.
    func start(filter: PlaceCategory?) async {
        await refreshLocation()
        await loadPlaces(filter: filter)
    }

    /// Re-center the map on the user's last known location.
    func recenterOnUser() {
        cameraPosition = .region(Self.region(for: center))
    }

    // MARK: - Location

    private func refreshLocation() async {
        do {
            let location = try await locationService.requestPermissionAndLocation()
            center = location.coordinate
            persist(location.coordinate)
            cameraPosition = .region(Self.region(for: center))

            let city = await GeocodingService.cityName(for: location)
            if city != "your city" {
                locationName = city
                UserDefaults.standard.set(city, forKey: "userCity")
            }
        } catch {
            // Keep the saved / fallback center; the map is still usable.
            print("[ExploreViewModel] location error: \(error.localizedDescription)")
        }
    }

    // MARK: - Places

    func loadPlaces(filter: PlaceCategory?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if let filter {
            do {
                places = try await placesService.recommendedPlaces(for: filter, near: center)
                if places.isEmpty {
                    errorMessage = "No \(filter.rawValue) spots found near you."
                }
            } catch {
                places = []
                errorMessage = error.localizedDescription
                print("[ExploreViewModel] places error: \(error)")
            }
        } else {
            // No filter: gather a few from each category concurrently. A failure in
            // one category shouldn't wipe out the others.
            async let nature = safeRecommend(.nature)
            async let localFood = safeRecommend(.localFood)
            async let cafes = safeRecommend(.cafes)
            async let culture = safeRecommend(.culture)
            async let activities = safeRecommend(.activities)
            let combined = await nature + localFood + cafes + culture + activities
            places = combined
            if combined.isEmpty {
                errorMessage = "Couldn't load places near you."
            }
        }
    }

    private func safeRecommend(_ category: PlaceCategory) async -> [PlaceAnnotation] {
        (try? await placesService.recommendedPlaces(for: category, near: center)) ?? []
    }

    // MARK: - Helpers

    private func persist(_ coordinate: CLLocationCoordinate2D) {
        UserDefaults.standard.set(coordinate.latitude, forKey: "userLat")
        UserDefaults.standard.set(coordinate.longitude, forKey: "userLng")
    }

    private static func savedCoordinate() -> CLLocationCoordinate2D? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: "userLat") != nil,
              defaults.object(forKey: "userLng") != nil else { return nil }
        let lat = defaults.double(forKey: "userLat")
        let lng = defaults.double(forKey: "userLng")
        guard lat != 0 || lng != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    private static func region(for center: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(center: center, latitudinalMeters: 9000, longitudinalMeters: 9000)
    }
}
