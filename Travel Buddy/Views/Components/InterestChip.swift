//
//  InterestChip.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 02/06/26.
//

import SwiftUI

struct InterestChip: View {
    let interest: String

    var body: some View {
        HStack(spacing: 6) {
            Text(InterestStyle.emoji(for: interest))
            Text(interest)
                .font(.system(size: ProfileMetrics.Font.chip, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(AppColors.brandTeal, in: Capsule())
    }
}

#Preview {
    HStack {
        InterestChip(interest: "Photography")
        InterestChip(interest: "Museums")
        InterestChip(interest: "Music")
    }
    .padding()
}
