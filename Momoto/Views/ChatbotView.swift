//
//  ChatbotView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI

struct ChatbotView: View {
    let context: ModelContext

    @StateObject private var viewModel = ChatbotViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            messageList
            Divider()
            inputBar
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Ask about the Mindmap")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.messages) { message in
                            bubble(for: message)
                                .id(message.id)
                        }
                    }
                    if viewModel.isThinking {
                        thinkingBubble
                            .id("thinking")
                    }
                }
                .padding(16)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(using: proxy)
            }
            .onChange(of: viewModel.isThinking) { _, _ in
                scrollToBottom(using: proxy)
            }
        }
    } //proxy to scroll automaticly

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 36))
                .foregroundStyle(Theme.purple.opacity(0.7))
        }
        .padding(.top, 60)
        .padding(.horizontal, 24)
    }

    private func bubble(for message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .font(.system(.body, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.role == .user
                    ? Color.purple
                    : Color(uiColor: UIColor.secondarySystemGroupedBackground)
                )
                .foregroundStyle(message.role == .user ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var thinkingBubble: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Thinking…")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask anything…", text: $viewModel.draft, axis: .vertical)
                .font(.system(.body, design: .rounded))
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(uiColor: UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button {
                inputFocused = false
                Task { await viewModel.send(context: context) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? Color.purple : Color.gray.opacity(0.4))
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        !viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !viewModel.isThinking
    }

    private func scrollToBottom(using proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if viewModel.isThinking {
                proxy.scrollTo("thinking", anchor: .bottom)
            } else if let last = viewModel.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatbotView(
            context: ModelContext(
                rawText: "Photosynthesis is how plants turn sunlight into food.",
                hierarchyOutline: "Photosynthesis\n- Inputs\n- Outputs",
                selectedNodeTitle: nil
            )
        )
    }
}
