# ChatBot

`ChatBot` is a SwiftUI iOS app that uses Apple's Foundation Models for on-device conversations and SwiftData for local chat history.

## Project Demo

[Watch the project demo video](docs/demo/chatbot-demo.mov)

This demo shows how the app works, including chatting, browsing previous sessions, and using image-based context in conversations.

## Features

- Text-based AI chat using `FoundationModels`
- Persistent chat sessions with `SwiftData`
- Previous chat list with session switching
- Image upload from the photo library
- Vision-powered image understanding before sending image context to the language model
- User-facing chat bubbles that show only the uploaded image and the user's typed message

## How Image Support Works

The app does not send raw images directly into the language model response pipeline. Instead:

1. The user selects an image from the photo library.
2. Vision analyzes the image.
3. OCR is extracted with `VNRecognizeTextRequest`.
4. Visual labels are extracted with `VNClassifyImageRequest`.
5. The extracted image context is kept hidden from the user-facing chat bubble.
6. That hidden context is appended to the model prompt so the assistant can answer questions about the image.

This keeps the UI clean while still allowing the assistant to respond intelligently to uploaded images.

## Tech Stack

- SwiftUI
- Foundation Models
- Vision
- PhotosUI
- SwiftData

## How It Works

1. The user starts a new chat or opens an existing conversation.
2. Messages are processed with Apple's on-device foundation model support.
3. Every conversation is saved locally with `SwiftData`.
4. If the user attaches an image, Vision extracts useful context before the prompt is sent.
5. The assistant replies using the typed message plus any hidden image context.

## Project Structure

- `ChatBot/Views`: UI screens and chat rendering
- `ChatBot/View Model`: chat state and prompt orchestration
- `ChatBot/Model`: app-facing message and session models plus schema helpers
- `ChatBot/Model/Schema`: SwiftData migration plan and current schema aliases
- `ChatBot/Model/Schema/Versions`: versioned SwiftData schemas used for migration safety
- `ChatBot/ImageVisionAnalyzer.swift`: OCR and image classification helper

## Requirements

- Xcode with support for `FoundationModels`
- Minimum supported device for full Apple Intelligence functionality: `iPhone 15 Pro`
- iOS device or simulator compatible with the app target
- Apple Intelligence / system model availability for chat responses

## Notes

- Chat sessions are stored locally.
- Uploaded images are stored with chat messages so they can be shown again in chat history.
- Vision extraction is hidden from the user interface and only used internally for better responses.
- SwiftData uses a versioned migration structure so future updates are safer for existing users.
