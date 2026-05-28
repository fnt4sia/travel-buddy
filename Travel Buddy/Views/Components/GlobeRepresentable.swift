//
//  GlobeRepresentable.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//

import SwiftUI

struct GlobeRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> GlobeView {
        return GlobeView(frame: .zero)
    }
    
    func updateUIView(_ uiView: GlobeView, context: Context) {}
}
