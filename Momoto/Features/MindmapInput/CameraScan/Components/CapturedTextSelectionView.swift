//
//  CapturedTextSelectionView.swift
//  MomotoMindmap
//

import SwiftUI

struct CapturedTextSelectionView: View {
    @ObservedObject var viewModel: CameraViewModel
    
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
                viewModel.useSelectedSections()
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
                let cropFrame = scaledRect(for: viewModel.cropRect, imageFrame: imageFrame)
                
                ZStack(alignment: .topLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageFrame.width, height: imageFrame.height)
                        .clipped()
                        .position(x: imageFrame.midX, y: imageFrame.midY)
                    
                    // Blue highlights only on sections that intersect the crop rect
                    ForEach(viewModel.capturedTextSections.filter { viewModel.cropRect.intersects($0.bounds) }) { section in
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
                    
                    // Draggable / resizable crop rectangle
                    CropRectangleView(
                        rect: Binding(
                            get: { cropFrame },
                            set: { newRect in
                                viewModel.cropRect = unscaledRect(from: newRect, imageFrame: imageFrame)
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
    
    private func scaledRect(for bounds: CGRect, imageFrame: CGRect) -> CGRect {
        let previewSize = viewModel.capturedPreviewSize
        let scaleX = imageFrame.width / max(previewSize.width, 1)
        let scaleY = imageFrame.height / max(previewSize.height, 1)
        
        return CGRect(
            x: imageFrame.minX + bounds.minX * scaleX,
            y: imageFrame.minY + bounds.minY * scaleY,
            width: bounds.width * scaleX,
            height: bounds.height * scaleY
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
    
    private func unscaledRect(from rect: CGRect, imageFrame: CGRect) -> CGRect {
        let previewSize = viewModel.capturedPreviewSize
        let scaleX = previewSize.width / max(imageFrame.width, 1)
        let scaleY = previewSize.height / max(imageFrame.height, 1)
        
        return CGRect(
            x: (rect.minX - imageFrame.minX) * scaleX,
            y: (rect.minY - imageFrame.minY) * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
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

private struct CropRectangleView: View {
    @Binding var rect: CGRect
    let bounds: CGRect
    
    @State private var startRect: CGRect? = nil
    
    private enum Corner { case topLeft, topRight, bottomLeft, bottomRight }
    
    var body: some View {
        ZStack {
            // Body of crop rectangle: white outline, draggable to move.
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .background(Color.white.opacity(0.001)) // makes whole rect hit-testable
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .gesture(moveGesture)
            
            // Corner handles
            handle(at: CGPoint(x: rect.minX, y: rect.minY), corner: .topLeft)
            handle(at: CGPoint(x: rect.maxX, y: rect.minY), corner: .topRight)
            handle(at: CGPoint(x: rect.minX, y: rect.maxY), corner: .bottomLeft)
            handle(at: CGPoint(x: rect.maxX, y: rect.maxY), corner: .bottomRight)
        }
    }
    
    private func handle(at position: CGPoint, corner: Corner) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 22, height: 22)
            .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
            .position(x: position.x, y: position.y)
            .gesture(resizeGesture(corner: corner))
    }
    
    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if startRect == nil { startRect = rect }
                guard let start = startRect else { return }
                
                let newX = max(bounds.minX, min(bounds.maxX - start.width, start.minX + value.translation.width))
                let newY = max(bounds.minY, min(bounds.maxY - start.height, start.minY + value.translation.height))
                rect = CGRect(x: newX, y: newY, width: start.width, height: start.height)
            }
            .onEnded { _ in startRect = nil }
    }
    
    private func resizeGesture(corner: Corner) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if startRect == nil { startRect = rect }
                guard let start = startRect else { return }
                
                let minSize: CGFloat = 60
                var minX = start.minX
                var minY = start.minY
                var maxX = start.maxX
                var maxY = start.maxY
                
                switch corner {
                case .topLeft:
                    minX = max(bounds.minX, min(maxX - minSize, start.minX + value.translation.width))
                    minY = max(bounds.minY, min(maxY - minSize, start.minY + value.translation.height))
                case .topRight:
                    maxX = max(minX + minSize, min(bounds.maxX, start.maxX + value.translation.width))
                    minY = max(bounds.minY, min(maxY - minSize, start.minY + value.translation.height))
                case .bottomLeft:
                    minX = max(bounds.minX, min(maxX - minSize, start.minX + value.translation.width))
                    maxY = max(minY + minSize, min(bounds.maxY, start.maxY + value.translation.height))
                case .bottomRight:
                    maxX = max(minX + minSize, min(bounds.maxX, start.maxX + value.translation.width))
                    maxY = max(minY + minSize, min(bounds.maxY, start.maxY + value.translation.height))
                }
                
                rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            }
            .onEnded { _ in startRect = nil }
    }
}
