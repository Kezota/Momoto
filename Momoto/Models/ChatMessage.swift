//
//  ChatMessage.swift
//  MomotoMindmap
//
//  Created by Ken on 05/05/26.
//

import Foundation

struct ChatMessage: Identifiable, Hashable {
    enum Role {
        case user
        case assistant
    }
    let id: UUID
    let role: Role
    var text: String
    let timestamp: Date

    init(id: UUID = UUID(), role: Role, text: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}
