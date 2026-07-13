//
//  ChatMessage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//
///Bu model tek bir mesajı temsil eder.

import Foundation

struct ChatMessage: Identifiable, Hashable {

    let id: String
    let conversationId: String
    let senderId: String
    let receiverId: String
    let text: String
    let sentAt: Date
    let isRead: Bool
}
