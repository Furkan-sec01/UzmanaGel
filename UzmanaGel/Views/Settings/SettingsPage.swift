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
    
    @AppStorage("selectedAppearance")
    private var selectedAppearance = "system"
    
    @State private var hasReadKVKK = false///new
    
    var body: some View {
        List{
            Section("Uygulama"){
                Toggle(isOn:$notificationEnabled){
                    Label("Bildirimler", systemImage: "bell")
                }
                
                Picker(selection: $selectedAppearance){
                    Text("Sistem").tag("system")
                    Text("Açık").tag("light")
                    Text("Koyu").tag( "dark")
                } label:{
                    Label("Görünüm",systemImage: "paintbrush")
                }

            }
            Section("Gizlilik"){
                NavigationLink{
                    Kvkk(hasRead: $hasReadKVKK,showsAcceptance: false)
                } label:{
                    Label(
                        "KVKK ve Gizlilik",
                        systemImage: "hand.raised"
                        )
                }
            }
            Section("Destek"){
                NavigationLink{
                    HelpPage()
                } label:{
                    Label("Yardım", systemImage: "questionmark.circle")
                }
                NavigationLink{
                    AboutPage()
                } label:{
                    Label("Hakkında",systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack{
        SettingsPage()
    }
}
