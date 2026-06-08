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
                .lineLimit(1)
                .foregroundStyle(AppColors.primaryText)
        }
        .foregroundStyle(AppColors.brandPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(AppColors.accentSurface, in: Capsule())
        .overlay(Capsule().stroke(AppColors.cardBorder, lineWidth: 1))
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
