//
//  GlobeRepresentable.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//

import SwiftUI
import CoreLocation

struct GlobeRepresentable: UIViewRepresentable {
    var location: CLLocation?
    
    func makeUIView(context: Context) -> GlobeView {
        return GlobeView(frame: .zero)
    }
    
    func updateUIView(_ uiView: GlobeView, context: Context) {
        if let location = location {
            print("[DEBUG] Rotating globe to: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            uiView.rotateToLocation(location)
        }
    }
}
