//
//  CameraViewModel.swift
//  MomotoMindmap
//

import SwiftUI
import Combine

@MainActor
final class CameraViewModel: ObservableObject {
    
    var ocr = OCRViewModel()
    
    @Published var showCapturedTextSheet: Bool = false
    @Published var isScannerPresented: Bool = true
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        ocr.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    var generateDisabled: Bool {
        ocr.scannedText.trimmingCharacters(in: .whitespacesAndNewlines).count < 10
    }
    
    var hasError: Bool {
        ocr.errorMessage != nil
    }
    
    func processScannedImages(_ images: [UIImage]) {
        Task {
            _ = await ocr.processScannedPages(images)
            if !self.ocr.scannedText.isEmpty {
                self.showCapturedTextSheet = true
            }
        }
    }
    
    func retake() {
        clear()
        showCapturedTextSheet = false
        isScannerPresented = true
    }
    
    func clear() {
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
