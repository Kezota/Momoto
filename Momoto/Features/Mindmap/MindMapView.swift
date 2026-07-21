//
//  MindMapView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI

struct MindMapView: View {
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: MindmapViewModel
    let mindMap: MindMap
    
    init(mindMap: MindMap) {
        self.mindMap = mindMap
        _viewModel = StateObject(wrappedValue: MindmapViewModel(mindMap: mindMap))
    }
    
    // Pan (geser canvas)
    @State private var offset: CGSize = CGSize(width: 40, height: 100)
    @GestureState private var dragDelta: CGSize = .zero
    
    // Zoom (pinch)
    @State private var scale: CGFloat = 1.0
    @GestureState private var pinchDelta: CGFloat = 1.0
    
    // Popup long-press
    @State private var poppedNode: MindMapNode? = nil
    @State private var showChat: Bool = false
    
    private var liveScale: CGFloat {
        min(max(scale * pinchDelta, 0.4), 2.5)
    }
    
    private var chatFab: some View {
        Button {
            showChat = true
        } label: {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 70, height: 100)
                .background(
                    Circle().fill(Color.purple)
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var liveOffset: CGSize {
        CGSize(width: offset.width + dragDelta.width,
               height: offset.height + dragDelta.height)
    }

    // Screen-space frame of a node, projecting its canvas position through the
    // current pan/zoom so the edit menu anchor is computed independently of any
    // ancestor transform (UIEditMenuInteraction positions unreliably when its
    // host view sits inside a scaled/offset SwiftUI hierarchy).
    private func screenFrame(for pos: NodePosition) -> CGRect {
        CGRect(
            x: liveOffset.width + pos.origin.x * liveScale,
            y: liveOffset.height + pos.origin.y * liveScale,
            width: MindmapNodeView.width * liveScale,
            height: MindmapNodeView.height * liveScale
        )
    }

    @ViewBuilder
    private var editMenuAnchor: some View {
        if let menuNodeID = viewModel.showFloatingMenuForNodeID,
           viewModel.editingNodeID == nil,
           let pos = viewModel.cachedLayout.positions[menuNodeID] {
            let frame = screenFrame(for: pos)
            Color.clear
                .frame(width: frame.width, height: frame.height)
                .background(
                    EditMenuBridge(
                        isPresented: true,
                        sections: editMenuSections(for: pos.node),
                        onDismiss: {
                            viewModel.showFloatingMenuForNodeID = nil
                        }
                    )
                )
                .position(x: frame.midX, y: frame.midY)
                .allowsHitTesting(false)
        }
    }

    private func editMenuSections(for node: MindMapNode) -> [EditMenuSection] {
        let isRoot = node.id == viewModel.mindMap.root.id
        return [
            EditMenuSection([
                EditMenuAction(title: isRoot ? "" : "Cut", icon: "scissors") {
                    viewModel.cutNode(node)
                },
                EditMenuAction(title: "Copy", icon: "doc.on.doc") {
                    viewModel.copyNode(node)
                },
                EditMenuAction(title: "Paste", icon: "doc.on.clipboard") {
                    viewModel.pasteNode(to: node.id)
                }
            ].filter { !$0.title.isEmpty }, isCompact: true),
            EditMenuSection([
                EditMenuAction(title: "Rename", icon: "pencil") {
                    viewModel.editingNodeID = node.id
                },
                EditMenuAction(title: "Change Icon", icon: "square.grid.2x2") {
                    viewModel.iconPickerNodeID = node.id
                },
                EditMenuAction(title: isRoot ? "" : "Duplicate", icon: "plus.square.on.square") {
                    if let newID = viewModel.duplicateNode(node) {
                        viewModel.selectedNodeID = newID
                    }
                }
            ].filter { !$0.title.isEmpty }),
            EditMenuSection([
                EditMenuAction(title: "Delete", icon: "trash", isDestructive: true) {
                    viewModel.deleteNode(nodeID: node.id)
                }
            ]),
            EditMenuSection([
                EditMenuAction(
                    title: node.children.isEmpty ? "" : (node.isExpanded ? "Fold" : "Unfold"),
                    icon: node.isExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical"
                ) {
                    viewModel.toggleExpand(nodeID: node.id)
                }
            ].filter { !$0.title.isEmpty }),
            EditMenuSection([
                EditMenuAction(title: "Add Child", icon: "arrow.right.circle") {
                    let newID = viewModel.addChild(to: node.id)
                    viewModel.selectedNodeID = newID
                    viewModel.editingNodeID = newID
                },
                EditMenuAction(title: isRoot ? "" : "Add Sibling", icon: "arrow.down.circle") {
                    if let newID = viewModel.addSibling(to: node.id) {
                        viewModel.selectedNodeID = newID
                        viewModel.editingNodeID = newID
                    }
                }
            ].filter { !$0.title.isEmpty }),
            EditMenuSection([
                EditMenuAction(title: "Grow Ideas", icon: "sparkles") {
                    viewModel.growIdeas(for: node)
                }
            ]),
            EditMenuSection([
                EditMenuAction(title: "Detail", icon: "info.circle") {
                    poppedNode = node
                }
            ])
        ]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Theme.white
                    .ignoresSafeArea()
                    .onTapGesture {
                        if viewModel.isEditModeActive {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.selectedNodeID = nil
                                viewModel.editingNodeID = nil
                                viewModel.showFloatingMenuForNodeID = nil
                            }
                        }
                    }
                
                // Mindmap Content Layer
                ZStack(alignment: .topLeading) {
                    MindmapLineLayer(positions: viewModel.cachedLayout.positions, size: viewModel.contentSize)
                    MindmapNodeLayer(viewModel: viewModel) { node in
                        poppedNode = node
                    }
                }
                .scaleEffect(liveScale, anchor: .topLeading)
                .offset(liveOffset)
                // Constrain the layout size to the viewport to prevent the parent from expanding
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)

                // Edit menu anchor — deliberately sits OUTSIDE the scaled/offset canvas above
                // so its computed screen frame is the source of truth, not an ancestor transform.
                editMenuAnchor
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)

                // Info Overlay (Fixed Position)
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Theme.purple)
                        Text(viewModel.isEditModeActive ? "Hold any node to show the edit toolbar" : "Hold any node to view its summary")
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundStyle(Theme.textPrimary)
                            .contentTransition(.numericText())
                            .animation(.easeInOut, value: viewModel.isEditModeActive)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: Theme.black.opacity(0.05), radius: 10, y: 4)
                    .padding(.top, 110)
                    .opacity(poppedNode == nil ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: poppedNode)
                    .allowsHitTesting(false)
                    
                    Spacer()
                }
                
                // Chat FAB (Fixed Position)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        chatFab
                            .padding(.trailing, 20)
                            .padding(.bottom, 34)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                // Node Popup
                if let node = poppedNode {
                    NodePopup(node: node) {
                        withAnimation(.easeInOut(duration: 0.2)) { poppedNode = nil }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 15)
                .updating($dragDelta) { value, state, _ in state = value.translation }
                .onEnded { offset.width += $0.translation.width; offset.height += $0.translation.height }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .updating($pinchDelta) { value, state, _ in state = value }
                .onEnded { scale = min(max(scale * $0, 0.4), 2.5) }
        )
        .animation(.easeInOut(duration: 0.2), value: poppedNode?.id)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    appState.path = NavigationPath()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.isEditModeActive.toggle()
                        if !viewModel.isEditModeActive {
                            viewModel.selectedNodeID = nil
                            viewModel.editingNodeID = nil
                            viewModel.showFloatingMenuForNodeID = nil
                        }
                    }
                } label: {
                    Text(viewModel.isEditModeActive ? "Done" : "Edit")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.purple)
                }
            }
        }
        .sheet(isPresented: $showChat) {
            NavigationStack {
                ChatbotView(context: viewModel.modelContext)
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.iconPickerNodeID != nil },
            set: { if !$0 { viewModel.iconPickerNodeID = nil } }
        )) {
            if let nodeID = viewModel.iconPickerNodeID, let node = viewModel.findNode(id: nodeID) {
                IconPickerView(currentSymbol: node.symbol) { symbol in
                    viewModel.setSymbol(nodeID: nodeID, symbol: symbol)
                }
            }
        }
    }
    
}

#Preview {
    let node = MindMapNode(title: "Preview", symbol: "star", summary: "Preview node", children: [], isExpanded: true)
    let map = MindMap(id: UUID(), title: "Preview", root: node, rawText: "", createdAt: .now, source: "Preview")

    NavigationStack {
        MindMapView(mindMap: map)
            .navigationBarTitleDisplayMode(.inline)
    }
}
