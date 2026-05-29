//
//  ContentView.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 20/05/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        if hasOnboarded {
            MainTabView()
        } else {
            NavigationStack {
                UnifiedOnboardingView()
            }
        }
    }
}

#Preview {
    ContentView()
}
