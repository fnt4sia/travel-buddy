//
//  GalleryThumbnail.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 03/06/26.
//


import SwiftUI

/// A single rounded gallery image with a graceful placeholder when the asset
/// is missing.
struct GalleryThumbnail: View {
    let imageName: String
    var size: CGFloat = 150

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }

    var body: some View {
        Group {
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [AppColors.accent.opacity(0.45), AppColors.brandTeal.opacity(0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .overlay { shape.stroke(AppColors.formBorder, lineWidth: 1) }
        .accessibilityLabel("Gallery photo")
    }
}

/// Horizontally scrollable row of gallery thumbnails.
struct GalleryStrip: View {
    let imageNames: [String]
    var horizontalPadding: CGFloat = ProfileMetrics.Layout.screenPadding

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(imageNames, id: \.self) { name in
                    GalleryThumbnail(imageName: name)
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
    }
}

#Preview {
    GalleryStrip(imageNames: ["a", "b", "c"])
        .padding(.vertical)
}