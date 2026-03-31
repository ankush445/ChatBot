//
//  ChatBotApp.swift
//  ChatBot
//
//  Created by ios-22 on 30/03/26.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ChatViewModel()
    @State private var showSessions = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.messages.isEmpty {
                    SuggestionsView(viewModel: viewModel)
                        .frame(maxHeight: .infinity)
                } else {
                    ChatView(messages: viewModel.messages,
                             isLoading: viewModel.isResponding,
                             partial: viewModel.partial,
                             partialId: viewModel.partialId)
                }
                
                Divider()
                HStack {
                    TextField("Write a question here...", text: $viewModel.userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            viewModel.sendMessage()
                        }
                    Button("Send") {
                        viewModel.sendMessage()
                    }
                    .disabled(viewModel.isResponding)
                }
                .padding()
                
            }
            .navigationTitle(viewModel.currentSessionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSessions = true
                    } label: {
                        Label("Chats", systemImage: "sidebar.left")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Chat") {
                        viewModel.startNewChat()
                    }
                }
            }
        }
        .task {
            viewModel.configure(modelContext: modelContext)
        }
        .sheet(isPresented: $showSessions) {
            SessionsView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewContainer.container)
}

private enum PreviewContainer {
    static let container: ModelContainer = {
        let schema = Schema([
            StoredChatSession.self as any PersistentModel.Type,
            StoredChatMessage.self as any PersistentModel.Type
        ])

        return try! ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
    }()
}
