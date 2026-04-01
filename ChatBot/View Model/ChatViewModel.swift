//
//  ChatBotApp.swift
//  ChatBot
//
//  Created by ios-22 on 30/03/26.
//


import SwiftUI
import FoundationModels
import SwiftData
import PhotosUI
import UIKit

@MainActor
@Observable
class ChatViewModel {
    
    var sessions: [StoredChatSession] = []
    var messages: [ChatMessage] = []
    var userInput: String = ""
    var isResponding = false
    var selectedImage: UIImage?
    var imageAnalysisSummary: String?
    var imageAnalysisStatus: String?
    var isAnalyzingImage = false
    
    var partial: String.PartiallyGenerated?
    var partialId: UUID?
    var currentSessionID: UUID?
    
    private var streamingTask: Task<Void, Never>?
    private var modelContext: ModelContext?
    private var hasLoadedHistory = false
    private let imageAnalyzer = ImageVisionAnalyzer()

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
        let selectedImage = selectedImage
        let selectedImageData = selectedImage?.jpegData(compressionQuality: 0.85)
        let cachedImageSummary = imageAnalysisSummary

        guard !trimmedInput.isEmpty || selectedImage != nil else { return }

        isResponding = true
        self.userInput = ""

        streamingTask = Task {
            do {
                let hiddenVisionContext = try await buildHiddenVisionContext(
                    text: trimmedInput,
                    image: selectedImage,
                    cachedSummary: cachedImageSummary
                )
                let visibleUserMessage = trimmedInput
                let prompt = promptForConversation(
                    adding: visibleUserMessage,
                    hiddenContext: hiddenVisionContext
                )

                appendAndPersist(
                    ChatMessage(
                        sender: .user,
                        content: visibleUserMessage,
                        imageData: selectedImageData,
                        hiddenContext: hiddenVisionContext
                    )
                )
                clearSelectedImage()

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
                if !trimmedInput.isEmpty {
                    self.userInput = trimmedInput
                }

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
                    
                } else if let error = error as? ImageVisionAnalyzer.AnalysisError {
                    errorMessage = error.errorDescription ?? "The selected image could not be analyzed."
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

    func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item else {
            clearSelectedImage()
            return
        }

        isAnalyzingImage = true
        imageAnalysisStatus = "Preparing image..."
        imageAnalysisSummary = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw ImageVisionAnalyzer.AnalysisError.invalidImage
            }

            selectedImage = image
            imageAnalysisStatus = "Reading image with Vision..."

            let analysis = try await imageAnalyzer.analyze(image)
            imageAnalysisSummary = analysis.summary
            imageAnalysisStatus = analysis.statusLine
        } catch {
            imageAnalysisSummary = nil

            if let error = error as? ImageVisionAnalyzer.AnalysisError {
                imageAnalysisStatus = error.errorDescription
            } else {
                imageAnalysisStatus = "The selected image could not be analyzed."
            }
        }

        isAnalyzingImage = false
    }

    func removeSelectedImage() {
        clearSelectedImage()
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
        userInput = ""
        clearSelectedImage()
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

    private func buildHiddenVisionContext(
        text: String,
        image: UIImage?,
        cachedSummary: String?
    ) async throws -> String {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var parts: [String] = []

        if let image {
            let summary: String

            if let cachedSummary, !cachedSummary.isEmpty {
                summary = cachedSummary
            } else {
                self.isAnalyzingImage = true
                self.imageAnalysisStatus = "Reading image with Vision..."
                defer { self.isAnalyzingImage = false }

                let analysis = try await imageAnalyzer.analyze(image)
                self.imageAnalysisSummary = analysis.summary
                self.imageAnalysisStatus = analysis.statusLine
                summary = analysis.summary
            }

            let imageSection = """
            Attached image context extracted with Vision:
            \(summary)
            """
            parts.append(imageSection)
        }

        return parts.joined(separator: "\n\n")
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

    private func promptForConversation(
        adding latestUserInput: String,
        hiddenContext: String?
    ) -> String {
        let latestPrompt = promptText(for: latestUserInput, hiddenContext: hiddenContext)
        guard !messages.isEmpty else { return latestPrompt }

        var lines = [
            "Continue the conversation below and answer the latest user message naturally.",
            ""
        ]

        for message in messages {
            let role = message.sender == .user ? "User" : "Assistant"
            lines.append("\(role): \(promptText(for: message.content, hiddenContext: message.hiddenContext))")
        }

        lines.append("User: \(latestPrompt)")
        lines.append("Assistant:")

        return lines.joined(separator: "\n")
    }

    private func sessionTitle(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Image" }

        let limit = 40
        let prefix = String(trimmed.prefix(limit))
        return trimmed.count > limit ? "\(prefix)..." : prefix
    }

    private func clearSelectedImage() {
        selectedImage = nil
        imageAnalysisSummary = nil
        imageAnalysisStatus = nil
        isAnalyzingImage = false
    }

    private func promptText(for content: String, hiddenContext: String?) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHiddenContext = hiddenContext?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        switch (trimmedContent.isEmpty, trimmedHiddenContext.isEmpty) {
        case (false, false):
            return "\(trimmedContent)\n\n\(trimmedHiddenContext)"
        case (false, true):
            return trimmedContent
        case (true, false):
            return trimmedHiddenContext
        case (true, true):
            return ""
        }
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
