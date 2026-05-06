//
//  UploadFileViewModel.swift
//  MomotoMindmap
//

import Foundation
import Combine

@MainActor
final class UploadFileViewModel: ObservableObject {
    @Published var isWorking: Bool = false
    @Published var errorMessage: String?
    @Published var extractedText: String = ""
    
    var hasError: Bool {
        errorMessage != nil
    }
    
    func dismissError() {
        errorMessage = nil
    }
    
    func handleURL(_ url: URL) {
        errorMessage = nil
        isWorking = true
        
        Task {
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }
            
            let text = PDFTextService.extract(from: url)
            
            await MainActor.run {
                self.isWorking = false
                guard !text.isEmpty else {
                    self.errorMessage = "No readable text found in this PDF."
                    return
                }
                self.extractedText = text
            }
        }
    }
    
    func clear() {
        extractedText = ""
        errorMessage = nil
    }
}
