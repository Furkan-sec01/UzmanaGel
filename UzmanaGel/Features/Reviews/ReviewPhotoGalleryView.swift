//
//  ReviewPhotoGalleryView.swift
//  UzmanaGel
//
//  Created by Antigravity on 22.07.2026.
//

import SwiftUI

struct ReviewPhotoGalleryView: View {
    let photos: [String]
    @State var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { idx, urlStr in
                    VStack {
                        Spacer()
                        
                        AsyncImage(url: URL(string: urlStr)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            case .failure:
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("Fotoğraf yüklenemedi".localized)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            default:
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        
                        Spacer()
                        
                        // Caption / Sayfa indikatörü
                        Text(String(format: "%d / %d".localized, idx + 1, photos.count))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(.bottom, 30)
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Üst Kapatma ve Paylaş Butonları
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    if photos.indices.contains(selectedIndex), let url = URL(string: photos[selectedIndex]) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
            }
        }
    }
}
