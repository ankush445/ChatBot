//
//  StoredChatSession.swift
//  ChatBot
//
//  Created by Codex on 31/03/26.
//

import Foundation
import SwiftData

extension StoredChatSession {
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
