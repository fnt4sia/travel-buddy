//
//  GeocodingService.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//


import MapKit

final class GeocodingService {
    // ← moved from: transitionToWelcomeScreen (the CLGeocoder part)
    static func cityName(for location: CLLocation) async -> String {
        let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location)
        return placemarks?.first?.locality ?? "your city"
    }
}
