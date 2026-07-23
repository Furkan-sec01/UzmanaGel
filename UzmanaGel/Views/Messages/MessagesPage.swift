//
//  MessagesPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//

import SwiftUI

struct MessagesPage: View {
    
    @StateObject private var vm = MessageViewModel()
    @ObservedObject private var langManager = LanguageManager.shared
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            if vm.conversations.isEmpty {
                emptyState
            } else {
                conversationScrollView
            }
        }
        .navigationTitle("Mesajlar".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.load()
        }
        .onDisappear {
            vm.stopListening()
        }
    }
    
    // MARK: - Conversation Scroll List
    private var conversationScrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Top Header Summary Bar
                headerStatusBar
                
                // Cards
                LazyVStack(spacing: 12) {
                    ForEach(vm.conversations) { conversation in
                        NavigationLink {
                            ChatDetailPage(conversation: conversation)
                        } label: {
                            conversationCard(conversation)
                        }
                        .buttonStyle(ChatRowButtonStyle())
                    }
                }
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Header Status Bar
    private var headerStatusBar: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Tüm Sohbetler".localized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            let totalUnread = vm.conversations.reduce(0) { $0 + $1.unreadCount }
            if totalUnread > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Text("\(totalUnread) \("Yeni".localized)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color.red.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.red.opacity(0.35), radius: 6, x: 0, y: 3)
            } else {
                Text("\(vm.conversations.count) \("kişi".localized)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Modern Conversation Card
    private func conversationCard(_ conversation: Conversation) -> some View {
        HStack(spacing: 14) {
            // Left: Avatar with Online Dot
            avatarView(for: conversation)
            
            // Center: Name & Last Message Preview
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(conversation.participantName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 4)
                    
                    // Formatted Timestamp
                    Text(formattedDate(conversation.lastMessageDate))
                        .font(.system(size: 12, weight: conversation.unreadCount > 0 ? .bold : .medium))
                        .foregroundColor(conversation.unreadCount > 0 ? Color("PrimaryColor") : .secondary)
                }
                
                HStack(alignment: .center) {
                    let msgText = conversation.lastMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    if msgText.isEmpty {
                        Text("Sohbeti başlatmak için dokunun...".localized)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.8))
                            .italic()
                            .lineLimit(1)
                    } else {
                        Text(msgText)
                            .font(.system(size: 14, weight: conversation.unreadCount > 0 ? .semibold : .regular))
                            .foregroundColor(conversation.unreadCount > 0 ? .primary : .secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer(minLength: 6)
                    
                    // Right: Unread Badge or Arrow
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(Color("PrimaryColor"))
                            .clipShape(Capsule())
                            .shadow(color: Color("PrimaryColor").opacity(0.35), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    conversation.unreadCount > 0
                    ? Color("PrimaryColor").opacity(0.3)
                    : Color.primary.opacity(0.06),
                    lineWidth: conversation.unreadCount > 0 ? 1.5 : 1
                )
        )
        .shadow(
            color: conversation.unreadCount > 0
            ? Color("PrimaryColor").opacity(0.08)
            : Color.black.opacity(0.05),
            radius: 10,
            x: 0,
            y: 4
        )
    }
    
    // MARK: - Avatar View & Fallback
    @ViewBuilder
    private func avatarView(for conversation: Conversation) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if let urlString = conversation.participantPhotoUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                    default:
                        fallbackAvatar(for: conversation)
                    }
                }
                .frame(width: 54, height: 54)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1.5)
                )
            } else {
                fallbackAvatar(for: conversation)
            }
            
            // Subtle Active Dot
            Circle()
                .fill(Color.green)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .stroke(Color("CardBackground"), lineWidth: 2.5)
                )
                .offset(x: 1, y: 1)
        }
    }
    
    private func fallbackAvatar(for conversation: Conversation) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color("PrimaryColor").opacity(0.18),
                        Color("PrimaryColor").opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 54, height: 54)
            .overlay(
                Group {
                    let initials = conversation.participantName
                        .split(separator: " ")
                        .prefix(2)
                        .compactMap { $0.first }
                        .map { String($0) }
                        .joined()
                        .uppercased()
                    
                    if !initials.isEmpty {
                        Text(initials)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            )
            .overlay(
                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1.5)
            )
    }
    
    // MARK: - Empty State Hero
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color("PrimaryColor").opacity(0.08))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 42))
                    .foregroundColor(Color("PrimaryColor"))
            }
            .shadow(color: Color("PrimaryColor").opacity(0.15), radius: 16, x: 0, y: 8)
            
            VStack(spacing: 8) {
                Text("Henüz Mesajınız Yok".localized)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Ustalar veya müşterilerle yaptığınız tüm yazışmalar burada güvenle saklanır.".localized)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Date Formatting Helper
    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Dün".localized
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Tactile Row Button Style
struct ChatRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        MessagesPage()
    }
}
