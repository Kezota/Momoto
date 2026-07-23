//
//  CropQuad.swift
//  Momoto
//
//  Created by Teresa Tendeas on 19/07/26.
//

import CoreGraphics

// An arbitrary convex-ish quadrilateral used for cropping.
// Corners move independently — it is not constrained to a rectangle.
struct CropQuad: Equatable {
    enum Corner: CaseIterable {
        case topLeft, topRight, bottomRight, bottomLeft
    }

    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomRight: CGPoint
    var bottomLeft: CGPoint

    static let zero = CropQuad(
        topLeft: .zero, topRight: .zero, bottomRight: .zero, bottomLeft: .zero
    )

    // Clockwise order, starting top-left.
    var points: [CGPoint] { [topLeft, topRight, bottomRight, bottomLeft] }

    var boundingRect: CGRect {
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return .zero }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    init(topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }

    // Seeds a quad from a rectangle (used for the default crop).
    init(rect: CGRect) {
        self.init(
            topLeft: CGPoint(x: rect.minX, y: rect.minY),
            topRight: CGPoint(x: rect.maxX, y: rect.minY),
            bottomRight: CGPoint(x: rect.maxX, y: rect.maxY),
            bottomLeft: CGPoint(x: rect.minX, y: rect.maxY)
        )
    }

    subscript(corner: Corner) -> CGPoint {
        get {
            switch corner {
            case .topLeft: return topLeft
            case .topRight: return topRight
            case .bottomRight: return bottomRight
            case .bottomLeft: return bottomLeft
            }
        }
        set {
            switch corner {
            case .topLeft: topLeft = newValue
            case .topRight: topRight = newValue
            case .bottomRight: bottomRight = newValue
            case .bottomLeft: bottomLeft = newValue
            }
        }
    }

    func translated(byX dx: CGFloat, y dy: CGFloat) -> CropQuad {
        CropQuad(
            topLeft: CGPoint(x: topLeft.x + dx, y: topLeft.y + dy),
            topRight: CGPoint(x: topRight.x + dx, y: topRight.y + dy),
            bottomRight: CGPoint(x: bottomRight.x + dx, y: bottomRight.y + dy),
            bottomLeft: CGPoint(x: bottomLeft.x + dx, y: bottomLeft.y + dy)
        )
    }

    // Ray-casting point-in-polygon test.
    func contains(_ point: CGPoint) -> Bool {
        let pts = points
        var inside = false
        var j = pts.count - 1
        for i in 0..<pts.count {
            let a = pts[i]
            let b = pts[j]
            if (a.y > point.y) != (b.y > point.y) {
                let t = (point.y - a.y) / (b.y - a.y)
                if point.x < a.x + t * (b.x - a.x) { inside.toggle() }
            }
            j = i
        }
        return inside
    }

    // Replacement for `CGRect.intersects` — true if the rect overlaps the quad at all.
    func intersects(_ rect: CGRect) -> Bool {
        guard boundingRect.intersects(rect) else { return false }

        let rectCorners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]

        // Rect corner inside quad, or quad corner inside rect.
        if rectCorners.contains(where: { contains($0) }) { return true }
        if points.contains(where: { rect.contains($0) }) { return true }

        // Crossing edges without either set of corners being contained.
        let quadPts = points
        for i in 0..<quadPts.count {
            let a = quadPts[i]
            let b = quadPts[(i + 1) % quadPts.count]
            for j in 0..<rectCorners.count {
                let c = rectCorners[j]
                let d = rectCorners[(j + 1) % rectCorners.count]
                if Self.segmentsIntersect(a, b, c, d) { return true }
            }
        }
        return false
    }

    private static func segmentsIntersect(
        _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint
    ) -> Bool {
        func cross(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
            (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
        }
        let d1 = cross(p3, p4, p1)
        let d2 = cross(p3, p4, p2)
        let d3 = cross(p1, p2, p3)
        let d4 = cross(p1, p2, p4)
        return ((d1 > 0) != (d2 > 0)) && ((d3 > 0) != (d4 > 0))
    }
}
