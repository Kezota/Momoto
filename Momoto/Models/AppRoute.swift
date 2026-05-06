//
//  AppRoute.swift
//  MomotoMindmap
//

import Foundation

enum AppRoute: Hashable {
    case scan
    case pdf
    case paste
    case processing
    case mindmap(MindMap)
    case chatbot
    case history
    case photo
}
