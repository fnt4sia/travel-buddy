import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @ObservedObject private var meetupStore = MeetupStore.shared

    init(viewModel: ProfileViewModel? = nil) {
            _viewModel = StateObject(
                wrappedValue: viewModel ?? ProfileViewModel()
            )
        }
    
    private var canEdit: Bool { viewModel.isEditable }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                aboutSection
                languageSection
                interestSection
                if canEdit || viewModel.hasSocialMedia { socialMediaSection }
                if canEdit || viewModel.hasGallery { gallerySection }
            }
            .padding(.horizontal, ProfileMetrics.Layout.screenPadding)
            .padding(.top, 16)
            .padding(.bottom, ProfileMetrics.Layout.bottomSafeInset)
        }
        .background(AppColors.background.ignoresSafeArea())
        .sheet(item: $viewModel.editTarget) { editorSheet(for: $0) }
        .task {
            await meetupStore.loadJoinedGroups()
        }
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                    Text("Your travel identity")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                }
                Spacer()
            }
            identityPanel
            profileStats
        }
    }

    private var identityPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                
                ZStack(alignment: .bottomTrailing) {
                    ProfileAvatar(
                        imageName: viewModel.profile.profileImageName,
                        imageData: viewModel.profile.profileImageData,
                        size: 92
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ProfileMetrics.Avatar.cornerRadius, style: .continuous)
                            .stroke(AppColors.textOnAccent.opacity(0.7), lineWidth: 2)
                    )

                    if canEdit {
                        EditPencil(onLight: true, label: "profile photo") {
                            viewModel.presentEditor(.photo)
                        }
                        .offset(x: 6, y: 6)
                    }
                }
                Spacer()
                countryBadge
                // I need to edit this huhu not yet fixed
                    .overlay(alignment: .topTrailing) {
                        if canEdit {
                            EditPencil(onLight: true, label: "profile info") {
                                viewModel.presentEditor(.identity)
                            }
                            .offset(x: 24, y: -30)
                        }
                    }
                
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text(displayUsername)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppColors.textOnAccent)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                    
                    Text("\(viewModel.profile.age)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.accentText)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(AppColors.textOnAccent, in: Capsule())
                }

                Text(viewModel.profile.realName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.textOnAccent.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppColors.textOnAccent.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: AppColors.brandPrimary.opacity(0.20), radius: 18, x: 0, y: 10)
    }

    private var identitySubtitle: String {
        "From \(viewModel.profile.country). Speaks \(languageSummary)."
    }

    private var displayUsername: String {
        let username = viewModel.profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return username.hasPrefix("@") ? username : "@\(username)"
    }

    private var languageSummary: String {
        let languages = Array(viewModel.profile.languages.prefix(2))
        guard !languages.isEmpty else { return "languages to be added" }
        let suffix = viewModel.profile.languages.count > 2
            ? " +\(viewModel.profile.languages.count - 2)"
            : ""
        return languages.joined(separator: ", ") + suffix
    }

    private var countryBadge: some View {
        VStack(spacing: 5) {
            Text(viewModel.profile.languageFlag)
                .font(.system(size: 24))
            Text(viewModel.profile.countryCode)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.textOnAccent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppColors.textOnAccent.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.textOnAccent.opacity(0.20), lineWidth: 1)
        )
    }

    private var profileStats: some View {
        HStack(spacing: 10) {
            ProfileStatTile(
                systemImage: "calendar.badge.plus",
                value: "\(meetupStore.createdGroupsCount)",
                title: "Events created"
            )
            ProfileStatTile(
                systemImage: "sparkles",
                value: CurrentUserProfileStore.memberSinceText,
                title: "Member since"
            )
        }
    }

    private var aboutSection: some View {
        SectionCard(icon: "person.fill", title: "About",
                    onEdit: canEdit ? { viewModel.presentEditor(.about) } : nil) {
            Text(viewModel.profile.aboutMe)
                .font(.system(size: ProfileMetrics.Font.body, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var languageSection: some View {
        SectionCard(icon: "translate", title: "Languages spoken",
                    onEdit: canEdit ? { viewModel.presentEditor(.languages) } : nil) {
            FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(viewModel.profile.languages, id: \.self) { LanguageChip(language: $0) }
            }
        }
    }

    private var interestSection: some View {
        SectionCard(icon: "heart.circle.fill", title: "Interests",
                    onEdit: canEdit ? { viewModel.presentEditor(.interests) } : nil) {
            FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(viewModel.profile.interests, id: \.self) { InterestChip(interest: $0) }
            }
        }
    }

    private var socialMediaSection: some View {
        SectionCard(icon: "network", title: "Social media",
                    onEdit: canEdit ? { viewModel.presentEditor(.socials) } : nil) {
            if viewModel.hasSocialMedia {
                VStack(alignment: .leading, spacing: 8) {
                    if let instagram = viewModel.instagramHandle {
                        SocialMediaRow(platform: .instagram, handle: instagram)
                    }
                    if let twitter = viewModel.twitterHandle {
                        SocialMediaRow(platform: .twitter, handle: twitter)
                    }
                }
            } else {
                placeholder("Add your Instagram or Twitter handle.")
            }
        }
    }

    private var gallerySection: some View {
        SectionCard(icon: "photo.on.rectangle.angled", title: "Gallery",
                    onEdit: canEdit ? { viewModel.presentEditor(.gallery) } : nil) {
            if viewModel.hasGallery {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.profile.gallery) { photo in
                            galleryThumbnail(photo.imageData)
                                .frame(width: 96, height: 96)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } else {
                placeholder("Add photos from your trips to share with other travelers.")
            }
        }
    }

    private func galleryThumbnail(_ data: Data) -> some View {
        Group {
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                AppColors.accentSurface
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppColors.cardBorder, lineWidth: 1))
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.system(size: ProfileMetrics.Font.body, weight: .medium))
            .foregroundStyle(AppColors.secondaryText.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func editorSheet(for target: ProfileEditTarget) -> some View {
        switch target {
        case .photo:
            ProfilePhotoEditorSheet(
                initialImageData: viewModel.profile.profileImageData,
                fallbackImageName: viewModel.profile.profileImageName,
                onSave: viewModel.updateProfileImage
            )
        case .identity:
            IdentityEditorSheet(
                initialUsername: viewModel.profile.name,
                initialRealName: viewModel.profile.realName,
                initialCountry: viewModel.profile.country,
                onSave: viewModel.updateIdentity
            )
        case .name:
            NameEditorSheet(initialName: viewModel.profile.name, onSave: viewModel.updateName)
        case .about:
            AboutEditorSheet(initialText: viewModel.profile.aboutMe, onSave: viewModel.updateAbout)
        case .languages:
            MultiSelectChipPicker(
                title: "Languages", fieldLabel: "Languages you speak",
                options: CurrentUserProfileStore.availableLanguages, kind: .language,
                minimumSelection: 1, initialSelection: viewModel.profile.languages,
                onSave: viewModel.updateLanguages
            )
        case .interests:
            MultiSelectChipPicker(
                title: "Interests", fieldLabel: "What are you into?",
                options: CurrentUserProfileStore.availableInterests, kind: .interest,
                minimumSelection: 1, initialSelection: viewModel.profile.interests,
                onSave: viewModel.updateInterests
            )
        case .socials:
            SocialsEditorSheet(
                initialInstagram: viewModel.profile.instagramHandle,
                initialTwitter: viewModel.profile.twitterHandle,
                onSave: viewModel.updateSocials
            )
        case .gallery:
            GalleryEditorSheet(initialPhotos: viewModel.profile.gallery, onSave: viewModel.replaceGallery)
        }
    }
}

private struct ProfileStatTile: View {
    let systemImage: String
    let value: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.accentText)
                .frame(width: 30, height: 30)
                .background(AppColors.accentSurface, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .padding(12)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(AppColors.cardBorder, lineWidth: 1))
    }
}

private struct EditPencil: View {
    var onLight: Bool = false
    var label: String = "item"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "pencil")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.accentText)
                .frame(width: 30, height: 30)
                .background(onLight ? AnyShapeStyle(AppColors.textOnAccent) : AnyShapeStyle(AppColors.accentSurface), in: Circle())
                .overlay(Circle().stroke(onLight ? AppColors.textOnAccent.opacity(0.7) : AppColors.cardBorder, lineWidth: 1))
                .shadow(color: AppColors.scrim.opacity(onLight ? 0.18 : 0), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit \(label)")
    }
}

private struct SectionCard<Content: View>: View {
    let icon: String
    let title: String
    var onEdit: (() -> Void)? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.accentText)
                    .frame(width: 30, height: 30)
                    .background(AppColors.accentSurface, in: Circle())
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
                if let onEdit { EditPencil(label: title, action: onEdit) }
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AppColors.cardBorder, lineWidth: 1))
    }
}

private struct EditSheetScaffold<Content: View>: View {
    let title: String
    var canSave: Bool = true
    let onCancel: () -> Void
    let onSave: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding(.horizontal, ProfileMetrics.Layout.screenPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel).foregroundStyle(AppColors.secondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? AppColors.accentText : AppColors.accentDisabled)
                        .disabled(!canSave)
                }
            }
        }
    }
}

private struct EditorFieldLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(AppColors.secondaryText)
            .tracking(0.5)
    }
}

private extension View {
    func profileFieldBackground() -> some View {
        padding(14)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppColors.cardBorder, lineWidth: 1))
    }
}

private enum ChipKind {
    case interest, language
    func emoji(for value: String) -> String {
        switch self {
        case .interest: return InterestStyle.emoji(for: value)
        case .language: return LanguageFlag.emoji(for: value)
        }
    }
}

private struct SelectableChip: View {
    let title: String
    let kind: ChipKind
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(kind.emoji(for: title))
                Text(title).font(.system(size: ProfileMetrics.Font.chip, weight: .medium))
                if isSelected {
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                }
            }
            .foregroundStyle(isSelected ? AppColors.textOnAccent : AppColors.accentText)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? AppColors.brandPrimary : AppColors.accentSurface, in: Capsule())
            .overlay(Capsule().stroke(isSelected ? AppColors.brandPrimary : AppColors.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct MultiSelectChipPicker: View {
    let title: String
    let fieldLabel: String
    let options: [String]
    let kind: ChipKind
    var minimumSelection: Int = 0
    let initialSelection: [String]
    let onSave: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Set<String>
    private let mergedOptions: [String]   // canonical options + any extra selected

    init(title: String, fieldLabel: String, options: [String], kind: ChipKind,
         minimumSelection: Int = 0, initialSelection: [String],
         onSave: @escaping ([String]) -> Void) {
        self.title = title
        self.fieldLabel = fieldLabel
        self.options = options
        self.kind = kind
        self.minimumSelection = minimumSelection
        self.initialSelection = initialSelection
        self.onSave = onSave
        _selection = State(initialValue: Set(initialSelection))
        self.mergedOptions = options + initialSelection.filter { !options.contains($0) }
    }

    private var ordered: [String] { mergedOptions.filter { selection.contains($0) } }
    private var canSave: Bool { selection.count >= minimumSelection && Set(initialSelection) != selection }

    var body: some View {
        EditSheetScaffold(title: title, canSave: canSave,
                          onCancel: { dismiss() },
                          onSave: { onSave(ordered); dismiss() }) {
            VStack(alignment: .leading, spacing: 12) {
                EditorFieldLabel(text: fieldLabel)
                FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(mergedOptions, id: \.self) { option in
                        SelectableChip(title: option, kind: kind, isSelected: selection.contains(option)) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if selection.contains(option) { selection.remove(option) }
                                else { selection.insert(option) }
                            }
                        }
                    }
                }
                if minimumSelection > 0 {
                    Text("Choose at least \(minimumSelection).")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct IdentityEditorSheet: View {
    let initialUsername: String
    let initialRealName: String
    let initialCountry: String
    let onSave: (String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var username: String
    @State private var realName: String
    @State private var country: String
    @FocusState private var focusedName: Bool

    init(
        initialUsername: String,
        initialRealName: String,
        initialCountry: String,
        onSave: @escaping (String, String, String) -> Void
    ) {
        self.initialUsername = initialUsername
        self.initialRealName = initialRealName
        self.initialCountry = initialCountry
        self.onSave = onSave
        _username = State(initialValue: initialUsername)
        _realName = State(initialValue: initialRealName)
        _country = State(initialValue: initialCountry)
    }

    private var normalizedUsername: String {
        SupabaseService.normalizedUsername(username) ?? ""
    }
    private var trimmedRealName: String { realName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedCountry: String { country.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool {
        !normalizedUsername.isEmpty && !trimmedRealName.isEmpty && !trimmedCountry.isEmpty &&
            (normalizedUsername != initialUsername || trimmedRealName != initialRealName || trimmedCountry != initialCountry)
    }

    var body: some View {
        EditSheetScaffold(title: "Profile", canSave: canSave,
                          onCancel: { dismiss() },
                          onSave: { onSave(normalizedUsername, trimmedRealName, trimmedCountry); dismiss() }) {
            VStack(alignment: .leading, spacing: 18) {
                EditorFieldLabel(text: "Username")
                TextField("gloobmate", text: $username)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($focusedName)
                    .onSubmit { if canSave { onSave(normalizedUsername, trimmedRealName, trimmedCountry); dismiss() } }
                    .profileFieldBackground()

                EditorFieldLabel(text: "Real name")
                TextField("Your full name", text: $realName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .profileFieldBackground()

                EditorFieldLabel(text: "Country origin")
                TextField("Indonesia", text: $country)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .profileFieldBackground()

                Text("Your username appears in rooms. Your real name appears on your profile.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear { focusedName = true }
    }
}

private struct NameEditorSheet: View {
    let initialName: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @FocusState private var focused: Bool

    init(initialName: String, onSave: @escaping (String) -> Void) {
        self.initialName = initialName
        self.onSave = onSave
        _name = State(initialValue: initialName)
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmed.isEmpty && trimmed != initialName }

    var body: some View {
        EditSheetScaffold(title: "Name", canSave: canSave,
                          onCancel: { dismiss() },
                          onSave: { onSave(trimmed); dismiss() }) {
            VStack(alignment: .leading, spacing: 10) {
                EditorFieldLabel(text: "Username")
                TextField("gloobmate", text: $name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($focused)
                    .onSubmit { if canSave { onSave(trimmed); dismiss() } }
                    .profileFieldBackground()
                Text("This is how other travelers will see you in rooms and chat.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
        .onAppear { focused = true }
    }
}

private struct AboutEditorSheet: View {
    let initialText: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @FocusState private var focused: Bool
    private let limit = 300

    init(initialText: String, onSave: @escaping (String) -> Void) {
        self.initialText = initialText
        self.onSave = onSave
        _text = State(initialValue: initialText)
    }

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { trimmed != initialText.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        EditSheetScaffold(title: "About", canSave: canSave,
                          onCancel: { dismiss() },
                          onSave: { onSave(trimmed); dismiss() }) {
            VStack(alignment: .leading, spacing: 10) {
                EditorFieldLabel(text: "About you")
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Share what you love about traveling and the meetups you're looking for.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.secondaryText.opacity(0.6))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    TextEditor(text: $text)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.primaryText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 180)
                        .focused($focused)
                        .onChange(of: text) { _, newValue in
                            if newValue.count > limit { text = String(newValue.prefix(limit)) }
                        }
                }
                .profileFieldBackground()
                HStack {
                    Spacer()
                    Text("\(text.count)/\(limit)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear { focused = true }
    }
}

private struct SocialsEditorSheet: View {
    let initialInstagram: String?
    let initialTwitter: String?
    let onSave: (_ instagram: String?, _ twitter: String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var instagram: String
    @State private var twitter: String

    init(initialInstagram: String?, initialTwitter: String?,
         onSave: @escaping (_ instagram: String?, _ twitter: String?) -> Void) {
        self.initialInstagram = initialInstagram
        self.initialTwitter = initialTwitter
        self.onSave = onSave
        _instagram = State(initialValue: initialInstagram ?? "")
        _twitter = State(initialValue: initialTwitter ?? "")
    }

    private var normIG: String? { ProfileViewModel.normalizedHandle(instagram) }
    private var normTW: String? { ProfileViewModel.normalizedHandle(twitter) }
    private var canSave: Bool { normIG != initialInstagram || normTW != initialTwitter }

    var body: some View {
        EditSheetScaffold(title: "Social media", canSave: canSave,
                          onCancel: { dismiss() },
                          onSave: { onSave(normIG, normTW); dismiss() }) {
            VStack(alignment: .leading, spacing: 20) {
                field(label: "Instagram", systemImage: "camera.fill", text: $instagram)
                field(label: "Twitter", systemImage: "at", text: $twitter)
                Text("Leave a field blank to remove that handle. The “@” is added automatically.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func field(label: String, systemImage: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            EditorFieldLabel(text: label)
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.accentText)
                    .frame(width: 24, height: 24)
                TextField("username", text: text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
            }
            .profileFieldBackground()
        }
    }
}

private struct ProfilePhotoEditorSheet: View {
    let initialImageData: Data?
    let fallbackImageName: String
    let onSave: (Data?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var imageData: Data?
    @State private var pickerItem: PhotosPickerItem?
    @State private var isLoading = false

    init(initialImageData: Data?, fallbackImageName: String, onSave: @escaping (Data?) -> Void) {
        self.initialImageData = initialImageData
        self.fallbackImageName = fallbackImageName
        self.onSave = onSave
        _imageData = State(initialValue: initialImageData)
    }

    private var canSave: Bool { imageData != initialImageData }

    var body: some View {
        EditSheetScaffold(title: "Profile photo", canSave: canSave,
                          onCancel: { dismiss() },
                          onSave: { onSave(imageData); dismiss() }) {
            VStack(spacing: 24) {
                ProfileAvatar(imageName: fallbackImageName, imageData: imageData, size: 160)
                    .frame(maxWidth: .infinity)

                VStack(spacing: 12) {
                    PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo").font(.system(size: 15, weight: .bold))
                            Text(isLoading ? "Loading…" : "Choose photo").font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(AppColors.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(AppColors.brandPrimary, in: Capsule())
                    }
                    .disabled(isLoading)
                    .onChange(of: pickerItem) { _, item in Task { await load(item) } }

                    if imageData != nil {
                        Button(role: .destructive) {
                            withAnimation { imageData = nil }
                        } label: {
                            Text("Remove photo")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppColors.destructive)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(AppColors.accentSurface, in: Capsule())
                                .overlay(Capsule().stroke(AppColors.cardBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @MainActor
    private func load(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isLoading = true
        defer { isLoading = false; pickerItem = nil }
        if let data = try? await item.loadTransferable(type: Data.self) {
            withAnimation { imageData = data }
        }
    }
}

private struct GalleryEditorSheet: View {
    let initialPhotos: [GalleryPhoto]
    let onSave: ([GalleryPhoto]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var photos: [GalleryPhoto]
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isLoading = false
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]

    init(initialPhotos: [GalleryPhoto], onSave: @escaping ([GalleryPhoto]) -> Void) {
        self.initialPhotos = initialPhotos
        self.onSave = onSave
        _photos = State(initialValue: initialPhotos)
    }

    private var canSave: Bool { photos.map(\.id) != initialPhotos.map(\.id) }

    var body: some View {
        EditSheetScaffold(title: "Gallery", canSave: canSave,
                          onCancel: { dismiss() },
                          onSave: { onSave(photos); dismiss() }) {
            VStack(alignment: .leading, spacing: 14) {
                PhotosPicker(selection: $pickerItems, maxSelectionCount: 12, matching: .images, photoLibrary: .shared()) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                        Text(isLoading ? "Adding…" : "Add photos").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(AppColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.brandPrimary, in: Capsule())
                }
                .disabled(isLoading)
                .onChange(of: pickerItems) { _, items in Task { await load(items) } }

                if photos.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 30))
                            .foregroundStyle(AppColors.accentText.opacity(0.6))
                        Text("No photos yet").font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColors.primaryText)
                        Text("Add photos from your trips to share with other travelers.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .profileFieldBackground()
                } else {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(photos) { photo in thumbnail(photo) }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func thumbnail(_ photo: GalleryPhoto) -> some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage).resizable().scaledToFill()
                    .frame(height: 110).frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.accentSurface).frame(height: 110)
            }
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { photos.removeAll { $0.id == photo.id } }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.textOnAccent)
                    .frame(width: 24, height: 24)
                    .background(AppColors.scrim.opacity(0.55), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(6)
            .accessibilityLabel("Remove photo")
        }
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppColors.cardBorder, lineWidth: 1))
    }

    @MainActor
    private func load(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        isLoading = true
        defer { isLoading = false; pickerItems = [] }
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photos.append(GalleryPhoto(imageData: data))
            }
        }
    }
}

#Preview("My profile") {
    ProfileView()
}

#Preview("Other member (read-only)") {
    ProfileView(viewModel: ProfileViewModel(profile: .profile(for: "Maria")))
}
