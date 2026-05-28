//
//  LocationPermissionView.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//

import SwiftUI
import SceneKit

// Bridge UIKit GlobeView into SwiftUI
struct GlobeRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> GlobeView {
        return GlobeView(frame: .zero)  // ← fixes "Missing argument for frame"
    }
    func updateUIView(_ uiView: GlobeView, context: Context) {}
}

struct LocationPermissionView: View {
    @StateObject private var viewModel = LocationPermissionViewModel()

    var body: some View {
        ZStack {
            GlobeRepresentable()  // ← use this instead of GlobeView() directly
                .ignoresSafeArea()

            VStack {
                Spacer()
                Text("Enable your Location 📍")
                    .font(.largeTitle).bold()

                Text("Location access allows you to find recommended local activities.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    Task { await viewModel.allowLocationTapped() }
                }) {
                    Text(viewModel.isLoading ? "Finding location..." : "Allow location access")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding()
            }
        }
        .navigationDestination(isPresented: $viewModel.navigateToConfirm) {
            LocationConfirmView(city: viewModel.city ?? "your city")  // create this next
        }
    }
}
