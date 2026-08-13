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

    // Zoom (pinch). Tracks where the pinch started so the zoom can be anchored under the
    // user's fingers instead of the canvas origin.
    @State private var scale: CGFloat = 1.0
    private struct PinchState {
        var magnification: CGFloat = 1
        var location: CGPoint = .zero
        var isActive = false
    }
    @GestureState private var pinch = PinchState()

    // Popup long-press
    @State private var poppedNode: MindMapNode? = nil
    @State private var showChat: Bool = false

    // Export
    @State private var exportedImage: UIImage? = nil
    @State private var showShareSheet: Bool = false
    @State private var isExportingImage: Bool = false
    
    private var liveScale: CGFloat {
        min(max(scale * pinch.magnification, 0.4), 2.5)
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
                    Circle().fill(Theme.purple)
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // The canvas transform is S = offset + point × scale (scaled about .topLeading). Zooming
    // about the fingers means solving for the offset that keeps the canvas point currently
    // under the pinch location fixed on screen: offset' = L − (L − offset) × m.
    private var liveOffset: CGSize {
        var base = CGSize(width: offset.width + dragDelta.width,
                          height: offset.height + dragDelta.height)
        if pinch.isActive {
            let m = liveScale / scale
            base = CGSize(
                width: pinch.location.x - (pinch.location.x - base.width) * m,
                height: pinch.location.y - (pinch.location.y - base.height) * m
            )
        }
        return base
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
            height: pos.height * liveScale
        )
    }

    // Renders the full tree (current fold/unfold state) to an image, independent of the
    // on-screen pan/zoom, so exports always capture the whole mindmap rather than the viewport.
    @MainActor
    private func renderMindmapImage() -> UIImage? {
        let exportView = MindmapExportView(
            positions: viewModel.cachedLayout.positions,
            contentSize: viewModel.contentSize
        )
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    // Kicks off the render with a visible loading state and only opens the share sheet once
    // the image is fully ready — ImageRenderer can return a blank first frame if the share
    // sheet is presented in the same tick the render was requested.
    private func exportAndShare() {
        isExportingImage = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            exportedImage = renderMindmapImage()
            isExportingImage = false
            if exportedImage != nil {
                showShareSheet = true
            }
        }
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
                (viewModel.isEditModeActive ? Theme.purple.opacity(0.05) : Theme.white)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isEditModeActive)
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

                // Info Overlay (Fixed Position) — a solid, distinct badge while editing so the
                // mode change reads clearly at a glance, not just via the toolbar button.
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isEditModeActive ? "pencil.circle.fill" : "info.circle.fill")
                            .foregroundStyle(viewModel.isEditModeActive ? .white : Theme.purple)
                        Text(viewModel.isEditModeActive ? "Editing. Hold a node for options" : "Hold a node to see its summary")
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundStyle(viewModel.isEditModeActive ? .white : Theme.textPrimary)
                            .contentTransition(.numericText())
                            .animation(.easeInOut, value: viewModel.isEditModeActive)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule().fill(viewModel.isEditModeActive ? AnyShapeStyle(Theme.purple) : AnyShapeStyle(.ultraThinMaterial))
                    )
                    .shadow(color: Theme.black.opacity(0.05), radius: 10, y: 4)
                    .padding(.top, 110)
                    .opacity(poppedNode == nil ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: poppedNode)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isEditModeActive)
                    .allowsHitTesting(false)

                    Spacer()
                }

                // Edit-mode frame — a thin border around the whole canvas so the active
                // editing state stays visible even when scrolled away from the toolbar/badge.
                if viewModel.isEditModeActive {
                    Rectangle()
                        .stroke(Theme.purple, lineWidth: 3)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
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
            MagnifyGesture()
                .updating($pinch) { value, state, _ in
                    state = PinchState(
                        magnification: value.magnification,
                        location: value.startLocation,
                        isActive: true
                    )
                }
                .onEnded { value in
                    let newScale = min(max(scale * value.magnification, 0.4), 2.5)
                    let m = newScale / scale
                    offset = CGSize(
                        width: value.startLocation.x - (value.startLocation.x - offset.width) * m,
                        height: value.startLocation.y - (value.startLocation.y - offset.height) * m
                    )
                    scale = newScale
                }
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
                if viewModel.isEditModeActive {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.isEditModeActive = false
                            viewModel.selectedNodeID = nil
                            viewModel.editingNodeID = nil
                            viewModel.showFloatingMenuForNodeID = nil
                        }
                    } label: {
                        Text("Done")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.purple)
                    }
                } else {
                    Menu {
                        Button {
                            exportAndShare()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.isEditModeActive = true
                            }
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    } label: {
                        if isExportingImage {
                            ProgressView()
                        } else {
                            Image(systemName: "ellipsis")
                        }
                    }
                    .disabled(isExportingImage)
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
        .sheet(isPresented: $showShareSheet) {
            if let exportedImage {
                ShareSheet(activityItems: [exportedImage])
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
