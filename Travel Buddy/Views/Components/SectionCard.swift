//
//  SectionCard.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 03/06/26.
//

import SwiftUI

struct SectionCard<Content: View>: View {
    @ViewBuilder var content: Content

    private let cornerRadius: CGFloat = 22
    private let padding: CGFloat = 16

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.formBackground, in: shape)
            .overlay { shape.stroke(AppColors.formBorder, lineWidth: 1) }
    }
}

#Preview {
    SectionCard {
        Text("Card content")
            .foregroundStyle(AppColors.primaryText)
    }
    .padding()
    .background(AppColors.accent.opacity(0.2))
}
