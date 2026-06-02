//
//  AppConfig.swift
//  Travel Buddy
//
//  Reads environment values that are injected at build time from Secrets.xcconfig
//  into the app's Info.plist (see Secrets.example.xcconfig and the project settings).
//

import Foundation

enum AppConfig {
    /// Google Places API key, sourced from `Secrets.xcconfig` via `INFOPLIST_KEY_GooglePlacesAPIKey`.
    static var googlePlacesAPIKey: String {
        let raw = Bundle.main.object(forInfoDictionaryKey: "GooglePlacesAPIKey") as? String ?? ""
        // When the xcconfig isn't wired up the value can come through unexpanded.
        guard !raw.isEmpty, raw != "$(GOOGLE_PLACES_API_KEY)", raw != "YOUR_GOOGLE_PLACES_API_KEY_HERE" else {
            assertionFailure("Missing Google Places API key. Copy Secrets.example.xcconfig to Secrets.xcconfig and set GOOGLE_PLACES_API_KEY.")
            return ""
        }
        return raw
    }
}
