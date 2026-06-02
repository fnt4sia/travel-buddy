//
//  SocialMediaRow.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 02/06/26.
//


import SwiftUI

struct SocialMediaRow: View {
    let platform: SocialPlatform
    let handle: String

    private let nameColumnWidth: CGFloat = 80

    var body: some View {
        HStack(spacing: 10) {
            badge

            HStack(spacing: 4) {
                Text(platform.displayName)
                    .frame(width: nameColumnWidth, alignment: .leading)
                Text(":")
                Text(handle)
            }
            .font(.system(size: ProfileMetrics.Font.social))
            .foregroundStyle(AppColors.primaryText)
        }
    }

    private var badge: some View {
        Group {
            if UIImage(named: platform.assetName) != nil {
                Image(platform.assetName)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: platform.fallbackSymbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(platform.badgeBackground)
            }
        }
        .frame(width: 24, height: 24)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SocialMediaRow(platform: .instagram, handle: "@markjohn22")
        SocialMediaRow(platform: .twitter, handle: "@jmark22")
    }
    .padding()
}
