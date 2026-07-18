//
//  AppRoute.swift
//  MomotoMindmap
//

import Foundation

enum AppRoute: Hashable {
    case scan
    case pdf
    case paste
    case preferences
    case processing
    case mindmap(MindMap)
    case chatbot
    case history
    case photo
}
