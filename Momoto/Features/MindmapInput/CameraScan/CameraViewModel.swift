//
//  CameraViewModel.swift
//  MomotoMindmap
//

import SwiftUI
import Combine
import UIKit

@MainActor
final class CameraViewModel: ObservableObject {
    enum ActiveSheet: Identifiable {
        case textSelection
        case capturedText
        
        var id: String {
            switch self {
            case .textSelection: "textSelection"
            case .capturedText: "capturedText"
            }
        }
    }
    
    struct TextSection: Identifiable, Hashable {
        let id: UUID
        let text: String
        let bounds: CGRect
        var isIncluded: Bool = true
    }
    
    var ocr = OCRViewModel()
    
    @Published var activeSheet: ActiveSheet?
    @Published var captureRequestID = 0
    @Published var visibleTextSections: [TextSection] = []
    @Published var capturedTextSections: [TextSection] = []
    @Published var capturedImage: UIImage?
    @Published var capturedPreviewSize: CGSize = .zero
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
    
    var captureDisabled: Bool {
        visibleTextSections.isEmpty
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
        
        capturedImage = image
        capturedPreviewSize = previewSize
        capturedTextSections = sections
        activeSheet = .textSelection
    }
    
    func toggleCapturedSection(_ section: TextSection) {
        guard let index = capturedTextSections.firstIndex(where: { $0.id == section.id }) else { return }
        capturedTextSections[index].isIncluded.toggle()
    }
    
    func useSelectedSections() {
        let selectedText = capturedTextSections
            .filter(\.isIncluded)
            .map(\.text)
            .joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !selectedText.isEmpty else {
            ocr.errorMessage = "Choose at least one text section to continue."
            return
        }
        
        ocr.scannedText = selectedText
        ocr.errorMessage = nil
        activeSheet = .capturedText
    }
    
    func handleScannerUnavailable() {
        ocr.errorMessage = "Live text scanning is not available on this device."
    }
    
    func retake() {
        clear()
        activeSheet = nil
        capturedTextSections = []
        capturedImage = nil
        capturedPreviewSize = .zero
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
