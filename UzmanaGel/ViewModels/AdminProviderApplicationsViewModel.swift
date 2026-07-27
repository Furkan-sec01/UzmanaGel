import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class AdminProviderApplicationsViewModel: ObservableObject {

    @Published private(set) var applications: [ExpertProfile] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadApplications() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let snapshot = try await db
                .collection("service_providers")
                .whereField(
                    "status",
                    in: ["Pending", "pending"]
                )
                .getDocuments()

            applications = snapshot.documents
                .compactMap { document -> ExpertProfile? in
                    guard var application = try? document.data(
                        as: ExpertProfile.self
                    ) else {
                        return nil
                    }

                    // Set Firestore document ID explicitly.
                    application.id = document.documentID

                    return application
                }
                .sorted {
                    ($0.createdAt?.dateValue() ?? .distantPast)
                        > ($1.createdAt?.dateValue() ?? .distantPast)
                }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class AdminProviderApplicationDetailViewModel:
    ObservableObject {

    @Published private(set) var isProcessing = false
    @Published var errorMessage: String?

    private let service = AdminProviderApplicationService()

    func submitDecision(
        application: ExpertProfile,
        action: AdminProviderApplicationAction,
        adminNote: String
    ) async -> Bool {
        guard !isProcessing else {
            return false
        }

        guard let providerId = application.id,
              !providerId.isEmpty else {
            errorMessage = "Uzman kimliği bulunamadı."
            return false
        }

        isProcessing = true
        errorMessage = nil

        defer {
            isProcessing = false
        }

        do {
            try await service.moderateApplication(
                providerId: providerId,
                action: action,
                adminNote: adminNote
            )

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func showError(_ message: String) {
        errorMessage = message
    }

    func clearError() {
        errorMessage = nil
    }
}
