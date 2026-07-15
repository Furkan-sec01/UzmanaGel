//
//  SettingsPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//

import SwiftUI

struct SettingsPage: View {
        
    @AppStorage("notificationEnabled") /// kucuk kullanıcı tercihlerini cihazda saklar
    private var notificationEnabled = true
    @ObservedObject private var langManager = LanguageManager.shared
    
    @AppStorage("selectedAppearance")
    private var selectedAppearance = "system"
    
    @State private var hasReadKVKK = false///new
    
    var body: some View {
        List{
            Section("Uygulama".localized){
                Toggle(isOn:$notificationEnabled){
                    Label("Bildirimler".localized, systemImage: "bell")
                }
                
                Picker(selection: $selectedAppearance){
                    Text("Sistem".localized).tag("system")
                    Text("Açık".localized).tag("light")
                    Text("Koyu".localized).tag( "dark")
                } label:{
                    Label("Görünüm".localized,systemImage: "paintbrush")
                }

            }
            Section("Gizlilik".localized){
                NavigationLink{
                    Kvkk(hasRead: $hasReadKVKK,showsAcceptance: false)
                } label:{
                    Label(
                        "KVKK ve Gizlilik".localized,
                        systemImage: "hand.raised"
                        )
                }
            }
            Section("Destek".localized){
                NavigationLink{
                    HelpPage()
                } label:{
                    Label("Yardım".localized, systemImage: "questionmark.circle")
                }
                NavigationLink{
                    AboutPage()
                } label:{
                    Label("Hakkında".localized,systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Ayarlar".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack{
        SettingsPage()
    }
}
