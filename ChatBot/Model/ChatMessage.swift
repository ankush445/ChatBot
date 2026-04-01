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
    let imageData: Data?
    let hiddenContext: String?
    let timestamp: Date
    
    init(sender: Sender,
         content: String,
         imageData: Data? = nil,
         hiddenContext: String? = nil,
         timestamp: Date = Date(),
         id: UUID = UUID()) {
        self.sender = sender
        self.content = content
        self.imageData = imageData
        self.hiddenContext = hiddenContext
        self.timestamp = timestamp
        self.id = id
    }

    var uiImage: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
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
