//
//  LiveTextScannerView.swift
//  MomotoMindmap
//

import SwiftUI
import UIKit
import VisionKit

struct LiveTextScannerView: UIViewControllerRepresentable {
    @Binding var captureRequestID: Int
    let onTextSectionsChanged: ([CameraViewModel.TextSection]) -> Void
    let onImageCaptured: (UIImage, [CameraViewModel.TextSection], CGSize) -> Void
    let onUnavailable: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        guard DataScannerViewController.isSupported,
              DataScannerViewController.isAvailable else {
            DispatchQueue.main.async {
                onUnavailable()
            }
            return UIViewController()
        }
        
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        
        DispatchQueue.main.async {
            try? scanner.startScanning()
        }
        
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let scanner = uiViewController as? DataScannerViewController else { return }
        context.coordinator.captureIfNeeded(
            requestID: captureRequestID,
            scanner: scanner,
            onImageCaptured: onImageCaptured
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTextSectionsChanged: onTextSectionsChanged)
    }
    
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onTextSectionsChanged: ([CameraViewModel.TextSection]) -> Void
        private var lastCaptureRequestID = 0
        private var currentSections: [CameraViewModel.TextSection] = []
        
        init(onTextSectionsChanged: @escaping ([CameraViewModel.TextSection]) -> Void) {
            self.onTextSectionsChanged = onTextSectionsChanged
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            updateTextSections(from: allItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            updateTextSections(from: allItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            updateTextSections(from: allItems)
        }
        
        func captureIfNeeded(
            requestID: Int,
            scanner: DataScannerViewController,
            onImageCaptured: @escaping (UIImage, [CameraViewModel.TextSection], CGSize) -> Void
        ) {
            guard requestID != lastCaptureRequestID else { return }
            lastCaptureRequestID = requestID
            
            let sections = currentSections
            let previewSize = scanner.view.bounds.size
            
            Task { @MainActor in
                do {
                    let image = try await scanner.capturePhoto()
                    onImageCaptured(image, sections, previewSize)
                } catch {
                    onTextSectionsChanged([])
                }
            }
        }
        
        private func updateTextSections(from items: [RecognizedItem]) {
            let sections = items.compactMap { item -> CameraViewModel.TextSection? in
                guard case .text(let text) = item else { return nil }
                let transcript = text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !transcript.isEmpty else { return nil }
                
                let bounds = text.bounds
                let rect = CGRect(
                    x: min(bounds.topLeft.x, bounds.bottomLeft.x),
                    y: min(bounds.topLeft.y, bounds.topRight.y),
                    width: max(bounds.topRight.x, bounds.bottomRight.x) - min(bounds.topLeft.x, bounds.bottomLeft.x),
                    height: max(bounds.bottomLeft.y, bounds.bottomRight.y) - min(bounds.topLeft.y, bounds.topRight.y)
                )
                
                return CameraViewModel.TextSection(id: text.id, text: transcript, bounds: rect)
            }
            
            currentSections = sections
            onTextSectionsChanged(sections)
        }
    }
}
