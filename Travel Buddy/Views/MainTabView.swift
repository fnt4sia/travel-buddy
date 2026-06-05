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
        AppColors.brandPrimary
    }
}

struct MainTabView: View {
    @State private var selectedTab: MainTab = .explore
    @State private var messagePath: [UUID] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .messages:
                    MessagesView(chatPath: $messagePath)
                case .explore:
                    MainMapView(onOpenChat: openMessageRoom)
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsTabBar {
                MainTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 48)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard)
        .animation(.easeInOut(duration: 0.22), value: showsTabBar)
    }

    private var showsTabBar: Bool {
        selectedTab != .messages || messagePath.isEmpty
    }

    private func openMessageRoom(_ groupID: UUID) {
        messagePath = [groupID]
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            selectedTab = .messages
        }
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
        .padding(3)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(AppColors.surface.opacity(0.94), in: Capsule())
        .overlay(Capsule().stroke(AppColors.cardBorder, lineWidth: 1))
        .shadow(color: AppColors.brandPrimary.opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

private struct MainTabItem: View {
    let tab: MainTab
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: tab.icon)
                .font(.system(size: tab == .explore ? 22 : 20, weight: .semibold))

            Text(tab.title)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(isSelected ? tab.tint : AppColors.secondaryText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if isSelected {
                Capsule()
                    .fill(AppColors.accentSurface)
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
