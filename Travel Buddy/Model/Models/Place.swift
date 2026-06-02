//
//  Place.swift
//  Travel Buddy
//
//  Domain model for a place shown on the map. Populated from the Google Places API
//  (see PlacesService) instead of static sample data.
//

import CoreLocation
import Foundation

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

struct PlaceAnnotation: Identifiable {
    let id: String
    let name: String
    let address: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let category: PlaceCategory
    let rating: Double?
    let userRatingCount: Int?
    let photoURL: URL?

    init(
        id: String = UUID().uuidString,
        name: String,
        address: String,
        description: String,
        coordinate: CLLocationCoordinate2D,
        category: PlaceCategory,
        rating: Double? = nil,
        userRatingCount: Int? = nil,
        photoURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.description = description
        self.coordinate = coordinate
        self.category = category
        self.rating = rating
        self.userRatingCount = userRatingCount
        self.photoURL = photoURL
    }
}
