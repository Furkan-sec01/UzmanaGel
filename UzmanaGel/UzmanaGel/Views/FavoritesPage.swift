//
//  FavoritesPage.swift
//  UzmanaGel
//
//  Created by Abdullah B on 12.02.2026.
//

import SwiftUI

struct FavoritesPage: View {

    @StateObject private var vm = FavoritesViewModel()
    @State private var showError = false

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()
            content
        }
        .navigationTitle("Favorilerim")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.load()
        }
        .onChange(of: vm.errorMessage) { _, msg in
            showError = (msg != nil)
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) { vm.clearError() }
        } message: {
            Text(vm.errorMessage ?? "Bilinmeyen hata")
        }
    }
}

private extension FavoritesPage {

    @ViewBuilder
    var content: some View {
        if vm.isLoading {
            loadingView
        } else if vm.services.isEmpty {
            emptyView
        } else {
            listView
        }
    }

    var loadingView: some View {
        ProgressView()
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
    }

    var emptyView: some View {
        VStack(spacing: 10) {
            Text("Favorin yok")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("Text"))

            Text("Ana sayfadan kalp ikonuna basarak favori ekleyebilirsin.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 24)
    }

    var listView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(vm.services) { item in
                    NavigationLink {
                        ServiceDetailPage(
                            service: item,
                            imageURL: vm.imageURLs[item.serviceId],
                            isFavorite: true
                        )
                    } label: {
                        ServiceCard(
                            service: item,
                            imageURL: vm.imageURLs[item.serviceId],
                            isFavorite: true,
                            onToggleFavorite: {
                                vm.removeFavorite(serviceId: item.serviceId)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
}
