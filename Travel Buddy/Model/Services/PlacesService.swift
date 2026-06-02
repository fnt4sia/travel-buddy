//
//  PlacesService.swift
//  Travel Buddy
//
//  Thin client for the Google Places API (New) — "Nearby Search".
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
        pickCount: Int = 3
    ) async throws -> [PlaceAnnotation] {
        let candidates = try await searchNearby(category: category, center: center, radius: radius)
        let ranked = Self.rankedByRatingAndPopularity(candidates)
        let best = Array(ranked.prefix(bestCount))
        return Array(best.shuffled().prefix(pickCount))
    }

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
            "places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.photos,places.editorialSummary",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )

        let body: [String: Any] = [
            "includedTypes": Self.includedTypes(for: category),
            "maxResultCount": 20,
            "rankPreference": "POPULARITY",
            "locationRestriction": [
                "circle": [
                    "center": ["latitude": center.latitude, "longitude": center.longitude],
                    "radius": radius
                ]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(status) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            print("[PlacesService] HTTP \(status): \(bodyText)")
            throw PlacesServiceError.requestFailed(status: status, body: bodyText)
        }

        let decoded = try JSONDecoder().decode(NearbyResponse.self, from: data)
        return (decoded.places ?? []).compactMap { $0.toAnnotation(category: category, apiKey: apiKey) }
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

    private static func includedTypes(for category: PlaceCategory) -> [String] {
        switch category {
        case .nature:
            return ["park", "national_park", "hiking_area", "beach"]
        case .activities:
            return ["tourist_attraction", "museum", "art_gallery", "amusement_park"]
        case .food:
            return ["restaurant", "cafe"]
        }
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

    let id: String?
    let displayName: LocalizedText?
    let formattedAddress: String?
    let location: LatLng?
    let rating: Double?
    let userRatingCount: Int?
    let photos: [Photo]?
    let editorialSummary: LocalizedText?

    func toAnnotation(category: PlaceCategory, apiKey: String) -> PlaceAnnotation? {
        guard let location, let name = displayName?.text, !name.isEmpty else { return nil }

        var photoURL: URL?
        if let photoName = photos?.first?.name, !photoName.isEmpty {
            photoURL = URL(string: "https://places.googleapis.com/v1/\(photoName)/media?maxHeightPx=800&maxWidthPx=800&key=\(apiKey)")
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
            photoURL: photoURL
        )
    }
}
