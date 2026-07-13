//
//  MessageRepository.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//

import Foundation
import FirebaseFirestore

final class MessageRepository {

    private let db = Firestore.firestore()

    // MARK: - Conversation ID

    func makeConversationId(
        currentUserId: String,
        participantId: String
    ) -> String {
        [currentUserId, participantId]
            .sorted()
            .joined(separator: "__")
    }

    // MARK: - Create Conversation

    func getOrCreateConversation(
        currentUserId: String,
        currentUserName: String,
        participantId: String,
        participantName: String,
        currentUserPhotoURL: String? = nil,
        participantPhotoURL: String? = nil
    ) async throws -> Conversation {

        let conversationId = makeConversationId(
            currentUserId: currentUserId,
            participantId: participantId
        )

        let ref = db
            .collection("conversations")
            .document(conversationId)

        let snapshot = try await ref.getDocument()

        if !snapshot.exists {
            var photoURLs: [String: String] = [:]

            if let currentUserPhotoURL,
               !currentUserPhotoURL.isEmpty {
                photoURLs[currentUserId] = currentUserPhotoURL
            }

            if let participantPhotoURL,
               !participantPhotoURL.isEmpty {
                photoURLs[participantId] = participantPhotoURL
            }
             
            ///Conersation Firebase Data
            let data: [String: Any] = [
                "participantIds": [
                    currentUserId,
                    participantId
                ],
                "participantNames": [
                    currentUserId: currentUserName,
                    participantId: participantName
                ],
                "participantPhotoURLs": photoURLs,
                "lastMessage": "",
                "lastMessageAt": FieldValue.serverTimestamp(),
                "unreadCounts": [
                    currentUserId: 0,
                    participantId: 0
                ],
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            try await ref.setData(data)
        }

        return Conversation(
            id: conversationId,
            participantId: participantId,
            participantName: participantName,
            participantPhotoUrl: participantPhotoURL,
            lastMessage: "",
            lastMessageDate: Date(),
            unreadCount: 0
        )
    }

    // MARK: - Listen Conversations

    func listenToConversations(
        currentUserId: String,
        onChange: @escaping ([Conversation]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {

        db.collection("conversations")
            .whereField(
                "participantIds",
                arrayContains: currentUserId
            )
            .addSnapshotListener { snapshot, error in

                if let error {
                    onError(error)
                    return
                }

                guard let documents = snapshot?.documents else {
                    onChange([])
                    return
                }

                let conversations = documents.compactMap { doc in
                    self.mapConversation(
                        document: doc,
                        currentUserId: currentUserId
                    )
                }
                .sorted {
                    $0.lastMessageDate > $1.lastMessageDate
                }

                onChange(conversations)
            }
    }

    // MARK: - Listen Messages

    func listenToMessages(
        conversationId: String,
        onChange: @escaping ([ChatMessage]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {

        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "sentAt")
            .addSnapshotListener { snapshot, error in

                if let error {
                    onError(error)
                    return
                }

                guard let documents = snapshot?.documents else {
                    onChange([])
                    return
                }

                let messages = documents.compactMap { doc in
                    self.mapMessage(document: doc)
                }

                onChange(messages)
            }
    }

    // MARK: - Send Message

    func sendMessage(
        conversation: Conversation,
        senderId: String,
        text: String
    ) async throws {

        let trimmedText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            return
        }

        let conversationRef = db
            .collection("conversations")
            .document(conversation.id)

        let messageRef = conversationRef
            .collection("messages")
            .document()

        let messageData: [String: Any] = [
            "conversationId": conversation.id,
            "senderId": senderId,
            "receiverId": conversation.participantId,
            "text": trimmedText,
            "sentAt": FieldValue.serverTimestamp(),
            "isRead": false
        ]

        let batch = db.batch()

        /// Add the new message
        batch.setData(
            messageData,
            forDocument: messageRef
        )

        /// Update conversation summary
        batch.updateData(
            [
                "lastMessage": trimmedText,
                "lastMessageAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
                "unreadCounts.\(conversation.participantId)":
                    FieldValue.increment(Int64(1))
            ],
            forDocument: conversationRef
        )

        try await batch.commit()
    }

    // MARK: - Mark Conversation As Read

    func markConversationAsRead(
        conversationId: String,
        currentUserId: String,
        messageIds: [String]
    ) async throws {

        guard !messageIds.isEmpty else { return }

        let conversationRef = db
            .collection("conversations")
            .document(conversationId)

        let batch = db.batch()

        // Reset unread count for current user
        let conversationUpdates: [AnyHashable: Any] = [
            FieldPath([
                "unreadCounts",
                currentUserId
            ]): 0
        ]

        batch.updateData(
            conversationUpdates,
            forDocument: conversationRef
        )

        // Mark received messages as read
        for messageId in messageIds {

            let messageRef = conversationRef
                .collection("messages")
                .document(messageId)

            batch.updateData(
                [
                    "isRead": true
                ],
                forDocument: messageRef
            )
        }

        try await batch.commit()
    }
    
    // MARK: - Map Conversation

    /// Convert FireStore Data to Swift Model
    private func mapConversation(
        document: QueryDocumentSnapshot,
        currentUserId: String
    ) -> Conversation? {

        let data = document.data()

        guard
            let participantIds = data["participantIds"] as? [String],
            let participantId = participantIds.first(
                where: { $0 != currentUserId }
            )
        else {
            return nil
        }

        let names =
            data["participantNames"] as? [String: String] ?? [:]

        let photos =
            data["participantPhotoURLs"] as? [String: String] ?? [:]

        let lastMessage =
            data["lastMessage"] as? String ?? ""

        let lastMessageDate =
            (data["lastMessageAt"] as? Timestamp)?.dateValue()
            ?? Date.distantPast

        let unreadCounts =
            data["unreadCounts"] as? [String: Any] ?? [:]

        let unreadCount =
            (unreadCounts[currentUserId] as? NSNumber)?.intValue ?? 0

        return Conversation(
            id: document.documentID,
            participantId: participantId,
            participantName: names[participantId] ?? "Kullanıcı",
            participantPhotoUrl: photos[participantId],
            lastMessage: lastMessage,
            lastMessageDate: lastMessageDate,
            unreadCount: unreadCount
        )
    }

    // MARK: - Map Message

    private func mapMessage(
        document: QueryDocumentSnapshot
    ) -> ChatMessage? {

        let data = document.data()

        guard
            let conversationId =
                data["conversationId"] as? String,
            let senderId =
                data["senderId"] as? String,
            let receiverId =
                data["receiverId"] as? String,
            let text =
                data["text"] as? String
        else {
            return nil
        }

        let sentAt =
            (data["sentAt"] as? Timestamp)?.dateValue()
            ?? Date()

        let isRead =
            data["isRead"] as? Bool ?? false

        return ChatMessage(
            id: document.documentID,
            conversationId: conversationId,
            senderId: senderId,
            receiverId: receiverId,
            text: text,
            sentAt: sentAt,
            isRead: isRead
        )
    }
}
