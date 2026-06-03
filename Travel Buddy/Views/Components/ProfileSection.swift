//
//  ProfileSection.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 02/06/26.
//

import SwiftUI
struct ProfileSection<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: ProfileMetrics.Layout.sectionTitleSpacing) {
            SectionHeader(icon: icon, title: title)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ProfileSection(icon: "heart.fill", title: "Interest") {
        FlowLayout {
            InterestChip(interest: "Photography")
            InterestChip(interest: "Museums")
        }
    }
    .padding()
}
