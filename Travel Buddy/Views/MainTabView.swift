import SwiftUI

enum MainTab: CaseIterable {
    case messages
    case explore
    case profile

    var title: String {
        switch self {
        case .messages:
            return "Messages"
        case .explore:
            return "Explore"
        case .profile:
            return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .messages:
            return "bubble.left.fill"
        case .explore:
            return "globe.asia.australia.fill"
        case .profile:
            return "person.crop.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .messages:
            return Color(red: 0.04, green: 0.38, blue: 0.48)
        case .explore:
            return Color(red: 0.35, green: 0.55, blue: 0.37)
        case .profile:
            return .black
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: MainTab = .explore

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .messages:
                    MessagesView()
                case .explore:
                    MainMapView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            MainTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
        }
        .ignoresSafeArea(.keyboard)
    }
}

private struct MainTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                } label: {
                    MainTabItem(tab: tab, isSelected: selectedTab == tab)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(.white.opacity(0.92), in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 14)
    }
}

private struct MainTabItem: View {
    let tab: MainTab
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: tab.icon)
                .font(.system(size: tab == .explore ? 29 : 26, weight: .semibold))

            Text(tab.title)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(isSelected ? tab.tint : .black)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if isSelected {
                Capsule()
                    .fill(Color.black.opacity(0.08))
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
