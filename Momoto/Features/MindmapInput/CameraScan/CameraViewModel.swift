//
//  CameraViewModel.swift
//  MomotoMindmap
//

import SwiftUI
import Combine
import UIKit
import Vision

@MainActor
final class CameraViewModel: ObservableObject {
    enum Phase {
        case scanning
        case textSelection

    }
    
    struct TextSection: Identifiable, Hashable {
        let id: UUID
        let text: String
        let bounds: CGRect
        let topLeft: CGPoint
        let topRight: CGPoint
        let bottomRight: CGPoint
        let bottomLeft: CGPoint
    }
    
    /// Fraction of the scanner height that's visible between the black bars.
    /// 0.6 means 60% middle visible, 20% blacked out top + 20% bottom. Tune freely.
    let visibleHeightRatio: CGFloat = 0.6
    
    // Must stay `var`: EditPreviewView binds through `$viewModel.ocr.scannedText`,
    // which requires a writable key path.
    var ocr = OCRViewModel()

    @Published var phase: Phase = .scanning
    @Published var captureRequestID = 0
    @Published var visibleTextSections: [TextSection] = []
    @Published var capturedTextSections: [TextSection] = []
    @Published var capturedImage: UIImage?
    @Published var capturedPreviewSize: CGSize = .zero
    @Published var cropQuad: CropQuad = .zero
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        ocr.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    var hasError: Bool {
        ocr.errorMessage != nil
    }
    
    var captureDisabled: Bool {
        visibleTextSections.isEmpty
    }
    
    var sectionsInCropCount: Int {
        capturedTextSections.filter { cropQuad.intersects($0.bounds) }.count
    }
    
    func updateRecognizedTextSections(_ sections: [TextSection]) {
        visibleTextSections = sections
    }
    
    func requestCapture() {
        guard !visibleTextSections.isEmpty else {
            ocr.errorMessage = "Point the camera at text before capturing."
            return
        }
        ocr.errorMessage = nil
        captureRequestID += 1
    }
    
    func handleCapturedImage(_ image: UIImage, sections: [TextSection], previewSize: CGSize) {
        guard !sections.isEmpty else {
            ocr.errorMessage = "Point the camera at text before capturing."
            return
        }
        
        // The visible band in scanner-view coordinates.
        let bandHeight = previewSize.height * (1 - visibleHeightRatio) / 2
        let visibleWindow = CGRect(
            x: 0,
            y: bandHeight,
            width: previewSize.width,
            height: previewSize.height - bandHeight * 2
        )
        
        // Crop the photo down to that band.
        let croppedImage = Self.cropImage(image, toViewRect: visibleWindow, viewSize: previewSize)
        
        ocr.isProcessing = true
        ocr.errorMessage = nil
        
        Task {
            do {
                let detectedSections = try await Self.recognizeTextSections(in: croppedImage)
                guard !detectedSections.isEmpty else {
                    ocr.errorMessage = "Point the camera at text inside the frame."
                    ocr.isProcessing = false
                    return
                }
                
                capturedImage = croppedImage
                capturedPreviewSize = croppedImage.size
                capturedTextSections = detectedSections
                
                // Default crop quad inside the now-smaller preview.
                let insetX = croppedImage.size.width * 0.04
                let insetY = croppedImage.size.height * 0.06
                cropQuad = CropQuad(rect: CGRect(
                    x: insetX,
                    y: insetY,
                    width: croppedImage.size.width - insetX * 2,
                    height: croppedImage.size.height - insetY * 2
                ))
                
                ocr.isProcessing = false
                phase = .textSelection
            } catch {
                ocr.errorMessage = "Try again because i cant read the text :("
                ocr.isProcessing = false
            }
        }
    }
    
    func useSelectedSections(onTextCaptured: (String) -> Void) {
        let selectedText = capturedTextSections
            .filter { cropQuad.intersects($0.bounds) }
            .sorted { $0.bounds.minY < $1.bounds.minY }
            .map(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !selectedText.isEmpty else {
            ocr.errorMessage = "Adjust the crop area to include text."
            return
        }
        
        ocr.scannedText = selectedText
        ocr.errorMessage = nil
        onTextCaptured(selectedText)
    }
    
    func handleScannerUnavailable() {
        ocr.errorMessage = "Live text scanning is not available on this device."
    }
    
    func retake() {
        ocr.scannedText = ""
        ocr.errorMessage = nil
        phase = .scanning
        capturedTextSections = []
        capturedImage = nil
        capturedPreviewSize = .zero
        cropQuad = .zero
    }
    
    
    func dismissError() {
        ocr.errorMessage = nil
    }
    
    // Maps the view-space rectangle into image pixel space (assuming aspectFill
    // display) and renders just that region into a new UIImage, respecting orientation.
    private static func cropImage(_ image: UIImage, toViewRect viewRect: CGRect, viewSize: CGSize) -> UIImage {
        let imageSize = image.size
        guard viewSize.width > 0, viewSize.height > 0,
              imageSize.width > 0, imageSize.height > 0 else { return image }
        
        let viewAspect = viewSize.width / viewSize.height
        let imageAspect = imageSize.width / imageSize.height
        
        let scale: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat
        
        if imageAspect > viewAspect {
            // Image wider than view — height fills, sides cropped.
            scale = imageSize.height / viewSize.height
            offsetX = (imageSize.width - viewSize.width * scale) / 2
            offsetY = 0
        } else {
            // Image taller than view — width fills, top/bottom cropped.
            scale = imageSize.width / viewSize.width
            offsetX = 0
            offsetY = (imageSize.height - viewSize.height * scale) / 2
        }
        
        let pixelRect = CGRect(
            x: viewRect.minX * scale + offsetX,
            y: viewRect.minY * scale + offsetY,
            width: viewRect.width * scale,
            height: viewRect.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: pixelRect.size)
        return renderer.image { _ in
            image.draw(at: CGPoint(x: -pixelRect.minX, y: -pixelRect.minY))
        }
    }
    
    private static func recognizeTextSections(in image: UIImage) async throws -> [TextSection] {
        guard let cgImage = image.cgImage else { return [] }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let imageSize = image.size
                let sections = observations.compactMap { observation -> TextSection? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return nil }
                    
                    let textRange = candidate.string.startIndex..<candidate.string.endIndex
                    guard let rectangle = try? candidate.boundingBox(for: textRange) else { return nil }
                    
                    let topLeft = imagePoint(from: rectangle.topLeft, imageSize: imageSize)
                    let topRight = imagePoint(from: rectangle.topRight, imageSize: imageSize)
                    let bottomRight = imagePoint(from: rectangle.bottomRight, imageSize: imageSize)
                    let bottomLeft = imagePoint(from: rectangle.bottomLeft, imageSize: imageSize)
                    let minX = min(topLeft.x, topRight.x, bottomRight.x, bottomLeft.x)
                    let maxX = max(topLeft.x, topRight.x, bottomRight.x, bottomLeft.x)
                    let minY = min(topLeft.y, topRight.y, bottomRight.y, bottomLeft.y)
                    let maxY = max(topLeft.y, topRight.y, bottomRight.y, bottomLeft.y)
                    
                    return TextSection(
                        id: UUID(),
                        text: text,
                        bounds: CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY),
                        topLeft: topLeft,
                        topRight: topRight,
                        bottomRight: bottomRight,
                        bottomLeft: bottomLeft
                    )
                }
                
                continuation.resume(returning: sections)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }
    
    private static func imagePoint(from normalizedPoint: CGPoint, imageSize: CGSize) -> CGPoint {
        CGPoint(
            x: normalizedPoint.x * imageSize.width,
            y: (1 - normalizedPoint.y) * imageSize.height
        )
    }
}
