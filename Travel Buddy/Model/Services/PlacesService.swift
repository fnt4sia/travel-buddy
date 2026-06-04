//
//  PlacesService.swift
//  Travel Buddy
//
//  Place recommendations. During development this returns local fixtures for
//  Badung and Cupertino so the app does not spend Google Places API credits.

import CoreLocation
import Foundation

struct PlacesService {
    static let shared = PlacesService()

    private static let badungCenter = CLLocationCoordinate2D(latitude: -8.6558, longitude: 115.1354)
    private static let cupertinoCenter = CLLocationCoordinate2D(latitude: 37.3229, longitude: -122.0322)

    // MARK: - Public API

    /// Returns up to `pickCount` hardcoded places for the closest development region.
    func recommendedPlaces(
        for category: PlaceCategory,
        near center: CLLocationCoordinate2D,
        radius: Double = 8000,
        bestCount: Int = 10,
        pickCount: Int = 3
    ) async throws -> [PlaceAnnotation] {
        Self.developmentPlaces(
            for: category,
            near: center,
            pickCount: pickCount
        )
    }

    // MARK: - Ranking

    /// Bayesian weighted rating so that both the *average rating* and the
    /// *number of ratings* matter. A 5.0 with 3 reviews won't outrank a 4.6
    /// with thousands of reviews.
    ///
    ///   score = (v / (v + m)) * R + (m / (v + m)) * C
    ///
    /// where R = the place's rating, v = its rating count, C = the mean rating
    /// across all candidates, and m = a confidence threshold.
    static func rankedByRatingAndPopularity(_ places: [PlaceAnnotation]) -> [PlaceAnnotation] {
        let rated = places.filter { ($0.rating ?? 0) > 0 && ($0.userRatingCount ?? 0) > 0 }
        guard !rated.isEmpty else { return places }

        let m = 20.0
        let meanRating = rated.compactMap { $0.rating }.reduce(0, +) / Double(rated.count)

        func score(_ place: PlaceAnnotation) -> Double {
            let v = Double(place.userRatingCount ?? 0)
            let R = place.rating ?? 0
            return (v / (v + m)) * R + (m / (v + m)) * meanRating
        }

        return rated.sorted { score($0) > score($1) }
    }

    // MARK: - Development fixtures

    private enum DevelopmentRegion {
        case badung
        case cupertino
    }

    private struct DevelopmentPlace {
        let region: DevelopmentRegion
        let annotation: PlaceAnnotation
    }

    private static func developmentPlaces(
        for category: PlaceCategory,
        near center: CLLocationCoordinate2D,
        pickCount: Int
    ) -> [PlaceAnnotation] {
        let region = nearestDevelopmentRegion(to: center)
        let candidates = developmentFixturePlaces
            .filter { $0.region == region && $0.annotation.category == category }
            .map(\.annotation)
        return Array(rankedByRatingAndPopularity(candidates).prefix(pickCount))
    }

    private static func nearestDevelopmentRegion(to center: CLLocationCoordinate2D) -> DevelopmentRegion {
        let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let badungDistance = location.distance(
            from: CLLocation(latitude: badungCenter.latitude, longitude: badungCenter.longitude)
        )
        let cupertinoDistance = location.distance(
            from: CLLocation(latitude: cupertinoCenter.latitude, longitude: cupertinoCenter.longitude)
        )
        return cupertinoDistance < badungDistance ? .cupertino : .badung
    }

    private static var developmentFixturePlaces: [DevelopmentPlace] {
        [
            badungFood(
                "Warung Nia",
                address: "Jl. Kayu Aya No.19, Seminyak, Badung",
                description: "Balinese grill spot for satay, sambal, and easy group dinners near Seminyak.",
                latitude: -8.6850,
                longitude: 115.1584,
                rating: 4.5,
                reviews: 1620
            ),
            badungFood(
                "Made's Warung Berawa",
                address: "Jl. Pantai Berawa, Canggu, Badung",
                description: "Casual Indonesian comfort food with a wide menu and relaxed meetup-friendly seating.",
                latitude: -8.6611,
                longitude: 115.1416,
                rating: 4.4,
                reviews: 890
            ),
            badungFood(
                "Warung Local",
                address: "Jl. Pantai Batu Bolong, Canggu, Badung",
                description: "Simple nasi campur and local plates close to the Batu Bolong walking route.",
                latitude: -8.6502,
                longitude: 115.1335,
                rating: 4.6,
                reviews: 740
            ),
            badungFood(
                "Bambu Restaurant",
                address: "Jl. Petitenget No.198, Seminyak, Badung",
                description: "Polished Indonesian dinner setting with shareable dishes and a calmer evening pace.",
                latitude: -8.6776,
                longitude: 115.1531,
                rating: 4.6,
                reviews: 1320
            ),
            badungNature(
                "Pantai Batu Bolong",
                address: "Canggu, Kuta Utara, Badung",
                description: "A popular surf beach with sunset walks, beach cafes, and easy meetup points.",
                latitude: -8.6584,
                longitude: 115.1302,
                rating: 4.5,
                reviews: 4300
            ),
            badungNature(
                "Pantai Melasti",
                address: "Ungasan, Kuta Selatan, Badung",
                description: "Limestone cliffs, clear water, and wide beach access for a scenic day trip.",
                latitude: -8.8478,
                longitude: 115.1604,
                rating: 4.7,
                reviews: 6200
            ),
            badungNature(
                "Taman Ayun Garden",
                address: "Mengwi, Badung",
                description: "Open temple gardens and quiet paths that work well for relaxed cultural walks.",
                latitude: -8.5415,
                longitude: 115.1726,
                rating: 4.6,
                reviews: 5100
            ),
            badungNature(
                "Seseh Beach",
                address: "Munggu, Mengwi, Badung",
                description: "A softer black-sand beach option for smaller groups and slower sunset plans.",
                latitude: -8.6374,
                longitude: 115.1101,
                rating: 4.4,
                reviews: 620
            ),
            badungActivity(
                "Garuda Wisnu Kencana",
                address: "Ungasan, Kuta Selatan, Badung",
                description: "Large cultural park with performances, viewpoints, and plenty of space for groups.",
                latitude: -8.8102,
                longitude: 115.1676,
                rating: 4.6,
                reviews: 25000
            ),
            badungActivity(
                "Waterbom Bali",
                address: "Jl. Kartika Plaza, Kuta, Badung",
                description: "Water park day plan with rides, lockers, and an easy structure for bigger groups.",
                latitude: -8.7282,
                longitude: 115.1686,
                rating: 4.7,
                reviews: 15000
            ),
            badungActivity(
                "Seminyak Village",
                address: "Jl. Kayu Jati No.8, Seminyak, Badung",
                description: "Indoor-outdoor shopping stop close to restaurants, coffee, and evening plans.",
                latitude: -8.6833,
                longitude: 115.1573,
                rating: 4.2,
                reviews: 3200
            ),
            badungActivity(
                "Atlas Beach Fest",
                address: "Jl. Pantai Berawa No.88, Canggu, Badung",
                description: "Beach club activity option for social meetups, music, and sunset hangouts.",
                latitude: -8.6619,
                longitude: 115.1360,
                rating: 4.4,
                reviews: 6800
            ),
            cupertinoFood(
                "Dishdash Cupertino",
                address: "190 S Murphy Ave, Cupertino, CA",
                description: "Group-friendly Middle Eastern restaurant with shareable plates near the city center.",
                latitude: 37.3222,
                longitude: -122.0312,
                rating: 4.5,
                reviews: 2500
            ),
            cupertinoFood(
                "Lazy Dog Restaurant & Bar",
                address: "19359 Stevens Creek Blvd, Cupertino, CA",
                description: "Casual American restaurant with a broad menu and reliable seating for meetups.",
                latitude: 37.3228,
                longitude: -122.0100,
                rating: 4.3,
                reviews: 3800
            ),
            cupertinoFood(
                "Local Kitchens Cupertino",
                address: "21666 Stevens Creek Blvd, Cupertino, CA",
                description: "Flexible food hall setup that makes it easy for groups with different cravings.",
                latitude: 37.3232,
                longitude: -122.0533,
                rating: 4.4,
                reviews: 410
            ),
            cupertinoFood(
                "Alexander's Patisserie",
                address: "Main Street Cupertino, Cupertino, CA",
                description: "Pastries, desserts, and coffee for a lighter meetup before exploring Main Street.",
                latitude: 37.3238,
                longitude: -122.0105,
                rating: 4.6,
                reviews: 1400
            ),
            cupertinoNature(
                "Cupertino Memorial Park",
                address: "21121 Stevens Creek Blvd, Cupertino, CA",
                description: "Central park with open lawns, picnic areas, and an easy first-meet location.",
                latitude: 37.3235,
                longitude: -122.0442,
                rating: 4.6,
                reviews: 1900
            ),
            cupertinoNature(
                "Rancho San Antonio Preserve",
                address: "22500 Cristo Rey Dr, Cupertino, CA",
                description: "Trail network with foothill views and beginner-friendly routes for morning hikes.",
                latitude: 37.3327,
                longitude: -122.0865,
                rating: 4.8,
                reviews: 5200
            ),
            cupertinoNature(
                "McClellan Ranch Preserve",
                address: "22221 McClellan Rd, Cupertino, CA",
                description: "Quiet preserve with short trails, nature education areas, and a slower pace.",
                latitude: 37.3138,
                longitude: -122.0662,
                rating: 4.6,
                reviews: 720
            ),
            cupertinoNature(
                "Stevens Creek County Park",
                address: "11401 Stevens Canyon Rd, Cupertino, CA",
                description: "Reservoir views and hiking paths for longer outdoor plans near Cupertino.",
                latitude: 37.3077,
                longitude: -122.0749,
                rating: 4.6,
                reviews: 1500
            ),
            cupertinoActivity(
                "Apple Park Visitor Center",
                address: "10600 N Tantau Ave, Cupertino, CA",
                description: "Apple-focused stop with an exhibition area, rooftop terrace, store, and cafe.",
                latitude: 37.3327,
                longitude: -122.0053,
                rating: 4.6,
                reviews: 4200
            ),
            cupertinoActivity(
                "Main Street Cupertino",
                address: "19419 Stevens Creek Blvd, Cupertino, CA",
                description: "Walkable dining and shopping area that works well for casual group plans.",
                latitude: 37.3239,
                longitude: -122.0107,
                rating: 4.4,
                reviews: 2100
            ),
            cupertinoActivity(
                "De Anza College Planetarium",
                address: "21250 Stevens Creek Blvd, Cupertino, CA",
                description: "Small science-focused outing for a quieter evening or weekend meetup.",
                latitude: 37.3198,
                longitude: -122.0454,
                rating: 4.5,
                reviews: 260
            ),
            cupertinoActivity(
                "Blackberry Farm",
                address: "21979 San Fernando Ave, Cupertino, CA",
                description: "Seasonal recreation area with picnic space and easygoing outdoor activities.",
                latitude: 37.3173,
                longitude: -122.0631,
                rating: 4.5,
                reviews: 900
            ),
        ]
    }

    private static func badungFood(
        _ name: String,
        address: String,
        description: String,
        latitude: Double,
        longitude: Double,
        rating: Double,
        reviews: Int
    ) -> DevelopmentPlace {
        fixture(.badung, name, address, description, latitude, longitude, .food, rating, reviews)
    }

    private static func badungNature(
        _ name: String,
        address: String,
        description: String,
        latitude: Double,
        longitude: Double,
        rating: Double,
        reviews: Int
    ) -> DevelopmentPlace {
        fixture(.badung, name, address, description, latitude, longitude, .nature, rating, reviews)
    }

    private static func badungActivity(
        _ name: String,
        address: String,
        description: String,
        latitude: Double,
        longitude: Double,
        rating: Double,
        reviews: Int
    ) -> DevelopmentPlace {
        fixture(.badung, name, address, description, latitude, longitude, .activities, rating, reviews)
    }

    private static func cupertinoFood(
        _ name: String,
        address: String,
        description: String,
        latitude: Double,
        longitude: Double,
        rating: Double,
        reviews: Int
    ) -> DevelopmentPlace {
        fixture(.cupertino, name, address, description, latitude, longitude, .food, rating, reviews)
    }

    private static func cupertinoNature(
        _ name: String,
        address: String,
        description: String,
        latitude: Double,
        longitude: Double,
        rating: Double,
        reviews: Int
    ) -> DevelopmentPlace {
        fixture(.cupertino, name, address, description, latitude, longitude, .nature, rating, reviews)
    }

    private static func cupertinoActivity(
        _ name: String,
        address: String,
        description: String,
        latitude: Double,
        longitude: Double,
        rating: Double,
        reviews: Int
    ) -> DevelopmentPlace {
        fixture(.cupertino, name, address, description, latitude, longitude, .activities, rating, reviews)
    }

    private static func fixture(
        _ region: DevelopmentRegion,
        _ name: String,
        _ address: String,
        _ description: String,
        _ latitude: Double,
        _ longitude: Double,
        _ category: PlaceCategory,
        _ rating: Double,
        _ reviews: Int
    ) -> DevelopmentPlace {
        DevelopmentPlace(
            region: region,
            annotation: PlaceAnnotation(
                name: name,
                address: address,
                description: description,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                category: category,
                rating: rating,
                userRatingCount: reviews
            )
        )
    }
}
