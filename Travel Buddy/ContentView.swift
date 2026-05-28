//
//  ContentView.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 20/05/26.
//

import SwiftUI

struct ContentView: View {
    @State private var hasOnboarded = UserDefaults.standard.bool(forKey: "hasOnboarded")

    var body: some View {
        if hasOnboarded {
            Text("Main App")
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
