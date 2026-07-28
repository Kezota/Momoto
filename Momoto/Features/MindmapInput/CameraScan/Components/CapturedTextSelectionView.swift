//
//  CapturedTextSelectionView.swift
//  MomotoMindmap
//

import SwiftUI

struct CapturedTextSelectionView: View {
    @ObservedObject var viewModel: CameraViewModel
    let onTextCaptured: (String) -> Void
    var body: some View {
        ZStack {
            capturedImageView
            VStack {
                topToolbar
                    .padding(.horizontal, 20)
                Spacer()
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
    
    private var topToolbar: some View {
        HStack {
            Button {
                viewModel.retake()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white))
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
            
            Spacer()
            
            Button {
                viewModel.useSelectedSections(onTextCaptured: onTextCaptured)
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.blue))
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
            }
            .disabled(viewModel.sectionsInCropCount == 0)
            .opacity(viewModel.sectionsInCropCount == 0 ? 0.5 : 1)
        }
    }
    
    @ViewBuilder
    private var capturedImageView: some View {
        if let image = viewModel.capturedImage, viewModel.capturedPreviewSize != .zero {
            GeometryReader { geometry in
                let imageFrame = fittedFrame(
                    in: geometry.size,
                    aspectRatio: viewModel.capturedPreviewSize.width / viewModel.capturedPreviewSize.height
                )

                ZStack(alignment: .topLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageFrame.width, height: imageFrame.height)
                        .clipped()
                        .position(x: imageFrame.midX, y: imageFrame.midY)

                    // Blue highlights only on sections that intersect the crop quad
                    ForEach(viewModel.capturedTextSections.filter { viewModel.cropQuad.intersects($0.bounds) }) { section in
                        TextHighlightShape(points: scaledHighlightPoints(for: section, imageFrame: imageFrame))
                            .fill(Color.blue.opacity(0.35))
                            .overlay(
                                TextHighlightShape(points: scaledHighlightPoints(for: section, imageFrame: imageFrame))
                                    .stroke(Color.blue.opacity(0.75), lineWidth: 1.5)
                            )
                            .mask {
                                Rectangle()
                                    .frame(width: imageFrame.width, height: imageFrame.height)
                                    .position(x: imageFrame.midX, y: imageFrame.midY)
                            }
                            .allowsHitTesting(false)
                    }

                    // Draggable free-form quadrilateral crop
                    CropQuadView(
                        quad: Binding(
                            get: { scaledQuad(for: viewModel.cropQuad, imageFrame: imageFrame) },
                            set: { newQuad in
                                viewModel.cropQuad = unscaledQuad(from: newQuad, imageFrame: imageFrame)
                            }
                        ),
                        bounds: imageFrame
                    )
                }
            }
            .aspectRatio(viewModel.capturedPreviewSize.width / viewModel.capturedPreviewSize.height, contentMode: .fit)
        } else {
            ContentUnavailableView("No captured image", systemImage: "photo")
        }
    }
    
    private func fittedFrame(in containerSize: CGSize, aspectRatio: CGFloat) -> CGRect {
        let containerRatio = containerSize.width / max(containerSize.height, 1)
        let size: CGSize
        
        if containerRatio > aspectRatio {
            let width = containerSize.height * aspectRatio
            size = CGSize(width: width, height: containerSize.height)
        } else {
            let height = containerSize.width / aspectRatio
            size = CGSize(width: containerSize.width, height: height)
        }
        
        return CGRect(
            x: (containerSize.width - size.width) / 2,
            y: (containerSize.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }
    
    private func scaledQuad(for quad: CropQuad, imageFrame: CGRect) -> CropQuad {
        CropQuad(
            topLeft: scaledPoint(quad.topLeft, imageFrame: imageFrame),
            topRight: scaledPoint(quad.topRight, imageFrame: imageFrame),
            bottomRight: scaledPoint(quad.bottomRight, imageFrame: imageFrame),
            bottomLeft: scaledPoint(quad.bottomLeft, imageFrame: imageFrame)
        )
    }
    
    private func scaledHighlightPoints(for section: CameraViewModel.TextSection, imageFrame: CGRect) -> [CGPoint] {
        [
            scaledPoint(section.topLeft, imageFrame: imageFrame),
            scaledPoint(section.topRight, imageFrame: imageFrame),
            scaledPoint(section.bottomRight, imageFrame: imageFrame),
            scaledPoint(section.bottomLeft, imageFrame: imageFrame)
        ]
    }
    
    private func scaledPoint(_ point: CGPoint, imageFrame: CGRect) -> CGPoint {
        let previewSize = viewModel.capturedPreviewSize
        let scaleX = imageFrame.width / max(previewSize.width, 1)
        let scaleY = imageFrame.height / max(previewSize.height, 1)
        
        return CGPoint(
            x: imageFrame.minX + point.x * scaleX,
            y: imageFrame.minY + point.y * scaleY
        )
    }
    
    private func unscaledQuad(from quad: CropQuad, imageFrame: CGRect) -> CropQuad {
        CropQuad(
            topLeft: unscaledPoint(quad.topLeft, imageFrame: imageFrame),
            topRight: unscaledPoint(quad.topRight, imageFrame: imageFrame),
            bottomRight: unscaledPoint(quad.bottomRight, imageFrame: imageFrame),
            bottomLeft: unscaledPoint(quad.bottomLeft, imageFrame: imageFrame)
        )
    }

    private func unscaledPoint(_ point: CGPoint, imageFrame: CGRect) -> CGPoint {
        let previewSize = viewModel.capturedPreviewSize
        let scaleX = previewSize.width / max(imageFrame.width, 1)
        let scaleY = previewSize.height / max(imageFrame.height, 1)

        return CGPoint(
            x: (point.x - imageFrame.minX) * scaleX,
            y: (point.y - imageFrame.minY) * scaleY
        )
    }
}

private struct TextHighlightShape: Shape {
    let points: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let firstPoint = points.first else { return path }
        
        path.move(to: firstPoint)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private struct CropQuadView: View {
    @Binding var quad: CropQuad
    let bounds: CGRect

    @State private var startQuad: CropQuad? = nil

    var body: some View {
        ZStack {
            // Quad outline: draggable to move the whole selection.
            CropQuadShape(quad: quad)
                .stroke(Color.white, lineWidth: 2)
                .background(
                    CropQuadShape(quad: quad)
                        .fill(Color.white.opacity(0.001)) // makes the interior hit-testable
                )
                .gesture(moveGesture)

            // Independent corner handles
            ForEach(Array(CropQuad.Corner.allCases.enumerated()), id: \.offset) { _, corner in
                handle(for: corner)
            }
        }
    }

    private func handle(for corner: CropQuad.Corner) -> some View {
        let position = quad[corner]
        let visualSize: CGFloat = 32
        let touchSize: CGFloat = 48

        return Circle()
            .fill(Color.white)
            .frame(width: visualSize, height: visualSize)
            .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
            .frame(width: touchSize, height: touchSize) // larger invisible touch target
            .contentShape(Circle())
            .position(x: position.x, y: position.y)
            .gesture(cornerGesture(corner: corner))
    }

    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if startQuad == nil { startQuad = quad }
                guard let start = startQuad else { return }

                let box = start.boundingRect
                // Clamp the translation so the whole quad stays inside the image.
                let dx = min(
                    max(value.translation.width, bounds.minX - box.minX),
                    bounds.maxX - box.maxX
                )
                let dy = min(
                    max(value.translation.height, bounds.minY - box.minY),
                    bounds.maxY - box.maxY
                )
                quad = start.translated(byX: dx, y: dy)
            }
            .onEnded { _ in startQuad = nil }
    }

    private func cornerGesture(corner: CropQuad.Corner) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if startQuad == nil { startQuad = quad }
                guard let start = startQuad else { return }

                let origin = start[corner]
                var moved = start
                moved[corner] = CGPoint(
                    x: min(max(origin.x + value.translation.width, bounds.minX), bounds.maxX),
                    y: min(max(origin.y + value.translation.height, bounds.minY), bounds.maxY)
                )
                quad = moved
            }
            .onEnded { _ in startQuad = nil }
    }
}

private struct CropQuadShape: Shape {
    let quad: CropQuad

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let pts = quad.points
        guard let first = pts.first else { return path }

        path.move(to: first)
        for point in pts.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}
