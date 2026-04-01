//
//  StoredChatSession.swift
//  ChatBot
//
//  Created by Codex on 31/03/26.
//

import Foundation
import SwiftData

@Model
final class StoredChatSession {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \StoredChatMessage.session)
    var messages: [StoredChatMessage] = []

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var sortedMessages: [StoredChatMessage] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }

    var previewText: String {
        guard let lastMessage = sortedMessages.last else {
            return "No messages yet"
        }

        if !lastMessage.content.isEmpty {
            return lastMessage.content
        }

        if lastMessage.imageData != nil {
            return "Image"
        }

        return "No messages yet"
    }
}
