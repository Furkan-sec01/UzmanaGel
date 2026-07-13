//
//  FavoritesViewModel.swift
//  UzmanaGel
//
//  Created by Abdullah B on 12.02.2026.
//

import Foundation
import Combine
import FirebaseStorage

@MainActor
final class FavoritesViewModel: ObservableObject {

    @Published var services: [Service] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var imageURLs: [String: URL] = [:]

    private let favRepo = FavoritesRepository()
    private let serviceRepo = ServiceRepository()

    func load() {
        Task { await fetch() }
    }

    func removeFavorite(serviceId: String) {
        Task {
            do {
                try await favRepo.removeFavorite(serviceId: serviceId)
                await fetch()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Tek bir servis için Storage klasöründen ilk görseli çek ve cache'le
    /// Path: service_images/{serviceId}/ → klasördeki ilk dosya
    func loadImage(for serviceId: String) {
        guard !serviceId.isEmpty, imageURLs[serviceId] == nil else { return }

        let folderRef = Storage.storage().reference().child("service_images/\(serviceId)")

        folderRef.list(maxResults: 1) { [weak self] result, error in
            if let error = error {
                print("📷 [\(serviceId)] list error: \(error.localizedDescription)")
                return
            }

            guard let item = result?.items.first else {
                print("📷 [\(serviceId)] klasörde dosya yok")
                return
            }

            item.downloadURL { [weak self] url, error in
                if let error = error {
                    print("📷 [\(serviceId)] downloadURL error: \(error.localizedDescription)")
                    return
                }
                guard let url = url else { return }
                DispatchQueue.main.async {
                    self?.imageURLs[serviceId] = url
                }
            }
        }
    }

    private func fetch() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let ids = try await favRepo.fetchFavoriteServiceIds()
            services = try await serviceRepo.fetchServicesByServiceIds(ids)
            for service in services {
                loadImage(for: service.serviceId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() { errorMessage = nil }
}
