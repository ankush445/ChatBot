//
//  ChatBotSchemaV2.swift
//  ChatBot
//
//  Created by Codex on 01/04/26.
//

import Foundation
import SwiftData

enum ChatBotSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            StoredChatSession.self,
            StoredChatMessage.self
        ]
    }

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
    }

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
            senderRawValue: String,
            content: String,
            imageData: Data? = nil,
            hiddenContext: String? = nil,
            timestamp: Date = Date(),
            session: StoredChatSession? = nil
        ) {
            self.id = id
            self.senderRawValue = senderRawValue
            self.content = content
            self.imageData = imageData
            self.hiddenContext = hiddenContext
            self.timestamp = timestamp
            self.session = session
        }
    }
}
