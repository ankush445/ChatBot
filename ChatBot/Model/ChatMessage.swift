//
//  ChatBotApp.swift
//  ChatBot
//
//  Created by ios-22 on 30/03/26.
//


import SwiftUI

struct ChatMessage: Identifiable, Codable {
    
    enum Sender: String, Codable {
        case user, assistant
    }
    
    let id: UUID
    let sender: Sender
    let content: String
    let timestamp: Date
    
    init(sender: Sender,
         content: String,
         timestamp: Date = Date(),
         id: UUID = UUID()) {
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
        self.id = id
    }
}

//MARK: - Previews

extension ChatMessage {
    static var examples: [ChatMessage] {
        [
            ChatMessage(sender: .user,
                        content: "What is a good dog for busy people?"),
            ChatMessage(sender: .assistant,
                        content: "Bulldogs and Chihuahua are good choices for busy people.")
        ]
    }
}
