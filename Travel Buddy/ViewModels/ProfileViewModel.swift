//
//  ProfileViewModel.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 02/06/26.
//

import SwiftUI
import Combine

enum ProfileEditTarget: Identifiable {
    case photo, name, about, languages, interests, socials, gallery, identity
    var id: Self { self }
}

final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile

    @Published var editTarget: ProfileEditTarget?

    let isEditable: Bool

    init() {
        self.profile = CurrentUserProfileStore.currentProfile()
        self.isEditable = true
    }

    init(profile: UserProfile, isEditable: Bool = false) {
        self.profile = profile
        self.isEditable = isEditable
    }

    var instagramHandle: String? { profile.instagramHandle }
    var twitterHandle: String? { profile.twitterHandle }
    var hasSocialMedia: Bool { profile.instagramHandle != nil || profile.twitterHandle != nil }
    var hasGallery: Bool { !profile.gallery.isEmpty }

    func presentEditor(_ target: ProfileEditTarget) {
        guard isEditable else { return }
        editTarget = target
    }

    func updateName(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        profile.name = trimmed
        persist()
    }

    func updateAbout(_ value: String) {
        profile.aboutMe = value.trimmingCharacters(in: .whitespacesAndNewlines)
        persist()
    }

    func updateLanguages(_ value: [String]) {
        profile.languages = value
        persist()
    }

    func updateInterests(_ value: [String]) {
        profile.interests = value
        persist()
    }

    func updateSocials(instagram: String?, twitter: String?) {
        profile.instagramHandle = Self.normalizedHandle(instagram)
        profile.twitterHandle = Self.normalizedHandle(twitter)
        persist()
    }

    func updateProfileImage(_ data: Data?) {
        profile.profileImageData = data
        persist()
    }

    func replaceGallery(_ photos: [GalleryPhoto]) {
        profile.gallery = photos
        persist()
    }
    
    func updateNameAndCountry(_ name: String, country: String) {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty, !trimmedCountry.isEmpty else { return }
            profile.name = trimmedName
            profile.updateCountry(to: trimmedCountry)
            persist()
    }

    static func normalizedHandle(_ raw: String?) -> String? {
        guard let raw else { return nil }
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        while value.hasPrefix("@") { value.removeFirst() }
        return value.isEmpty ? nil : "@" + value
    }

    private func persist() {
        guard isEditable else { return }
        CurrentUserProfileStore.saveEditableProfile(profile)
    }
}
