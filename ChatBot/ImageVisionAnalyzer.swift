//
//  ImageVisionAnalyzer.swift
//  ChatBot
//
//  Created by Codex on 01/04/26.
//

import Foundation
import ImageIO
import UIKit
import Vision

struct ImageVisionAnalysis {
    let recognizedText: String
    let labels: [String]

    var summary: String {
        var sections: [String] = []

        if !recognizedText.isEmpty {
            sections.append("Recognized text:\n\(recognizedText)")
        }

        if !labels.isEmpty {
            sections.append("Detected subjects: \(labels.joined(separator: ", "))")
        }

        if sections.isEmpty {
            return "No clear text or sucobjects were detected in the image."
        }

        return sections.joined(separator: "\n\n")
    }

    var statusLine: String {
        if !recognizedText.isEmpty && !labels.isEmpty {
            return "Image ready: found text and visual subjects."
        }

        if !recognizedText.isEmpty {
            return "Image ready: found readable text."
        }

        if !labels.isEmpty {
            return "Image ready: found visual subjects."
        }

        return "Image ready: limited detail detected."
    }
}

struct ImageVisionAnalyzer {
    enum AnalysisError: LocalizedError {
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "The selected file is not a valid image."
            }
        }
    }

    func analyze(_ image: UIImage) async throws -> ImageVisionAnalysis {
        guard let cgImage = normalizedCGImage(from: image) else {
            throw AnalysisError.invalidImage
        }

        async let recognizedText = recognizeText(in: cgImage, orientation: image.cgImageOrientation)
        async let labels = safeClassifyImage(in: cgImage, orientation: image.cgImageOrientation)

        let text = (try? await recognizedText) ?? ""
        let imageLabels = await labels

        let analysis = ImageVisionAnalysis(
            recognizedText: text,
            labels: imageLabels
        )

        return analysis
    }

    private func recognizeText(
        in cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> String {
        try await runVisionWork {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.02

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: orientation,
                options: [:]
            )
            try handler.perform([request])

            let observations = (request.results) ?? []
            return observations
                .compactMap { $0.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
        }
    }

    private func safeClassifyImage(
        in cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) async -> [String] {
        do {
            return try await classifyImage(in: cgImage, orientation: orientation)
        } catch {
            return []
        }
    }

    private func classifyImage(
        in cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> [String] {
        try await runVisionWork {
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: orientation,
                options: [:]
            )
            try handler.perform([request])

            let results = (request.results) ?? []
            return results
                .filter { $0.confidence >= 0.2 }
                .prefix(4)
                .map(\.identifier)
        }
    }

    private func runVisionWork<T: Sendable>(
        _ work: @escaping @Sendable () throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try work())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func normalizedCGImage(from image: UIImage) -> CGImage? {
        if let cgImage = image.cgImage {
            return cgImage
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        let renderedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        return renderedImage.cgImage
    }
}

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        case .upMirrored:
            return .upMirrored
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .up
        }
    }
}
