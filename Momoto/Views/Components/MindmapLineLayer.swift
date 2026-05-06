//
//  MindmapLineLayer.swift
//  MomotoMindmap
//

import SwiftUI

struct MindmapLineLayer: View {
    let positions: [UUID: NodePosition]
    let size: CGSize
    
    var body: some View {
        Canvas { context, _ in
            for (_, pos) in positions {
                guard let parentID = pos.parentID,
                      let parentPos = positions[parentID] else { continue }
                
                let startX = parentPos.origin.x + MindmapNodeView.width
                let startY = parentPos.origin.y + MindmapNodeView.height / 2
                let endX   = pos.origin.x
                let endY   = pos.origin.y + MindmapNodeView.height / 2
                let midX   = (startX + endX) / 2
                
                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                path.addCurve(
                    to: CGPoint(x: endX, y: endY),
                    control1: CGPoint(x: midX, y: startY),
                    control2: CGPoint(x: midX, y: endY)
                )
                context.stroke(path,
                               with: .color(Theme.textSecondary.opacity(0.6)),
                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
