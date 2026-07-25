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

    @Published var selectedItem: PhotosPickerItem?
    
    let ocr = OCRViewModel()
    
    var hasError: Bool {
        errorMessage != nil || ocr.errorMessage != nil
    }
    
    func dismissError() {
        errorMessage = nil
        ocr.errorMessage = nil
    }
    
    func handleSelectedItem(_ item: PhotosPickerItem, onExtracted: @escaping (String) -> Void) {
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
                            onExtracted(text)
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
}
