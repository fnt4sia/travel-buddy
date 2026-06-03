//
//  SectionHeader.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 03/06/26.
//


import SwiftUI

/// Reusable "icon + title" header used above every profile section.
/// Uses semantic text styles so it scales with Dynamic Type.
struct SectionHeader: View {
    let icon: String
    let title: String
    var tint: Color = AppColors.primaryText

    var body: some View {
        HStack(spacing: ProfileMetrics.Layout.iconTitleSpacing) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
            Text(title)
                .font(.headline)
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        SectionHeader(icon: "person.fill", title: "About me")
        SectionHeader(icon: "heart.fill", title: "Interest")
    }
    .padding()
}