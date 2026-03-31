//
//  ChatBotApp.swift
//  ChatBot
//
//  Created by ios-22 on 30/03/26.
//


/*
 Simple markdown renderer
 only use for small texts during streaming
 otherwise performance limitations show
 
 or use
 Text(LocalizedStringKey(markdown))
 */

import SwiftUI

struct MarkdownText: View {
    let markdown: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(parseLines(from: markdown), id: \.self) { line in
                render(line: line)
            }
        }
    }

    @ViewBuilder
    func render(line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasPrefix("- ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                Text(attributedMarkdown(from: String(trimmed.dropFirst(2))))
            }
        } else {
            Text(attributedMarkdown(from: trimmed))
        }
    }

    func parseLines(from markdown: String) -> [String] {
        markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }

    func attributedMarkdown(from text: String) -> AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
}

#Preview {
    MarkdownText(markdown: """
        Hello world
        *this is* bold and **italic**
        text
        
        **Description**: Poodles are highly intelligent.
        - **Grooming**: Needs brushing
        - **Exercise**: Daily
        """)
}
