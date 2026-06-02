//
//  ProfileViewModel.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 02/06/26.
//

import SwiftUI
import Combine

final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile

    var onEdit: () -> Void = {}
    var onBack: () -> Void = {}

    init(profile: UserProfile = .currentUserMock) {
        self.profile = profile
    }

    var ageText: String { "• \(profile.age)" }

    var instagramHandle: String? { profile.instagramHandle }
    var twitterHandle: String? { profile.twitterHandle }

    var hasSocialMedia: Bool {
        profile.instagramHandle != nil || profile.twitterHandle != nil
    }

    func editTapped() { onEdit() }
    func backTapped() { onBack() }
}
