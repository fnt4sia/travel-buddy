//
//  LanguageChip.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 02/06/26.
//

import SwiftUI

struct LanguageChip: View {
    let language: String

    var body: some View {
        HStack(spacing: 6) {
            Text(LanguageFlag.emoji(for: language))
            Text(language)
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
        LanguageChip(language: "Malaysia")
        LanguageChip(language: "Indonesia")
    }
    .padding()
}
