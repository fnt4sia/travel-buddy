//
//  OtherUserProfile.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 03/06/26.
//

import SwiftUI
import Combine

final class OtherUserProfileViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile
    @Published var isAboutExpanded = false

    var onBack: () -> Void = {}

    init(profile: UserProfile) {
        self.profile = profile
    }

    var ageText: String { "• \(profile.age)" }
    var locationText: String { profile.locationText }

    var instagramHandle: String? { profile.instagramHandle.isEmpty ? nil : profile.instagramHandle }
    var twitterHandle: String? { profile.twitterHandle.isEmpty ? nil : profile.twitterHandle }
    var hasSocials: Bool { instagramHandle != nil || twitterHandle != nil }

    var galleryImageNames: [String] { profile.galleryImageNames }
    var hasGallery: Bool { !profile.galleryImageNames.isEmpty }

    func toggleAbout() { isAboutExpanded.toggle() }
    func backTapped() { onBack() }
}
