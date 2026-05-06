//
//  CameraViewModel.swift
//  MomotoMindmap
//

import SwiftUI
import Combine

@MainActor
final class CameraViewModel: ObservableObject {
    let camera = CameraSessionService()
    let ocr = OCRViewModel()
    
    @Published var capturedImage: UIImage?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        camera.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        ocr.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    var displayText: String {
        if ocr.isProcessing { return "Reading text…" }
        if ocr.scannedText.isEmpty { return "Tap the shutter to capture text." }
        return ocr.scannedText
    }
    
    var generateDisabled: Bool {
        ocr.scannedText.trimmingCharacters(in: .whitespacesAndNewlines).count < 10
    }
    
    var clearDisabled: Bool {
        capturedImage == nil && ocr.scannedText.isEmpty
    }
    
    var hasError: Bool {
        ocr.errorMessage != nil
    }
    
    func bootstrap() {
        camera.bootstrap()
    }
    
    func stop() {
        camera.stop()
    }
    
    func handleShutter() {
        Task {
            guard let image = await camera.capturePhoto() else { return }
            self.capturedImage = image
            _ = await ocr.processScannedPages([image])
        }
    }
    
    func clear() {
        capturedImage = nil
        ocr.scannedText = ""
        ocr.errorMessage = nil
    }
    
    func handleGenerate(onTextCaptured: (String) -> Void) {
        let text = ocr.scannedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onTextCaptured(text)
    }
    
    func dismissError() {
        ocr.errorMessage = nil
    }
}
