//
//  PDFTextService.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import Foundation
import PDFKit

enum PDFTextService {
    static func extract(from url: URL) -> String {
        guard let document = PDFDocument(url: url) else { return "" }
        var text = ""
        for index in 0..<document.pageCount {
            if let pageText = document.page(at: index)?.string {
                text += pageText + "\n"
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
