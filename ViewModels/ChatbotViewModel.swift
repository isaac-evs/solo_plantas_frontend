//
//  ChatbotViewModel.swift
//  VirtualGarden
//

import SwiftUI
import Combine

struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date

    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// Minimal backend payload expectation mapping
struct ChatRequest: Codable {
    let message: String
}

struct ChatResponse: Codable {
    let reply: String
}

@MainActor
class ChatbotViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isTyping: Bool = false
    @Published var errorMessage: String? = nil

    init() {
        // Initial greeting
        messages.append(ChatMessage(text: "Hello! I am your AI botanical assistant. I have deep knowledge of the Solo Plantas catalog and general gardening. How can I help your garden thrive today?", isUser: false))
    }

    func sendMessage() async {
        let text = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Append user boundary exactly
        let userMsg = ChatMessage(text: text, isUser: true)
        messages.append(userMsg)
        currentInput = ""
        isTyping = true
        errorMessage = nil

        do {
            let body = try JSONSerialization.data(withJSONObject: ["message": text])
            
            // Expected to hit an endpoint that the backend team configures dynamically
            let response: ChatResponse = try await NetworkManager.shared.request(
                endpoint: "/chat",
                method: "POST",
                requiresAuth: true,
                body: body
            )

            // Inject the new agent message visually
            messages.append(ChatMessage(text: response.reply, isUser: false))
        } catch {
            print("Chatbot Error: \(error)")
            // Inform user visually if the backend isn't ready
            messages.append(ChatMessage(text: "I couldn't reach the server right now", isUser: false))
            errorMessage = error.localizedDescription
        }

        isTyping = false
    }
}
