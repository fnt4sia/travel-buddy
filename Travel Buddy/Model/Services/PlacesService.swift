//
//  PlacesService.swift
//  Travel Buddy
//
//  Thin client for place recommendations.
//
//  Development mode returns hardcoded Badung-area places so the app can be
//  worked on without calling the paid Google Places API (New). Flip
//  `usesDevelopmentPlaces` to false when re-enabling live Nearby Search.
//
//  Google Places API (New) — "Nearby Search".
//  Fetches places of a category near a coordinate, ranks them by a blend of
//  average rating *and* number of ratings (Bayesian weighted rating), then
//  exposes a helper that returns a random sample of the best ones.
//
//  Docs: https://developers.google.com/maps/documentation/places/web-service/nearby-search
//

import CoreLocation
import Foundation

enum PlacesServiceError: LocalizedError {
    case missingAPIKey
    case requestFailed(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Google Places API key is missing. Set it in Secrets.xcconfig."
        case .requestFailed(let status, _):
            return "Places request failed (HTTP \(status))."
        }
    }
}

struct PlacesService {
    static let shared = PlacesService()
    private static let usesDevelopmentPlaces = true

    private let session: URLSession
    private let endpoint = URL(string: "https://places.googleapis.com/v1/places:searchNearby")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    private var apiKey: String { AppConfig.googlePlacesAPIKey }

    // MARK: - Public API

    /// Returns up to `pickCount` places, randomly chosen from the `bestCount`
    /// highest-ranked results for the given category near `center`.
    func recommendedPlaces(
        for category: PlaceCategory,
        near center: CLLocationCoordinate2D,
        radius: Double = 8000,
        bestCount: Int = 10,
        pickCount: Int = 5
    ) async throws -> [PlaceAnnotation] {
        if Self.usesDevelopmentPlaces {
            return Self.developmentPlaces(
                for: category,
                near: center,
                pickCount: pickCount
            )
        }

        let candidates = try await searchNearby(category: category, center: center, radius: radius)
        let ranked = Self.rankedByRatingAndPopularity(candidates)
        let best = Array(ranked.prefix(bestCount))
        return Array(best.shuffled().prefix(pickCount))
    }

    // MARK: - Development fixtures

    private static func developmentPlaces(
        for category: PlaceCategory,
        near center: CLLocationCoordinate2D,
        pickCount: Int
    ) -> [PlaceAnnotation] {
        let candidates = developmentBadungPlaces
            .filter { $0.category == category }
            .sorted { lhs, rhs in
                let lhsDistance = lhs.coordinate.distance(to: center)
                let rhsDistance = rhs.coordinate.distance(to: center)
                if abs(lhsDistance - rhsDistance) > 1200 {
                    return lhsDistance < rhsDistance
                }

                return weightedScore(lhs) > weightedScore(rhs)
            }

        return Array(candidates.prefix(pickCount))
    }

    private static func weightedScore(_ place: PlaceAnnotation) -> Double {
        let rating = place.rating ?? 0
        let count = Double(place.userRatingCount ?? 0)
        return rating + min(count / 2000, 1.0)
    }

    private static let developmentBadungPlaces: [PlaceAnnotation] = [
        PlaceAnnotation(
            id: "dev-local-warung-nia",
            name: "Warung Nia",
            address: "Jl. Kayu Aya No.19, Seminyak, Badung",
            description: "Balinese-style satay and grilled dishes near Seminyak, useful as a local-food test place.",
            coordinate: CLLocationCoordinate2D(latitude: -8.68446, longitude: 115.15649),
            category: .localFood,
            rating: 4.5,
            userRatingCount: 1800,
            primaryTypeName: "Balinese Restaurant",
            priceLevel: "$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["restaurant", "indonesian_restaurant"]
        ),
        PlaceAnnotation(
            id: "dev-local-nasi-ayam-kedewatan-ibu-mangku",
            name: "Nasi Ayam Kedewatan Ibu Mangku Seminyak",
            address: "Jl. Kayu Jati No.12, Seminyak, Badung",
            description: "Casual Indonesian chicken rice spot for local-food flow testing.",
            coordinate: CLLocationCoordinate2D(latitude: -8.68248, longitude: 115.15371),
            category: .localFood,
            rating: 4.4,
            userRatingCount: 1200,
            primaryTypeName: "Indonesian Restaurant",
            priceLevel: "$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["restaurant", "indonesian_restaurant"]
        ),
        PlaceAnnotation(
            id: "dev-local-warung-made",
            name: "Made's Warung Seminyak",
            address: "Jl. Raya Seminyak, Seminyak, Badung",
            description: "Long-running Indonesian restaurant with familiar Seminyak location data.",
            coordinate: CLLocationCoordinate2D(latitude: -8.69061, longitude: 115.17025),
            category: .localFood,
            rating: 4.3,
            userRatingCount: 2600,
            primaryTypeName: "Indonesian Restaurant",
            priceLevel: "$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["restaurant", "indonesian_restaurant"]
        ),
        PlaceAnnotation(
            id: "dev-local-babi-guling-dobiel",
            name: "Babi Guling Pak Dobiel",
            address: "Jl. Srikandi No.9, Nusa Dua, Badung",
            description: "Popular local pork rice shop in Nusa Dua for southern Badung testing.",
            coordinate: CLLocationCoordinate2D(latitude: -8.80229, longitude: 115.21822),
            category: .localFood,
            rating: 4.5,
            userRatingCount: 2100,
            primaryTypeName: "Balinese Restaurant",
            priceLevel: "$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["restaurant", "indonesian_restaurant"]
        ),
        PlaceAnnotation(
            id: "dev-cafe-revolver",
            name: "Revolver Espresso",
            address: "Jl. Kayu Aya No.3, Seminyak, Badung",
            description: "Compact coffee stop for testing cafe recommendations and chat meetups.",
            coordinate: CLLocationCoordinate2D(latitude: -8.68364, longitude: 115.15683),
            category: .cafes,
            rating: 4.6,
            userRatingCount: 3400,
            primaryTypeName: "Coffee Shop",
            priceLevel: "$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["cafe", "coffee_shop"]
        ),
        PlaceAnnotation(
            id: "dev-cafe-sisterfields",
            name: "Sisterfields",
            address: "Jl. Kayu Cendana No.7, Seminyak, Badung",
            description: "Modern cafe and brunch place near Seminyak Village.",
            coordinate: CLLocationCoordinate2D(latitude: -8.68207, longitude: 115.15562),
            category: .cafes,
            rating: 4.4,
            userRatingCount: 4800,
            primaryTypeName: "Cafe",
            priceLevel: "$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["cafe", "restaurant"]
        ),
        PlaceAnnotation(
            id: "dev-cafe-crate",
            name: "Crate Cafe",
            address: "Jl. Canggu Padang Linjong, Canggu, Badung",
            description: "Busy Canggu cafe fixture for popularity and crowd-proxy testing.",
            coordinate: CLLocationCoordinate2D(latitude: -8.64662, longitude: 115.13525),
            category: .cafes,
            rating: 4.5,
            userRatingCount: 5600,
            primaryTypeName: "Cafe",
            priceLevel: "$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["cafe", "coffee_shop"]
        ),
        PlaceAnnotation(
            id: "dev-cafe-baked-berawa",
            name: "Baked Berawa",
            address: "Jl. Subak Sari No.13, Tibubeneng, Badung",
            description: "Bakery-cafe around Berawa for northern Badung testing.",
            coordinate: CLLocationCoordinate2D(latitude: -8.66234, longitude: 115.14773),
            category: .cafes,
            rating: 4.5,
            userRatingCount: 1600,
            primaryTypeName: "Cafe",
            priceLevel: "$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["cafe", "bakery"]
        ),
        PlaceAnnotation(
            id: "dev-dessert-gusto",
            name: "Gusto Gelato & Caffe",
            address: "Jl. Mertanadi No.46B, Kerobokan Kelod, Badung",
            description: "Gelato spot for dessert-category flows without fast-food noise.",
            coordinate: CLLocationCoordinate2D(latitude: -8.67706, longitude: 115.17036),
            category: .dessert,
            rating: 4.6,
            userRatingCount: 9500,
            primaryTypeName: "Ice Cream Shop",
            priceLevel: "$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["dessert_shop", "ice_cream_shop"]
        ),
        PlaceAnnotation(
            id: "dev-dessert-dough-darlings",
            name: "Dough Darlings Seminyak",
            address: "Jl. Petitenget, Kerobokan Kelod, Badung",
            description: "Donut and coffee shop for dessert result testing.",
            coordinate: CLLocationCoordinate2D(latitude: -8.67477, longitude: 115.15118),
            category: .dessert,
            rating: 4.4,
            userRatingCount: 900,
            primaryTypeName: "Dessert Shop",
            priceLevel: "$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["dessert_shop", "bakery"]
        ),
        PlaceAnnotation(
            id: "dev-dessert-monsieur-spoon",
            name: "Monsieur Spoon Petitenget",
            address: "Jl. Petitenget No.112-A, Seminyak, Badung",
            description: "Pastry and bakery place around Petitenget.",
            coordinate: CLLocationCoordinate2D(latitude: -8.67430, longitude: 115.15374),
            category: .dessert,
            rating: 4.4,
            userRatingCount: 2100,
            primaryTypeName: "Bakery",
            priceLevel: "$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["bakery", "dessert_shop"]
        ),
        PlaceAnnotation(
            id: "dev-nature-petitenget-beach",
            name: "Petitenget Beach",
            address: "Petitenget, Seminyak, Badung",
            description: "Open beach area near Seminyak for relaxed meetup scenarios.",
            coordinate: CLLocationCoordinate2D(latitude: -8.67922, longitude: 115.14893),
            category: .nature,
            rating: 4.5,
            userRatingCount: 6800,
            primaryTypeName: "Beach",
            priceLevel: "Free",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["beach", "tourist_attraction"]
        ),
        PlaceAnnotation(
            id: "dev-nature-batu-bolong-beach",
            name: "Batu Bolong Beach",
            address: "Canggu, Badung",
            description: "Canggu beach location for northern Badung map testing.",
            coordinate: CLLocationCoordinate2D(latitude: -8.65761, longitude: 115.13068),
            category: .nature,
            rating: 4.4,
            userRatingCount: 7200,
            primaryTypeName: "Beach",
            priceLevel: "Free",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["beach", "tourist_attraction"]
        ),
        PlaceAnnotation(
            id: "dev-nature-garuda-wisnu-park",
            name: "Garuda Wisnu Kencana Cultural Park",
            address: "Jl. Raya Uluwatu, Ungasan, Badung",
            description: "Large park and landmark area for southern Badung activity flows.",
            coordinate: CLLocationCoordinate2D(latitude: -8.81039, longitude: 115.16760),
            category: .nature,
            rating: 4.5,
            userRatingCount: 22000,
            primaryTypeName: "Park",
            priceLevel: "$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["park", "tourist_attraction"]
        ),
        PlaceAnnotation(
            id: "dev-nature-pandawa-beach",
            name: "Pandawa Beach",
            address: "Kutuh, South Kuta, Badung",
            description: "South Badung beach fixture for nature-category coverage.",
            coordinate: CLLocationCoordinate2D(latitude: -8.84678, longitude: 115.18407),
            category: .nature,
            rating: 4.6,
            userRatingCount: 18000,
            primaryTypeName: "Beach",
            priceLevel: "$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["beach", "tourist_attraction"]
        ),
        PlaceAnnotation(
            id: "dev-culture-gwk",
            name: "GWK Statue Plaza",
            address: "Ungasan, South Kuta, Badung",
            description: "Cultural landmark around Garuda Wisnu Kencana.",
            coordinate: CLLocationCoordinate2D(latitude: -8.81186, longitude: 115.16761),
            category: .culture,
            rating: 4.5,
            userRatingCount: 18000,
            primaryTypeName: "Cultural Landmark",
            priceLevel: "$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["cultural_landmark", "tourist_attraction"]
        ),
        PlaceAnnotation(
            id: "dev-culture-petitenget-temple",
            name: "Pura Petitenget",
            address: "Jl. Petitenget, Seminyak, Badung",
            description: "Temple location near Seminyak for culture-category development.",
            coordinate: CLLocationCoordinate2D(latitude: -8.68002, longitude: 115.15035),
            category: .culture,
            rating: 4.4,
            userRatingCount: 900,
            primaryTypeName: "Hindu Temple",
            priceLevel: "Free",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["hindu_temple", "cultural_landmark"]
        ),
        PlaceAnnotation(
            id: "dev-culture-puja-mandala",
            name: "Puja Mandala",
            address: "Jl. Kuruksetra, Nusa Dua, Badung",
            description: "Multi-faith worship complex in Nusa Dua for cultural itinerary testing.",
            coordinate: CLLocationCoordinate2D(latitude: -8.80171, longitude: 115.21990),
            category: .culture,
            rating: 4.6,
            userRatingCount: 1500,
            primaryTypeName: "Cultural Landmark",
            priceLevel: "Free",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["cultural_landmark", "place_of_worship"]
        ),
        PlaceAnnotation(
            id: "dev-activity-waterbom",
            name: "Waterbom Bali",
            address: "Jl. Kartika Plaza, Kuta, Badung",
            description: "Water park in Kuta for activity-category testing.",
            coordinate: CLLocationCoordinate2D(latitude: -8.72896, longitude: 115.16939),
            category: .activities,
            rating: 4.7,
            userRatingCount: 15000,
            primaryTypeName: "Water Park",
            priceLevel: "$$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["water_park", "tourist_attraction"]
        ),
        PlaceAnnotation(
            id: "dev-activity-finns",
            name: "FINNS Recreation Club",
            address: "Jl. Pantai Berawa, Canggu, Badung",
            description: "Recreation club around Berawa for active meetup scenarios.",
            coordinate: CLLocationCoordinate2D(latitude: -8.66292, longitude: 115.14895),
            category: .activities,
            rating: 4.4,
            userRatingCount: 3100,
            primaryTypeName: "Recreation Center",
            priceLevel: "$$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["adventure_sports_center", "tourist_attraction"]
        ),
        PlaceAnnotation(
            id: "dev-activity-bali-wake-park",
            name: "Bali Wake Park",
            address: "Pelabuhan Benoa, Badung",
            description: "Wake park fixture for activity-category development.",
            coordinate: CLLocationCoordinate2D(latitude: -8.73316, longitude: 115.21338),
            category: .activities,
            rating: 4.5,
            userRatingCount: 1700,
            primaryTypeName: "Adventure Sports Center",
            priceLevel: "$$",
            businessStatus: "OPERATIONAL",
            isOpenNow: true,
            types: ["adventure_sports_center", "water_park"]
        )
    ]

    // MARK: - Networking

    private func searchNearby(
        category: PlaceCategory,
        center: CLLocationCoordinate2D,
        radius: Double
    ) async throws -> [PlaceAnnotation] {
        guard !apiKey.isEmpty else { throw PlacesServiceError.missingAPIKey }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        // Only request the fields we actually use (required by the New Places API).
        request.setValue(
            "places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.photos,places.editorialSummary,places.types,places.primaryType,places.primaryTypeDisplayName,places.businessStatus,places.currentOpeningHours,places.priceLevel",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )

        let profile = Self.searchProfile(for: category)
        var body: [String: Any] = [
            "includedTypes": profile.includedTypes,
            "maxResultCount": 20,
            "rankPreference": "POPULARITY",
            "locationRestriction": [
                "circle": [
                    "center": ["latitude": center.latitude, "longitude": center.longitude],
                    "radius": radius
                ]
            ]
        ]
        if !profile.excludedTypes.isEmpty {
            body["excludedTypes"] = profile.excludedTypes
        }
        if !profile.excludedPrimaryTypes.isEmpty {
            body["excludedPrimaryTypes"] = profile.excludedPrimaryTypes
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(status) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            print("[PlacesService] HTTP \(status): \(bodyText)")
            throw PlacesServiceError.requestFailed(status: status, body: bodyText)
        }

        let decoded = try JSONDecoder().decode(NearbyResponse.self, from: data)
        return (decoded.places ?? [])
            .compactMap { $0.toAnnotation(category: category, apiKey: apiKey) }
            .filter(Self.isWorthShowing)
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

    // MARK: - Category → Google place types (Places API New, "Table A")

    private struct SearchProfile {
        let includedTypes: [String]
        let excludedTypes: [String]
        let excludedPrimaryTypes: [String]
    }

    private static func searchProfile(for category: PlaceCategory) -> SearchProfile {
        switch category {
        case .localFood:
            return SearchProfile(
                includedTypes: ["restaurant", "indonesian_restaurant"],
                excludedTypes: ["fast_food_restaurant"],
                excludedPrimaryTypes: ["fast_food_restaurant"]
            )
        case .cafes:
            return SearchProfile(
                includedTypes: ["cafe", "coffee_shop"],
                excludedTypes: ["fast_food_restaurant"],
                excludedPrimaryTypes: ["fast_food_restaurant"]
            )
        case .dessert:
            return SearchProfile(
                includedTypes: ["bakery", "dessert_shop", "ice_cream_shop"],
                excludedTypes: ["fast_food_restaurant"],
                excludedPrimaryTypes: ["fast_food_restaurant"]
            )
        case .nature:
            return SearchProfile(
                includedTypes: ["park", "national_park", "hiking_area", "beach"],
                excludedTypes: [],
                excludedPrimaryTypes: []
            )
        case .culture:
            return SearchProfile(
                includedTypes: ["museum", "art_gallery", "tourist_attraction"],
                excludedTypes: ["hotel"],
                excludedPrimaryTypes: ["hotel"]
            )
        case .activities:
            return SearchProfile(
                includedTypes: ["tourist_attraction", "amusement_park"],
                excludedTypes: ["hotel"],
                excludedPrimaryTypes: ["hotel"]
            )
        }
    }

    private static func isWorthShowing(_ place: PlaceAnnotation) -> Bool {
        guard place.businessStatus != "CLOSED_PERMANENTLY" else { return false }

        let searchableName = place.name.lowercased()
        let blockedNameFragments = [
            "mcdonald", "mcd ", "mc donald", "kfc", "burger king",
            "pizza hut", "domino", "subway", "starbucks", "chick-fil-a",
            "chick fill a", "wendy", "taco bell", "a&w"
        ]
        if blockedNameFragments.contains(where: searchableName.contains) {
            return false
        }

        let loweredTypes = Set(place.types.map { $0.lowercased() })
        let hotelTypes = [
            "hotel", "lodging", "motel", "resort_hotel",
            "extended_stay_hotel", "bed_and_breakfast", "guest_house"
        ]
        if hotelTypes.contains(where: loweredTypes.contains) {
            return false
        }

        if place.category == .localFood || place.category == .cafes || place.category == .dessert {
            let fastFoodTypes = ["fast_food_restaurant", "meal_takeaway"]
            if fastFoodTypes.contains(where: loweredTypes.contains) {
                return false
            }
        }

        return true
    }
}

// MARK: - Response DTOs

private struct NearbyResponse: Decodable {
    let places: [GooglePlace]?
}

private struct GooglePlace: Decodable {
    struct LocalizedText: Decodable { let text: String? }
    struct LatLng: Decodable { let latitude: Double; let longitude: Double }
    struct Photo: Decodable { let name: String? }
    struct OpeningHours: Decodable { let openNow: Bool? }

    let id: String?
    let displayName: LocalizedText?
    let formattedAddress: String?
    let location: LatLng?
    let rating: Double?
    let userRatingCount: Int?
    let photos: [Photo]?
    let editorialSummary: LocalizedText?
    let types: [String]?
    let primaryType: String?
    let primaryTypeDisplayName: LocalizedText?
    let businessStatus: String?
    let currentOpeningHours: OpeningHours?
    let priceLevel: String?

    func toAnnotation(category: PlaceCategory, apiKey: String) -> PlaceAnnotation? {
        guard let location, let name = displayName?.text, !name.isEmpty else { return nil }

        let photoURLs = (photos ?? [])
            .prefix(6)
            .compactMap { photo -> URL? in
                guard let photoName = photo.name, !photoName.isEmpty else {
                    return nil
                }
                return URL(string: "https://places.googleapis.com/v1/\(photoName)/media?maxHeightPx=900&maxWidthPx=900&key=\(apiKey)")
            }

        return PlaceAnnotation(
            id: id ?? UUID().uuidString,
            name: name,
            address: formattedAddress ?? "",
            description: editorialSummary?.text ?? "",
            coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            category: category,
            rating: rating,
            userRatingCount: userRatingCount,
            photoURLs: photoURLs,
            primaryTypeName: primaryTypeDisplayName?.text ?? primaryType?.replacingOccurrences(of: "_", with: " ").capitalized,
            priceLevel: priceDisplayName(for: priceLevel),
            businessStatus: businessStatus,
            isOpenNow: currentOpeningHours?.openNow,
            types: types ?? []
        )
    }

    private func priceDisplayName(for value: String?) -> String? {
        switch value {
        case "PRICE_LEVEL_FREE": return "Free"
        case "PRICE_LEVEL_INEXPENSIVE": return "$"
        case "PRICE_LEVEL_MODERATE": return "$$"
        case "PRICE_LEVEL_EXPENSIVE": return "$$$"
        case "PRICE_LEVEL_VERY_EXPENSIVE": return "$$$$"
        default: return nil
        }
    }
}

private extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}
