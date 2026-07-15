//
//  ChatDetailPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//

import SwiftUI

struct ChatDetailPage: View {

    @StateObject private var vm: ChatDetailViewModel

    init(conversation: Conversation) {
        _vm = StateObject(
            wrappedValue: ChatDetailViewModel(
                conversation: conversation
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(vm.messages) { message in
                        messageBubble(message)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            Divider()

            messageInput
        }
        .background(Color("BackgroundColor"))
        .navigationTitle(vm.conversation.participantName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.load()
        }
        .onDisappear{
            vm.stopListening()
        }
    }

    private func messageBubble(
        _ message: ChatMessage
    ) -> some View {

        HStack {
            if vm.isCurrentUser(message) {
                Spacer()
            }

            Text(message.text)
                .font(.system(size: 15))
                .foregroundColor(
                    vm.isCurrentUser(message)
                    ? .white
                    : .primary
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    vm.isCurrentUser(message)
                    ? Color("PrimaryColor")
                    : Color(.secondarySystemBackground)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
                .frame(
                    maxWidth: 280,
                    alignment: vm.isCurrentUser(message)
                    ? .trailing
                    : .leading
                )

            if !vm.isCurrentUser(message) {
                Spacer()
            }
        }
    }

    private var messageInput: some View {
        HStack(spacing: 10) {

            TextField(
                "Mesaj yaz...",
                text: $vm.messageText,
                axis: .vertical
            )
            .lineLimit(1...4)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )

            Button {
                vm.sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Color("PrimaryColor"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(
                vm.isSending ||
                vm.messageText
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color("BackgroundColor"))
    }
}

#Preview {
    NavigationStack {
        ChatDetailPage(
            conversation: Conversation(
                id: "conversation-1",
                participantId: "expert-1",
                participantName: "Ahmet Usta",
                participantPhotoUrl: nil,
                lastMessage: "Yarın saat 14:00 uygundur.",
                lastMessageDate: Date(),
                unreadCount: 2
            )
        )
    }
}
