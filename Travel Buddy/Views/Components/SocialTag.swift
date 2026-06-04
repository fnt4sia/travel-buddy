//
//  SocialTag.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 03/06/26.
//


import SwiftUI

struct SocialTag: View {
    let platform: SocialPlatform
    let handle: String

    var body: some View {
        HStack(spacing: 7) {
            SocialBadge(platform: platform, size: 20)
            Text(handle)
                .font(.subheadline)
                .foregroundStyle(AppColors.primaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(AppColors.accent.opacity(0.14), in: Capsule())
    }
}

#Preview {
    HStack {
        SocialTag(platform: .instagram, handle: "@markjohn22")
        SocialTag(platform: .twitter, handle: "@jmark22")
    }
    .padding()
}
