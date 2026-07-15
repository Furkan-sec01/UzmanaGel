//
//  PreViewScreen.swift
//  UzmanaGel
//
//  Created by Abdullah B on 29.01.2026.
//

import SwiftUI

struct PreViewScreen: View {
    var body: some View {
        ZStack{
            Color("BackgroundColor2")
                .ignoresSafeArea()
            
            VStack{
                Image("Logo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 300)
                    .clipShape(Circle())
                    .shadow(radius: 100)
                    .padding(200)
                
                
                Text("from")
                    .foregroundStyle(Color("SecondaryColor"))
                    .font(
                        .system(size: 18)
                        .bold())
                
                
                Text("NDM Software")
                    .foregroundStyle(Color.yellow)
                    .font(
                        .system(size: 20)
                        .bold())
                    
            }
        }
    }
}

#Preview {
    PreViewScreen()
}
