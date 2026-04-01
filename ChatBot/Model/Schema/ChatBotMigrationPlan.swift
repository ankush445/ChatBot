//
//  ChatBotMigrationPlan.swift
//  ChatBot
//
//  Created by Codex on 01/04/26.
//

import SwiftData

enum ChatBotMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            ChatBotSchemaV1.self,
            ChatBotSchemaV2.self
        ]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: ChatBotSchemaV1.self, toVersion: ChatBotSchemaV2.self)
        ]
    }
}
