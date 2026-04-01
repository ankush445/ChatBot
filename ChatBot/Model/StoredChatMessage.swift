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
    @Attribute(.externalStorage) var imageData: Data?
    var hiddenContext: String?
    var timestamp: Date
    var session: StoredChatSession?

    init(
        id: UUID = UUID(),
        sender: ChatMessage.Sender,
        content: String,
        imageData: Data? = nil,
        hiddenContext: String? = nil,
        timestamp: Date = Date(),
        session: StoredChatSession? = nil
    ) {
        self.id = id
        self.senderRawValue = sender.rawValue
        self.content = content
        self.imageData = imageData
        self.hiddenContext = hiddenContext
        self.timestamp = timestamp
        self.session = session
    }

    convenience init(message: ChatMessage, session: StoredChatSession) {
        self.init(
            id: message.id,
            sender: message.sender,
            content: message.content,
            imageData: message.imageData,
            hiddenContext: message.hiddenContext,
            timestamp: message.timestamp,
            session: session
        )
    }

    var chatMessage: ChatMessage {
        ChatMessage(
            sender: ChatMessage.Sender(rawValue: senderRawValue) ?? .assistant,
            content: content,
            imageData: imageData,
            hiddenContext: hiddenContext,
            timestamp: timestamp,
            id: id
        )
    }
}
