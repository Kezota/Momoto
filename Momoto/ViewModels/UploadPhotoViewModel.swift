//
//  UploadPhotoViewModel.swift
//  MomotoMindmap
//

import SwiftUI
import Combine
import PhotosUI

@MainActor
final class UploadPhotoViewModel: ObservableObject {
    @Published var isWorking: Bool = false
    @Published var errorMessage: String?
    @Published var extractedText: String = ""
    @Published var selectedItem: PhotosPickerItem? {
        didSet {
            if let selectedItem {
                handleSelectedItem(selectedItem)
            }
        }
    }
    
    let ocr = OCRViewModel()
    
    var hasError: Bool {
        errorMessage != nil || ocr.errorMessage != nil
    }
    
    func dismissError() {
        errorMessage = nil
        ocr.errorMessage = nil
    }
    
    private func handleSelectedItem(_ item: PhotosPickerItem) {
        errorMessage = nil
        isWorking = true
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    
                    let text = await ocr.processScannedPages([image])
                    
                    await MainActor.run {
                        self.isWorking = false
                        if let text = text, !text.isEmpty {
                            self.extractedText = text
                        } else {
                            self.errorMessage = ocr.errorMessage ?? "No readable text found in this photo."
                        }
                    }
                } else {
                    await MainActor.run {
                        self.isWorking = false
                        self.errorMessage = "Failed to load the image."
                    }
                }
            } catch {
                await MainActor.run {
                    self.isWorking = false
                    self.errorMessage = "Failed to load image: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func clear() {
        extractedText = ""
        errorMessage = nil
        selectedItem = nil
        ocr.scannedText = ""
        ocr.errorMessage = nil
    }
}
