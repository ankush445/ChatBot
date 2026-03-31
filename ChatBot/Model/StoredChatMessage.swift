//
//  StoredChatMessage.swift
//  ChatBot
//
//  Created by Codex on 30/03/26.
//

import Foundation
import SwiftData

@Model
final class StoredChatMessage {
    @Attribute(.unique) var id: UUID
    var senderRawValue: String
    var content: String
    var timestamp: Date
    var session: StoredChatSession?

    init(
        id: UUID = UUID(),
        sender: ChatMessage.Sender,
        content: String,
        timestamp: Date = Date(),
        session: StoredChatSession? = nil
    ) {
        self.id = id
        self.senderRawValue = sender.rawValue
        self.content = content
        self.timestamp = timestamp
        self.session = session
    }

    convenience init(message: ChatMessage, session: StoredChatSession) {
        self.init(
            id: message.id,
            sender: message.sender,
            content: message.content,
            timestamp: message.timestamp,
            session: session
        )
    }

    var chatMessage: ChatMessage {
        ChatMessage(
            sender: ChatMessage.Sender(rawValue: senderRawValue) ?? .assistant,
            content: content,
            timestamp: timestamp,
            id: id
        )
    }
}
