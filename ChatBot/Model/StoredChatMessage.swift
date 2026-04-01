//
//  StoredChatMessage.swift
//  ChatBot
//
//  Created by Codex on 30/03/26.
//

import Foundation
import SwiftData

extension StoredChatMessage {
    convenience init(message: ChatMessage, session: StoredChatSession) {
        self.init(
            id: message.id,
            senderRawValue: message.sender.rawValue,
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
