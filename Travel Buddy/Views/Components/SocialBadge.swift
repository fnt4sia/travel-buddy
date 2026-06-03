//
//  SocialBadge.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 03/06/26.
//


import SwiftUI

/// The small rounded brand glyph for a social platform.
/// Prefers a bundled asset (`instagram` / `x_twitter`); otherwise falls back to
/// an SF Symbol on the platform's brand-colored badge. Shared by `SocialTag`
/// and `SocialMediaRow` so the badge styling lives in exactly one place.
struct SocialBadge: View {
    let platform: SocialPlatform
    var size: CGFloat = 24

    var body: some View {
        Group {
            if UIImage(named: platform.assetName) != nil {
                Image(platform.assetName)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: platform.fallbackSymbol)
                    .font(.system(size: size * 0.55, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(platform.badgeBackground)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
    }
}

#Preview {
    HStack {
        SocialBadge(platform: .instagram)
        SocialBadge(platform: .twitter)
    }
    .padding()
}