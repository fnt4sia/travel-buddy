//
//  ProfileAvatar.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 02/06/26.
//

import SwiftUI

struct ProfileAvatar: View {
    let imageName: String
    var imageData: Data? = nil
    var size: CGFloat = ProfileMetrics.Avatar.size

    private var shape: some Shape {
        RoundedRectangle(cornerRadius: ProfileMetrics.Avatar.cornerRadius, style: .continuous)
    }

    var body: some View {
        avatarContent
            .frame(width: size, height: size)
            .clipShape(shape)
            .overlay { shape.stroke(AppColors.textOnAccent, lineWidth: 1) }
            .shadow(color: AppColors.scrim.opacity(0.1), radius: 12, x: 0, y: 8)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            AppColors.avatarPlaceholder
                .overlay {
                    Image(systemName: "person.crop.square.fill")
                        .font(.system(size: size * 1))
                        .foregroundStyle(AppColors.brandPrimary.opacity(0.45))
                }
        }
    }
}

#Preview {
    ProfileAvatar(imageName: "missing_asset")
        .padding()
}
