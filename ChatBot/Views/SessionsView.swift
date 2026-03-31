//
//  SessionsView.swift
//  ChatBot
//
//  Created by Codex on 31/03/26.
//

import SwiftUI

struct SessionsView: View {
    @Environment(\.dismiss) private var dismiss

    var viewModel: ChatViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.sessions, id: \.id) { session in
                    Button {
                        viewModel.selectSession(session)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(session.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if session.id == viewModel.currentSessionID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }

                            Text(session.previewText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)

                            Text(session.updatedAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: viewModel.deleteSessions)
            }
            .navigationTitle("Previous Chats")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Chat") {
                        viewModel.startNewChat()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SessionsView(viewModel: ChatViewModel())
}
