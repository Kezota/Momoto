//
//  ErrorModel.swift
//  Momoto
//
//  Created by Kezia Meilany Tandapai on 07/05/26.
//

import Foundation

enum OCRError: Error {
    case noImage
    case recognitionFailed(Error)
}

enum TextToNodeError: LocalizedError {
    case inputTooShort
    case invalidJSON(String)
    case emptyResult
    case aiFailure(String)

    var errorDescription: String? {
        switch self {
        case .inputTooShort:
            return "Input text is too short to generate a mind map."
        case .invalidJSON(let detail):
            return "Failed to parse AI response as JSON: \(detail)"
        case .emptyResult:
            return "AI returned an empty response."
        case .aiFailure(let detail):
            return "AI processing failed: \(detail)"
        }
    }
}
