//
//  OCRViewModel.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import Foundation
import UIKit
import Combine

@MainActor
final class OCRViewModel: ObservableObject {
    @Published var scannedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
    private let ocrService: OCRService
    nonisolated init(ocrService: OCRService = OCRService()) {
        self.ocrService = ocrService
    }
    
    func processScannedPages(_ images: [UIImage]) async -> String? {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }
        
        do {
            let text = try await ocrService.recognizeText(in: images)
            scannedText = text
            return text
        } catch {
            errorMessage = "Try again because i cant read the text :("
            return nil
        }
    }
//    func useSampleText() -> String {                   //Buat sample kalau butuh
//        let sample = MindMapNode.sampleRawText
//        scannedText = sample
//        return sample
//    }
}
