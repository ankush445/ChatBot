//
//  ChatBotApp.swift
//  ChatBot
//
//  Created by ios-22 on 30/03/26.
//

import SwiftUI
import SwiftData

@main
struct ChatBotApp: App {
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StoredChatSession.self,
            StoredChatMessage.self
        ])

        return try! ModelContainer(for: schema)
    }()

    var body: some Scene {
        WindowGroup {
            AvailabilityView()
        }
        .modelContainer(sharedModelContainer)
    }
}

import FoundationModels

struct AvailabilityView: View {
    
    private var model = SystemLanguageModel.default
    
    var body: some View {
        switch model.availability {
            case .available:
                ContentView()
            case .unavailable(.modelNotReady):
                Text("The model is not ready yet. Please come back later.")
            case .unavailable(.appleIntelligenceNotEnabled):
                Text("Apple Intelligence is not enabled on this device. Please turn on Apple Intelligence.")
                
            case .unavailable(.deviceNotEligible):
                Text("This device is not eligible for Apple Intelligence.")
                
            case .unavailable(let other):
            Text("An unknown error occurred: \(String(describing: other))")
        }
    }
}
