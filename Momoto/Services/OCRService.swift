//
//  OCRService.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//
import Foundation
import UIKit
import Vision

enum OCRError: Error {
    case noImage
    case recognitionFailed(Error)
}

struct OCRService {
    func recognizeText(in images: [UIImage]) async throws -> String { //Recognize text from MANY images
        guard !images.isEmpty else {
            throw OCRError.noImage
        }
        
        var pages: [String] = []
        for image in images {
            let pageText = try await recognizeText(in: image)
            if !pageText.isEmpty { pages.append(pageText) }
        }
        return pages.joined(separator: "/n/n")
    }
    func recognizeText(in image: UIImage) async throws -> String { //Recognize text from one image
        guard let cgImage = image.cgImage else {return ""}
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }
}
