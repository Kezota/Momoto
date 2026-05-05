//
//  MindMapView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI

struct MindMapView: View {

    @StateObject private var viewModel = MindmapViewModel()

    // Layout di-cache agar tidak recompute setiap frame saat pinch
    @State private var cachedLayout: LayoutResult = LayoutResult(positions: [:], totalHeight: 0)

    // Pan (geser canvas)
    @State private var offset: CGSize = CGSize(width: 40, height: 100)
    @GestureState private var dragDelta: CGSize = .zero

    // Zoom (pinch)
    @State private var scale: CGFloat = 1.0
    @GestureState private var pinchDelta: CGFloat = 1.0

    // Popup long-press
    @State private var poppedNode: MindMapNode? = nil

    private let columnSpacing: CGFloat = 60
    private let rowSpacing: CGFloat = 20

    // Nilai zoom aktif saat gestur berlangsung
    private var liveScale: CGFloat {
        min(max(scale * pinchDelta, 0.4), 2.5)
    }

    // Nilai offset aktif saat gestur berlangsung
    private var liveOffset: CGSize {
        CGSize(width: offset.width + dragDelta.width,
               height: offset.height + dragDelta.height)
    }

    var body: some View {
        let contentSize = canvasSize(positions: cachedLayout.positions)

        ZStack {
            // Canvas putih full layar
            Color.white

            // Konten mindmap
            ZStack(alignment: .topLeading) {
                lineLayer(positions: cachedLayout.positions, size: contentSize)
                nodeLayer(positions: cachedLayout.positions)
            }
            .scaleEffect(liveScale, anchor: .topLeading)
            .offset(liveOffset)

            // Popup yang muncul saat long-press
            if let node = poppedNode {
                NodePopup(node: node) {
                    withAnimation(.easeInOut(duration: 0.2)) { poppedNode = nil }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        // Frame harus explicitly full screen agar gesture area tidak mengecil saat zoom out
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        // contentShape memastikan seluruh area layar bisa menerima gesture
        .contentShape(Rectangle())
        // Gestur geser canvas (1 jari)
        .simultaneousGesture(
            DragGesture(minimumDistance: 15)
                .updating($dragDelta) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    offset.width  += value.translation.width
                    offset.height += value.translation.height
                }
        )
        // Gestur zoom (2 jari / pinch)
        .simultaneousGesture(
            MagnificationGesture()
                .updating($pinchDelta) { value, state, _ in
                    state = value
                }
                .onEnded { value in
                    scale = min(max(scale * value, 0.4), 2.5)
                }
        )
        .animation(.easeInOut(duration: 0.2), value: poppedNode?.id)
        .onAppear {
            cachedLayout = buildLayout(node: viewModel.mindMap.root, depth: 0, startY: 0)
        }
        // Recompute layout hanya saat data mindmap berubah (bukan saat zoom/pan)
        .onChange(of: viewModel.mindMap) { _, _ in
            cachedLayout = buildLayout(node: viewModel.mindMap.root, depth: 0, startY: 0)
        }
    }

    // MARK: - Garis koneksi

    private func lineLayer(positions: [UUID: NodePosition], size: CGSize) -> some View {
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
                               with: .color(Color.gray.opacity(0.4)),
                               style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - Node bubbles

    private func nodeLayer(positions: [UUID: NodePosition]) -> some View {
        ForEach(Array(positions.values), id: \.id) { pos in
            MindmapNodeView(
                node: pos.node,
                depth: pos.depth,
                isSelected: viewModel.selectedNodeID == pos.node.id
            )
            .offset(x: pos.origin.x, y: pos.origin.y)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.selectNode(nodeID: pos.node.id)
                    if !pos.node.children.isEmpty {
                        viewModel.toggleExpand(nodeID: pos.node.id)
                    }
                }
            }
            .onLongPressGesture(minimumDuration: 0.45) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    poppedNode = pos.node
                }
            }
        }
    }

    // MARK: - Layout engine

    struct NodePosition {
        let id: UUID
        let node: MindMapNode
        let depth: Int
        let origin: CGPoint
        let parentID: UUID?
    }

    struct LayoutResult {
        var positions: [UUID: NodePosition]
        var totalHeight: CGFloat
    }

    private func buildLayout(node: MindMapNode, depth: Int, startY: CGFloat, parentID: UUID? = nil) -> LayoutResult {
        var positions: [UUID: NodePosition] = [:]
        let x = CGFloat(depth) * (MindmapNodeView.width + columnSpacing)

        if node.isExpanded && !node.children.isEmpty {
            var childY = startY
            var childPositions: [UUID: NodePosition] = [:]

            for child in node.children {
                let result = buildLayout(node: child, depth: depth + 1, startY: childY, parentID: node.id)
                childPositions.merge(result.positions) { _, new in new }
                childY += result.totalHeight + rowSpacing
            }

            let subtreeHeight = childY - startY - rowSpacing
            let centreY = startY + subtreeHeight / 2 - MindmapNodeView.height / 2

            positions[node.id] = NodePosition(id: node.id, node: node, depth: depth,
                                              origin: CGPoint(x: x, y: centreY),
                                              parentID: parentID)
            positions.merge(childPositions) { _, new in new }
            return LayoutResult(positions: positions, totalHeight: subtreeHeight)
        } else {
            positions[node.id] = NodePosition(id: node.id, node: node, depth: depth,
                                              origin: CGPoint(x: x, y: startY),
                                              parentID: parentID)
            return LayoutResult(positions: positions, totalHeight: MindmapNodeView.height)
        }
    }

    private func canvasSize(positions: [UUID: NodePosition]) -> CGSize {
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        for pos in positions.values {
            maxX = max(maxX, pos.origin.x + MindmapNodeView.width)
            maxY = max(maxY, pos.origin.y + MindmapNodeView.height)
        }
        return CGSize(width: maxX, height: maxY)
    }
}

// MARK: - Popup

private struct NodePopup: View {
    let node: MindMapNode
    let onDismiss: () -> Void

    var body: some View {
        // Background tipis buat detect tap di luar card
        Color.black.opacity(0.15)
            .ignoresSafeArea()
            .onTapGesture { onDismiss() }
            .overlay {
                // Card kecil di tengah layar
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(node.title)
                            .font(.headline)
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                        }
                    }

                    Divider()

                    if let summary = node.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Tidak ada ringkasan.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .frame(maxWidth: 300)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                )
            }
    }
}

#Preview {
    MindMapView()
}
