//
//  ChatbotView.swift
//  VirtualGarden
//

import SwiftUI

struct ChatbotView: View {
    @StateObject private var viewModel = ChatbotViewModel()
    @FocusState private var isInputFocused: Bool
    
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F5F0E8").ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(viewModel.messages) { msg in
                                    ChatBubbleRow(message: msg)
                                        .id(msg.id)
                                }

                                if viewModel.isTyping {
                                    HStack {
                                        TypingIndicator()
                                            .padding()
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                        Spacer()
                                    }
                                    .padding(.horizontal, isIpad ? 40 : 16)
                                    .id("TypingIndicator")
                                }
                            }
                            .padding(.vertical, 24)
                        }
                        .onChange(of: viewModel.messages) { _ in
                            withAnimation {
                                proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: viewModel.isTyping) { typing in
                            if typing {
                                withAnimation {
                                    proxy.scrollTo("TypingIndicator", anchor: .bottom)
                                }
                            }
                        }
                        .onTapGesture {
                            isInputFocused = false
                        }
                    }

                    // Input Header bounds safely locked
                    VStack(spacing: 0) {
                        Divider().background(Color.gray.opacity(0.3))
                        HStack(spacing: 12) {
                            TextField("Ask me about native plants...", text: $viewModel.currentInput, axis: .vertical)
                                .focused($isInputFocused)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .shadow(color: .black.opacity(0.05), radius: 5)
                                .lineLimit(1...5)
                            
                            Button {
                                Task {
                                    await viewModel.sendMessage()
                                }
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: isIpad ? 40 : 34))
                                    .foregroundColor(viewModel.currentInput.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.5) : Color(hex: "#4A7C59"))
                            }
                            .disabled(viewModel.currentInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isTyping)
                        }
                        .padding(.horizontal, isIpad ? 40 : 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#F5F0E8"))
                    }
                }
            }
            .navigationTitle("Plant Assistant")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ChatBubbleRow: View {
    let message: ChatMessage
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .font(.system(size: isIpad ? 18 : 16))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(Color(hex: "#4A7C59"))
                    .clipShape(ChatBubbleShape(isUser: true))
                    .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
            } else {
                Text(message.text)
                    .font(.system(size: isIpad ? 18 : 16))
                    .foregroundColor(Color(hex: "#1A2E1A"))
                    .padding(16)
                    .background(Color.white)
                    .clipShape(ChatBubbleShape(isUser: false))
                    .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
                Spacer()
            }
        }
        .padding(.horizontal, isIpad ? 40 : 16)
    }
}

struct ChatBubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [
            .topLeft,
            .topRight,
            isUser ? .bottomLeft : .bottomRight
        ], cornerRadii: CGSize(width: 18, height: 18))
        return Path(path.cgPath)
    }
}

struct TypingIndicator: View {
    @State private var bounce = [false, false, false]
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color(hex: "#4A7C59").opacity(0.6))
                    .frame(width: 8, height: 8)
                    .offset(y: bounce[i] ? -4 : 0)
            }
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                withAnimation(Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    bounce[i] = true
                }
            }
        }
    }
}
