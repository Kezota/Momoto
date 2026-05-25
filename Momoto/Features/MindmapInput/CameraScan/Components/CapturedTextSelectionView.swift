//
//  CapturedTextSelectionView.swift
//  MomotoMindmap
//

import SwiftUI

struct CapturedTextSelectionView: View {
    @ObservedObject var viewModel: CameraViewModel
    
    private var hasSelectedSections: Bool {
        viewModel.capturedTextSections.contains { $0.isIncluded }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tap highlighted text you do not want to include.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 12)
                    
                    capturedImageView
                    
                    Button {
                        viewModel.useSelectedSections()
                    } label: {
                        Text("Review Captured Text")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.red, isFullWidth: true))
                    .disabled(!hasSelectedSections)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Choose Text")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
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
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .position(x: imageFrame.midX, y: imageFrame.midY)
                    
                    ForEach(viewModel.capturedTextSections) { section in
                        let rect = scaledRect(for: section.bounds, imageFrame: imageFrame)
                        
                        Button {
                            viewModel.toggleCapturedSection(section)
                        } label: {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(section.isIncluded ? Theme.green.opacity(0.28) : Theme.red.opacity(0.18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(section.isIncluded ? Theme.green : Theme.red, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .frame(width: max(rect.width, 32), height: max(rect.height, 28))
                        .position(x: rect.midX, y: rect.midY)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(viewModel.capturedPreviewSize.width / viewModel.capturedPreviewSize.height, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
        } else {
            ContentUnavailableView("No captured image", systemImage: "photo")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}
