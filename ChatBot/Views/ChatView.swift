//
//  ChatBotApp.swift
//  ChatBot
//
//  Created by ios-22 on 30/03/26.
//

import SwiftUI
import FoundationModels

struct ChatView: View {
    
    let messages: [ChatMessage]
    let isLoading: Bool
    
    let partial: String.PartiallyGenerated?
    let partialId: UUID?
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(messages) { message in
                    ChatMessageBubble(message: message)
                }
                
                if let partial, let id = partialId {
                    StreamingResponseView(partial: partial)
                        .id(id)
                } else if isLoading {
                    ProgressView()
                }
                    
            }
            .padding()
            .padding(.bottom, 100)
        }
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let image = message.uiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if !message.content.isEmpty {
                MarkdownText(markdown: message.content)
            }
        }
        .modifier(StreamingViewModifier(sender: message.sender))
    }
}

struct StreamingResponseView: View {
    
    let partial: String.PartiallyGenerated
    
    var body: some View {
        MarkdownText(markdown: partial)
            .modifier(StreamingViewModifier(sender: .assistant))
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.7), value: partial)
    }
}


struct StreamingViewModifier: ViewModifier {
    
    let sender: ChatMessage.Sender
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(sender == .user ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(sender == .user ? .leading : .trailing, 20)
            .frame(maxWidth: .infinity,
                   alignment: sender == .user ? .trailing : .leading)
    }
}

#Preview {
    ChatView(messages: ChatMessage.examples,
             isLoading: false,
             partial: nil,
             partialId: nil)
}
