//
//  ChatBotApp.swift
//  ChatBot
//
//  Created by ios-22 on 30/03/26.
//


import SwiftUI

struct SuggestionsView: View {
    
    var viewModel: ChatViewModel
    
    let suggestions = [
        // 💬 General Questions
        "Tell me something interesting.",
        "Explain a complex topic in simple words.",
        "What are some productive daily habits?",
        
        // 💼 Business & Work
        "Give me a business idea for a small startup.",
        "How can I grow my local business?",
        "Suggest marketing strategies for a new product.",
        "How do I improve customer engagement?",
        
        // 📈 Career & Growth
        "How can I improve my communication skills?",
        "Tips to crack an interview.",
        "How to become more confident?",
        
        // 💰 Finance
        "How can I start saving money effectively?",
        "Basic investment tips for beginners.",
        
        // 🧠 Productivity
        "How to stay focused while working?",
        "Best ways to manage time efficiently.",
        
        // ❤️ Lifestyle
        "How to maintain a healthy lifestyle?",
        "Ways to reduce stress and anxiety.",
        
        // 🌍 Tech & Learning
        "Explain AI in simple terms.",
        "What are the latest tech trends?",
        
        // ✍️ Content & Writing
        "Write a professional email.",
        "Help me create a social media post.",
        
        // 🎯 Fun / Casual
        "Suggest some weekend activities.",
        "Tell me a fun fact."
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                
                // 🧠 Title / Emoji
                Text("💡 Suggestions")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 10)
                
                // 🔁 Suggestions List
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        viewModel.userInput = suggestion
                        viewModel.sendMessage()
                    } label: {
                        Text(suggestion)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    SuggestionsView(viewModel: ChatViewModel())
}
