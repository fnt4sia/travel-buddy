//
//  AppColors.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//

import SwiftUI

struct AppColors {
    static var brandPrimary: Color {
        Color(red: 0.016, green: 0.337, blue: 0.431) // #04566E
    }

    static var brandDeep: Color {
        Color(red: 0.008, green: 0.192, blue: 0.255)
    }

    static var brandSecondary: Color {
        Color(red: 0.039, green: 0.506, blue: 0.557)
    }

    static var warmAccent: Color {
        Color(red: 0.945, green: 0.616, blue: 0.224)
    }

    // MARK: - Primary Colors
    static var primaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.96, alpha: 1)
                : UIColor(red: 0.06, green: 0.08, blue: 0.09, alpha: 1)
        })
    }

    static var secondaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.72, alpha: 1)
                : UIColor(red: 0.34, green: 0.40, blue: 0.42, alpha: 1)
        })
    }

    // MARK: - Background Colors
    static var background: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.03, green: 0.05, blue: 0.06, alpha: 1)
                : UIColor(red: 0.96, green: 0.98, blue: 0.98, alpha: 1)
        })
    }

    static var surface: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.08, green: 0.10, blue: 0.11, alpha: 1)
                : UIColor.white
        })
    }

    static var surfaceElevated: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.14, blue: 0.15, alpha: 1)
                : UIColor(red: 0.985, green: 0.995, blue: 0.995, alpha: 1)
        })
    }

    static var cardBorder: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.10)
                : UIColor(red: 0.80, green: 0.87, blue: 0.88, alpha: 1)
        })
    }

    static var accentSurface: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.05, green: 0.20, blue: 0.24, alpha: 1)
                : UIColor(red: 0.90, green: 0.96, blue: 0.97, alpha: 1)
        })
    }

    static var welcomeBackground: Color {
        Color.black
    }

    // MARK: - Form Colors
    static var formBackground: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(white: 0.15, alpha: 0.75)
            } else {
                return UIColor(white: 1.0, alpha: 0.75)
            }
        })
    }

    static var formBorder: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(white: 0.3, alpha: 0.2)
            } else {
                return UIColor(white: 1.0, alpha: 0.2)
            }
        })
    }

    static var textFieldBackground: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(white: 0.2, alpha: 1.0)
            } else {
                return UIColor(white: 1.0, alpha: 1.0)
            }
        })
    }

    static var textFieldBorder: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(white: 0.3, alpha: 0.3)
            } else {
                return UIColor(white: 0.7, alpha: 0.3)
            }
        })
    }

    // MARK: - Accent Colors
    static var accent: Color {
        brandPrimary
    }

    static var accentDisabled: Color {
        brandPrimary.opacity(0.38)
    }

    // Profile colors
    static var brandTeal: Color {
        brandPrimary
    }

    static var coverBackground: Color {
        brandPrimary
    }

    static var avatarPlaceholder: Color {
        accentSurface
    }

    static var pinColor: Color {
        brandPrimary
    }

    static var pinGlow: Color {
        brandSecondary
    }
}
