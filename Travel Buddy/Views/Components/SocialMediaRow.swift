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
            SocialBadge(platform: platform)

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
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SocialMediaRow(platform: .instagram, handle: "@markjohn22")
        SocialMediaRow(platform: .twitter, handle: "@jmark22")
    }
    .padding()
}
