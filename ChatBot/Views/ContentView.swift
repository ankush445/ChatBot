//
//  ChatBotApp.swift
//  ChatBot
//
//  Created by ios-22 on 30/03/26.
//


import SwiftUI
import SwiftData
import PhotosUI

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ChatViewModel()
    @State private var showSessions = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
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
                VStack(spacing: 12) {
                    if let selectedImage = viewModel.selectedImage {
                        HStack(alignment: .top, spacing: 12) {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 14))

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Attached image")
                                    .font(.headline)

                                Text(viewModel.imageAnalysisStatus ?? "Image selected")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Button {
                                selectedPhotoItem = nil
                                viewModel.removeSelectedImage()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else if let imageStatus = viewModel.imageAnalysisStatus {
                        Text(imageStatus)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Image(systemName: "photo")
                                .font(.title3)
                                .frame(width: 36, height: 36)
                        }
                        .disabled(viewModel.isResponding)

                        TextField("Write a question here...", text: $viewModel.userInput)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                viewModel.sendMessage()
                            }

                        Button("Send") {
                            viewModel.sendMessage()
                        }
                        .disabled(viewModel.isResponding || viewModel.isAnalyzingImage)
                    }
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
        .task(id: selectedPhotoItem) {
            await viewModel.loadSelectedImage(from: selectedPhotoItem)
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
            StoredChatSession.self,
            StoredChatMessage.self
        ])

        return try! ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
    }()
}
