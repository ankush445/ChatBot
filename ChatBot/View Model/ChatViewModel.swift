//
//  ChatBotApp.swift
//  ChatBot
//
//  Created by ios-22 on 30/03/26.
//


import SwiftUI
import FoundationModels
import SwiftData

@MainActor
@Observable
class ChatViewModel {
    
    var sessions: [StoredChatSession] = []
    var messages: [ChatMessage] = []
    var userInput: String = ""
    var isResponding = false
    
    var partial: String.PartiallyGenerated?
    var partialId: UUID?
    var currentSessionID: UUID?
    
    private var streamingTask: Task<Void, Never>?
    private var modelContext: ModelContext?
    private var hasLoadedHistory = false

    var currentSessionTitle: String {
        currentSession?.title ?? "ChatBot"
    }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext

        guard !hasLoadedHistory else { return }
        hasLoadedHistory = true
        loadSessions()

        if let newestSession = sessions.first {
            selectSession(newestSession)
        } else {
            startNewChat()
        }
    }

    func sendMessage() {
        
        guard !isResponding else { return }
        guard currentSession != nil else { return }
        let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        isResponding = true
        let prompt = promptForConversation(adding: trimmedInput)
        
        appendAndPersist(ChatMessage(sender: .user, content: trimmedInput))
        
        self.userInput = ""
        
        streamingTask = Task {
            do {
                let stream = LanguageModelSession().streamResponse(to: prompt)
                self.partialId = UUID()
                
                for try await partial in stream {
                    self.partial = partial.content
                }
                
                guard !Task.isCancelled else { return }
                
                appendAndPersist(
                    ChatMessage(
                        sender: .assistant,
                        content: partial ?? "",
                        id: partialId ?? UUID()
                    )
                )
                
            } catch {
                
                let errorMessage: String

                if let error = error as? FoundationModels.LanguageModelSession.GenerationError {
                    
                    switch error {
                        
                    case .exceededContextWindowSize:
                        errorMessage = "Your request is too long. Please try with a shorter message."
                        
                    case .assetsUnavailable:
                        errorMessage = "AI model is not available right now. Please try again later."
                        
                    case .guardrailViolation:
                        errorMessage = "Your request couldn't be processed due to content restrictions."
                        
                    case .unsupportedGuide:
                        errorMessage = "This feature is not supported. Please try a different request."
                        
                    case .unsupportedLanguageOrLocale:
                        errorMessage = "This language is not supported. Please try in a supported language."
                        
                    case .decodingFailure:
                        errorMessage = "Something went wrong while processing the response. Please try again."
                        
                    case .rateLimited:
                        errorMessage = "Too many requests. Please wait a moment and try again."
                        
                    case .concurrentRequests:
                        errorMessage = "Please wait for the current response to finish before sending another message."
                        
                    case .refusal(_, _):
                        errorMessage = "Something went wrong. Please try again."

                    @unknown default:
                        errorMessage = "Something went wrong. Please try again."
                    }
                    
                } else {
                    errorMessage = "Unexpected error occurred. Please try again."
                }
                
                // 👇 Add error as chat message
                appendAndPersist(
                    ChatMessage(
                        sender: .assistant,
                        content: errorMessage
                    )
                )
            }
            
            // 👇 Always reset state (important)
            await MainActor.run {
                self.isResponding = false
                self.partial = nil
                self.partialId = nil
                self.streamingTask = nil
            }
        }
    }
    
    func startNewChat() {
        cancelStreaming()

        if let currentSession, currentSession.messages.isEmpty {
            selectSession(currentSession)
            return
        }

        guard let modelContext else { return }

        let session = StoredChatSession()
        modelContext.insert(session)
        saveContext()

        sessions.insert(session, at: 0)
        selectSession(session)
    }

    func selectSession(_ session: StoredChatSession) {
        cancelStreaming()
        currentSessionID = session.id
        messages = session.sortedMessages.map(\.chatMessage)
        userInput = ""
    }

    func deleteSessions(at offsets: IndexSet) {
        guard let modelContext else { return }

        let sessionsToDelete = offsets.map { sessions[$0] }

        for session in sessionsToDelete {
            modelContext.delete(session)
        }

        saveContext()
        loadSessions()

        if let currentSessionID,
           !sessions.contains(where: { $0.id == currentSessionID }) {
            if let newestSession = sessions.first {
                selectSession(newestSession)
            } else {
                startNewChat()
            }
        }
    }

    private var currentSession: StoredChatSession? {
        sessions.first(where: { $0.id == currentSessionID })
    }

    private func cancelStreaming() {
        messages = []
        userInput = ""
        isResponding = false
        partial = nil
        partialId = nil
        
        streamingTask?.cancel()
        streamingTask = nil
    }

    private func appendAndPersist(_ message: ChatMessage) {
        messages.append(message)
        persist(message)
    }

    private func persist(_ message: ChatMessage) {
        guard let currentSession else { return }

        currentSession.messages.append(StoredChatMessage(message: message, session: currentSession))
        currentSession.updatedAt = message.timestamp

        if currentSession.title == "New Chat", message.sender == .user {
            currentSession.title = sessionTitle(from: message.content)
        }

        loadSessions()
        saveContext()
    }

    private func loadSessions() {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<StoredChatSession>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        do {
            sessions = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load sessions: \(error.localizedDescription)")
        }
    }

    private func saveContext() {
        guard let modelContext else { return }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save chat history: \(error.localizedDescription)")
        }
    }

    private func promptForConversation(adding latestUserInput: String) -> String {
        guard !messages.isEmpty else { return latestUserInput }

        var lines = [
            "Continue the conversation below and answer the latest user message naturally.",
            ""
        ]

        for message in messages {
            let role = message.sender == .user ? "User" : "Assistant"
            lines.append("\(role): \(message.content)")
        }

        lines.append("User: \(latestUserInput)")
        lines.append("Assistant:")

        return lines.joined(separator: "\n")
    }

    private func sessionTitle(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "New Chat" }

        let limit = 40
        let prefix = String(trimmed.prefix(limit))
        return trimmed.count > limit ? "\(prefix)..." : prefix
    }
}

import Playgrounds

#Playground {
    
    let session = LanguageModelSession(instructions: "You are a dog specialties. Your job is to give helpful advice to new dog owners.")
    
    let prompt = "Can I keep a Border Collie in my apartment? in detail"
    
    do {
        let stream = session.streamResponse(to: prompt)
        
        for try await partial in stream {
            print(partial)
        }
       
    } catch {
        print("error: \(error)")
        if let error = error as? FoundationModels.LanguageModelSession.GenerationError {
            print("error: \(error.localizedDescription)")
        }
    }
}
