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

    private let locationService: LocationService
    private var resolvedLocation: CLLocation?

    init(locationService: LocationService = .shared) {
        self.locationService = locationService
    }

    func allowLocationTapped() async {
        isLoading = true
        do {
            let location = try await locationService.requestPermissionAndLocation()
            resolvedLocation = location

            city = await GeocodingService.cityName(for: location)
            navigateToConfirm = true
        } catch {
            print("Location error: \(error)")
        }
        isLoading = false
    }
}
