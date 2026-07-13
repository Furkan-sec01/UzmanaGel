//
//  SideMenuViewModel.swift
//  UzmanaGel
//
//  Created by Abdullah B on 5.02.2026.
//

import Foundation
import Combine

@MainActor
final class SideMenuViewModel: ObservableObject {

    @Published var user: AppUser?
    @Published var isLoading = false

    private let repo = UserRepository()

    func load(uid: String?) {
        guard let uid else { return }

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                user = try await repo.fetchUser(uid: uid)
            } catch {
                // istersen debug
                print("SideMenu load user error:", error.localizedDescription)
            }
        }
    }
}
