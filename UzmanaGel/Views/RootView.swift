//
//  RootView.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import SwiftUI
import Combine


@MainActor
final class NotificationRouter: ObservableObject {

    static let shared = NotificationRouter()

    @Published private(set) var pendingReservationId: String?

    private init() {}

    func openReservation(id: String) {
        pendingReservationId = id
    }

    func clearReservation() {
        pendingReservationId = nil
    }
}

struct RootView: View {

    @EnvironmentObject var session: SessionViewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @ObservedObject private var notificationRouter = NotificationRouter.shared

    @State private var notificationReservation: Reservation?
    @State private var notificationErrorMessage = ""
    @State private var showNotificationError = false

    private let reservationRepository = ReservationRepository()

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if session.isAuthenticated && session.isCheckingProfile {
                ProgressView("Profil kontrol ediliyor...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("BackgroundColor").ignoresSafeArea())
            } else if session.isAuthenticated && session.isInExpertSignupFlow,
                      let vm = session.expertSignUpViewModel {// optional binding
                ExpertSignUpView(vm: vm)
                    .environmentObject(session)
            } else if session.isAuthenticated && session.isExpert {
                ExpertHomepage()
                    .environmentObject(session)
            } else if session.isAuthenticated && session.needsProfileSetup {
                CompleteProfileView()
                    .environmentObject(session)
            } else if session.isAuthenticated {
                Homepage()
            } else {
                LoginPage()
            }
        }
        .task(id: notificationRouter.pendingReservationId) {
            await openPendingReservationIfPossible()
        }
        .onChange(of: session.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated else { return }

            Task {
                await openPendingReservationIfPossible()
            }
        }
        .onChange(of: session.isCheckingProfile) { _, isCheckingProfile in
            guard !isCheckingProfile else { return }

            Task {
                await openPendingReservationIfPossible()
            }
        }
        .sheet(item: $notificationReservation) { reservation in
            ReservationDetailPage(reservation: reservation)
        }
        .alert("Bildirim Açılamadı".localized, isPresented: $showNotificationError) {
            Button("Tamam".localized, role: .cancel) {}
        } message: {
            Text(notificationErrorMessage)
        }
    }

    @MainActor
    private func openPendingReservationIfPossible() async {
        guard session.isAuthenticated,
              !session.isCheckingProfile,
              let reservationId = notificationRouter.pendingReservationId else {
            return
        }

        do {
            let reservation = try await reservationRepository.fetchReservation(
                byId: reservationId
            )

            notificationRouter.clearReservation()
            notificationReservation = reservation
        } catch {
            notificationRouter.clearReservation()
            notificationErrorMessage = error.localizedDescription
            showNotificationError = true
        }
    }
}
