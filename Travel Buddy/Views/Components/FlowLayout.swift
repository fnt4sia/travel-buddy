//
//  FlowLayout.swift
//  Travel Buddy
//
//  Created by Balqis Putri Muharda on 02/06/26.
//

import SwiftUI

struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = ProfileMetrics.Layout.chipSpacing
    var verticalSpacing: CGFloat = ProfileMetrics.Layout.chipSpacing

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widestLine: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += lineHeight + verticalSpacing
                x = 0
                lineHeight = 0
            }
            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
            widestLine = max(widestLine, x - horizontalSpacing)
        }

        let width = maxWidth.isFinite ? maxWidth : widestLine
        return CGSize(width: width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += lineHeight + verticalSpacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
