//
//  LocationService.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//


import CoreLocation
import Combine

final class LocationService: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = LocationService()
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermissionAndLocation() async throws -> CLLocation {
        let status = manager.authorizationStatus
        
        // Check current authorization status
        if status == .notDetermined {
            // Request permission first
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            // Already authorized, get location directly
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                manager.requestLocation()
            }
        } else {
            // Permission denied or restricted
            throw NSError(domain: "LocationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location permission denied"])
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            // Permission granted, now request location
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            // Permission denied
            let error = NSError(domain: "LocationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location permission denied"])
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        print("[DEBUG] Location received: \(location.coordinate.latitude), \(location.coordinate.longitude) - Accuracy: \(location.horizontalAccuracy)m")
        continuation?.resume(returning: location)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
