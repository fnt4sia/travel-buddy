//
//  AppColors.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//

import SwiftUI

struct AppColors {
    // MARK: - Primary Colors
    static var primaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        })
    }
    
    static var secondaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .lightGray : .gray
        })
    }
    
    // MARK: - Background Colors
    static var background: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
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
        return .teal
    }
    
    static var accentDisabled: Color {
        return .teal.opacity(0.4)
    }
    
    // MARK: - Special Colors
    static var pinColor: Color {
        Color(red: 0.9, green: 0.2, blue: 0.2)
    }
    
    static var pinGlow: Color {
        Color(red: 1.0, green: 0.3, blue: 0.3)
    }
}
