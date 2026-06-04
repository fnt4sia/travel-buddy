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
    case localFood = "Local Food"
    case cafes = "Cafes"
    case dessert = "Dessert"
    case nature = "Nature"
    case culture = "Culture"
    case activities = "Activities"

    var icon: String {
        switch self {
        case .localFood: return "fork.knife"
        case .cafes: return "cup.and.saucer.fill"
        case .dessert: return "birthday.cake.fill"
        case .nature: return "leaf"
        case .culture: return "building.columns.fill"
        case .activities: return "figure.hiking"
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
    let photoURLs: [URL]
    let primaryTypeName: String?
    let priceLevel: String?
    let businessStatus: String?
    let isOpenNow: Bool?
    let types: [String]

    var photoURL: URL? {
        photoURLs.first
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        address: String,
        description: String,
        coordinate: CLLocationCoordinate2D,
        category: PlaceCategory,
        rating: Double? = nil,
        userRatingCount: Int? = nil,
        photoURLs: [URL] = [],
        primaryTypeName: String? = nil,
        priceLevel: String? = nil,
        businessStatus: String? = nil,
        isOpenNow: Bool? = nil,
        types: [String] = []
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.description = description
        self.coordinate = coordinate
        self.category = category
        self.rating = rating
        self.userRatingCount = userRatingCount
        self.photoURLs = photoURLs
        self.primaryTypeName = primaryTypeName
        self.priceLevel = priceLevel
        self.businessStatus = businessStatus
        self.isOpenNow = isOpenNow
        self.types = types
    }
}
