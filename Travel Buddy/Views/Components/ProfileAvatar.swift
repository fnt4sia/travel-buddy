//
//  ProfileAvatar.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 02/06/26.
//
import SwiftUI

struct ProfileAvatar: View {
    enum AvatarShape { case roundedSquare, circle }

    let imageName: String
    var size: CGFloat = ProfileMetrics.Avatar.size
    var shape: AvatarShape = .roundedSquare

    private var clipShape: AnyShape {
        switch shape {
        case .circle:
            return AnyShape(Circle())
        case .roundedSquare:
            return AnyShape(RoundedRectangle(cornerRadius: ProfileMetrics.Avatar.cornerRadius, style: .continuous))
        }
    }

    var body: some View {
        avatarContent
            .frame(width: size, height: size)
            .clipShape(clipShape)
            .overlay { clipShape.stroke(Color.white, lineWidth: 2) }
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            AppColors.avatarPlaceholder
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.5))
                        .foregroundStyle(.black.opacity(0.34))
                }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        ProfileAvatar(imageName: "missing", size: 96, shape: .roundedSquare)
        ProfileAvatar(imageName: "missing", size: 96, shape: .circle)
    }
    .padding()
}
