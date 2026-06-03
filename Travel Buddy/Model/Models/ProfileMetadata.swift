//
//  ProfileMetadata.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 02/06/26.
//

import SwiftUI

enum InterestStyle {
    static func emoji(for interest: String) -> String {
        switch interest {
        case "Photography": return "📷"
        case "Museums":     return "🏛️"
        case "Music":       return "🎵"
        case "Travel":      return "✈️"
        case "Food":        return "🍜"
        case "Art":         return "🎨"
        case "Hiking":      return "🥾"
        case "Cooking":     return "🍳"
        case "Fashion":     return "👕"
        case "Adventure":   return "🧭"
        case "Sports":      return "🏀"
        case "Yoga":        return "🧘"
        case "Nature":      return "🌿"
        case "Meditation":  return "🌙"
        case "Shopping":    return "🛍️"
        case "Dining":      return "🍽️"
        case "Dance":       return "💃"
        case "Fitness":     return "🏋️"
        default:            return "⭐️"
        }
    }

    static func symbol(for interest: String) -> String {
        switch interest {
        case "Photography": return "camera.fill"
        case "Museums":     return "building.columns.fill"
        case "Music":       return "music.note"
        case "Travel":      return "airplane"
        case "Food":        return "fork.knife"
        case "Art":         return "paintpalette.fill"
        case "Hiking":      return "mountain.2.fill"
        case "Cooking":     return "flame.fill"
        case "Fashion":     return "tshirt.fill"
        case "Adventure":   return "compass.drawing"
        case "Sports":      return "figure.basketball"
        case "Yoga":        return "figure.yoga"
        case "Nature":      return "leaf.fill"
        case "Meditation":  return "moon.stars.fill"
        case "Shopping":    return "bag.fill"
        case "Dining":      return "fork.knife"
        case "Dance":       return "music.note.house.fill"
        case "Fitness":     return "dumbbell.fill"
        default:            return "star.fill"
        }
    }
}
enum LanguageFlag {
    static func emoji(for value: String) -> String {
        switch value {
        case "Malaysia", "Malay":            return "🇲🇾"
        case "Indonesia", "Indonesian":      return "🇮🇩"
        case "English":                      return "🇬🇧"
        case "Chinese", "Mandarin":          return "🇨🇳"
        case "Arabic":                       return "🇸🇦"
        case "Spanish":                      return "🇪🇸"
        case "French":                       return "🇫🇷"
        case "Japanese":                     return "🇯🇵"
        case "Korean":                       return "🇰🇷"
        case "German":                       return "🇩🇪"
        case "Thai":                         return "🇹🇭"
        default:                             return "🏳️"
        }
    }
}

enum SocialPlatform {
    case instagram
    case twitter

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .twitter:   return "Twitter"
        }
    }

    var assetName: String {
        switch self {
        case .instagram: return "instagram"
        case .twitter:   return "x_twitter"
        }
    }

    var fallbackSymbol: String {
        switch self {
        case .instagram: return "camera.fill"
        case .twitter:   return "xmark"
        }
    }

    var badgeBackground: AnyShapeStyle {
        switch self {
        case .instagram:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.27, blue: 0.42),
                        Color(red: 0.51, green: 0.23, blue: 0.78),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .twitter:
            return AnyShapeStyle(Color.black)
        }
    }
}
