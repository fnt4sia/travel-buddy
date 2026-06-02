//
//  LocationPermissionViewModel.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//


import CoreLocation
import Combine

@MainActor
class LocationPermissionViewModel: ObservableObject {
    @Published var city: String?
    @Published var isLoading = false
    @Published var navigateToConfirm = false
    @Published var location: CLLocation?
    @Published var globeLocation: CLLocation?

    private let locationService: LocationService
    private var resolvedLocation: CLLocation?

    init(locationService: LocationService = .shared) {
        self.locationService = locationService
    }

    func allowLocationTapped() async {
        isLoading = true
        do {
            let location = try await locationService.requestPermissionAndLocation()
            print("[DEBUG] Location obtained in ViewModel: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            resolvedLocation = location
            self.location = location

            // Persist coordinates so the map can center on the user right away.
            UserDefaults.standard.set(location.coordinate.latitude, forKey: "userLat")
            UserDefaults.standard.set(location.coordinate.longitude, forKey: "userLng")

            let geocodedCity = await GeocodingService.cityName(for: location)
            print("[DEBUG] Geocoded city: \(geocodedCity)")
            city = geocodedCity

            let countryLocation = await GeocodingService.countryLocation(for: location)
            globeLocation = countryLocation ?? location
            navigateToConfirm = true
        } catch {
            print("[DEBUG] Location error: \(error)")
        }
        isLoading = false
    }
}
