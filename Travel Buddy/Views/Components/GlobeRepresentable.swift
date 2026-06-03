//
//  GlobeRepresentable.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//

import SwiftUI
import CoreLocation

struct GlobeRepresentable: UIViewRepresentable, Equatable {
    var location: CLLocation?

    static func == (lhs: GlobeRepresentable, rhs: GlobeRepresentable) -> Bool {
        switch (lhs.location, rhs.location) {
        case (nil, nil):
            return true
        case let (left?, right?):
            return left.coordinate.latitude == right.coordinate.latitude
                && left.coordinate.longitude == right.coordinate.longitude
        default:
            return false
        }
    }
    
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
