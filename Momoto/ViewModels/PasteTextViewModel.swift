//
//  PasteTextViewModel.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import Foundation
import Combine

@MainActor
final class PasteTextViewModel: ObservableObject {
    @Published var text: String = ""
    private let minChars = 40
    
    var isSubmitDisabled: Bool {
        text.count < minChars
    }
    
    func submit(onSubmit: (String) -> Void) {
        guard text.count >= minChars else { return }
        onSubmit(text)
    }
}
