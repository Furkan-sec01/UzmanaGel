//
//  Conversation.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//

///Bu model tek bir konuşma satırını temsil eder

import Foundation

struct Conversation: Identifiable, Hashable{
    
    let id: String
    let participantId: String
    let participantName: String
    let participantPhotoUrl: String?
    let lastMessage: String
    let lastMessageDate: Date
    let unreadCount: Int
}
