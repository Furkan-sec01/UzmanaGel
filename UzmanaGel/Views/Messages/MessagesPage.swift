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
        Group{
            if vm.conversations.isEmpty{
                emptyState
            }else{
                conversationList
            }
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Mesajlar".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(){
            vm.load()
        }
        .onDisappear {
            vm.stopListening()
        }
    }
    
    private var conversationList: some View{
        List(vm.conversations){ conversation in
            NavigationLink {
                   ChatDetailPage(conversation: conversation)
               } label: {
                   conversationRow(conversation)
               }
           }
        .listStyle(.plain)
    }
    
    private func conversationRow(
        _ conversation: Conversation
    ) -> some View {

        HStack(spacing: 12) {

            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(Color("PrimaryColor"))

            VStack(alignment: .leading, spacing: 5) {
                Text(conversation.participantName)
                    .font(.system(size: 16, weight: .semibold))

                Text(conversation.lastMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 24, minHeight: 24)
                    .background(Color("PrimaryColor"))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 6)
    }
    private var emptyState: some View {
            VStack(spacing: 16) {
                Image(systemName: "message")
                    .font(.system(size: 48))
                    .foregroundColor(Color("PrimaryColor"))

                Text("Henüz mesaj bulunmuyor.".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

#Preview {
    NavigationStack{
        MessagesPage()
    }
}
