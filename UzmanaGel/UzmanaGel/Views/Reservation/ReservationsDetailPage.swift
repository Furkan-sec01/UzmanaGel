//
//  ReservationsDetailPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 14.07.2026.
//

import SwiftUI
import FirebaseAuth

struct ReservationDetailPage: View {

    @State private var reservation: Reservation

    var onStatusChanged: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var chatConversation: Conversation?
    @State private var showChat = false
    @State private var isOpeningChat = false

    @State private var isUpdatingStatus = false
    @State private var showCancelConfirmation = false
    @State private var showRejectConfirmation = false

    @State private var errorMessage = ""
    @State private var showError = false

    private let messageRepository = MessageRepository()
    private let reservationRepository = ReservationRepository()

    init(
        reservation: Reservation,
        onStatusChanged: (() -> Void)? = nil
    ) {
        _reservation = State(initialValue: reservation)
        self.onStatusChanged = onStatusChanged
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    detailSection

            addressSection
                    noteSection
                    actionSection
                }
                .padding(20)
            }
            .background(Color("BackgroundColor"))
            .navigationTitle("Rezervasyon Detayı".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat".localized) {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showChat) {
                if let chatConversation {
                    ChatDetailPage(conversation: chatConversation)
                }
            }
            .alert("Hata".localized, isPresented: $showError) {
                Button("Tamam".localized, role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog(
                "Rezervasyonu iptal et".localized,
                isPresented: $showCancelConfirmation,
                titleVisibility: .visible
            ) {
                Button("İptal Et".localized, role: .destructive) {
                    Task {
                        await cancelReservationFromDetail()
                    }
                }

                Button("Vazgeç".localized, role: .cancel) { }
            } message: {
                Text("Bu rezervasyonu iptal etmek istediğinizden emin misiniz?".localized)
            }
            .confirmationDialog(
                "Rezervasyonu reddet".localized,
                isPresented: $showRejectConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reddet".localized, role: .destructive) {
                    Task {
                        await updateReservationStatusFromDetail(.rejected)
                    }
                }

                Button("Vazgeç".localized, role: .cancel) { }
            } message: {
                Text(String(format: "%@ adlı müşterinin rezervasyon talebini reddetmek istediğinizden emin misiniz?".localized, reservation.customerName))
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(reservation.serviceTitle)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(reservation.providerName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                statusBadge(reservation.status)
            }

            Divider()

            infoRow(
                icon: "calendar",
                title: "Randevu Tarihi".localized,
                value: formatDate(reservation.reservationDate)
            )
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bilgiler".localized)
                .font(.headline)

            VStack(spacing: 12) {
                infoRow(
                    icon: "person",
                    title: "Müşteri".localized,
                    value: reservation.customerName
                )

                infoRow(
                    icon: "briefcase",
                    title: "Hizmet".localized,
                    value: reservation.serviceTitle
                )

                if !reservation.serviceDuration.isEmpty {
                    infoRow(
                        icon: "timer",
                        title: "Süre".localized,
                        value: reservation.serviceDuration
                    )
                }

                infoRow(
                    icon: "turkishlirasign.circle",
                    title: "Tahmini Ücret".localized,
                    value: "\(reservation.servicePrice) ₺"
                )

                infoRow(
                    icon: "clock",
                    title: "Oluşturulma Tarihi".localized,
                    value: formatDate(reservation.createdAt)
                )
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Adres".localized)
                .font(.headline)

            Text(reservation.addressText.isEmpty ? "Adres eklenmemiş.".localized : reservation.addressText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Not".localized)
                .font(.headline)

            Text(reservation.note.isEmpty ? "Not eklenmemiş.".localized : reservation.note)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("İşlemler".localized)
                .font(.headline)

            messageButton

            if canProviderDecide {
                providerDecisionButtons
            }

            if canCustomerCancel {
                cancelButton
            }
        }
    }

    private var messageButton: some View {
        Button {
            Task {
                await openChat()
            }
        } label: {
            HStack(spacing: 10) {
                if isOpeningChat {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "message.fill")
                }

                Text("Mesaj Gönder".localized)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color("PrimaryColor"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isOpeningChat || isUpdatingStatus)
    }

    private var providerDecisionButtons: some View {
        HStack(spacing: 10) {
            Button {
                showRejectConfirmation = true
            } label: {
                Text("Reddet".localized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isUpdatingStatus)

            Button {
                Task {
                    await updateReservationStatusFromDetail(.accepted)
                }
            } label: {
                HStack(spacing: 8) {
                    if isUpdatingStatus {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }

                    Text("Kabul Et".localized)
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isUpdatingStatus)
        }
    }

    private var cancelButton: some View {
        Button {
            showCancelConfirmation = true
        } label: {
            HStack(spacing: 8) {
                if isUpdatingStatus {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.red)
                }

                Text("Rezervasyonu İptal Et".localized)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(Color.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isUpdatingStatus)
    }

    private var canCustomerCancel: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return false
        }

        return currentUserId == reservation.customerId
            && (
                reservation.status == .pending
                || reservation.status == .accepted
            )
    }

    private var canProviderDecide: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return false
        }

        return currentUserId == reservation.providerId
            && reservation.status == .pending
    }

    private func infoRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("PrimaryColor"))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
            }

            Spacer()
        }
    }

    private func statusBadge(
        _ status: ReservationStatus
    ) -> some View {
        Text(status.title)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor(status).opacity(0.15))
            .foregroundColor(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(
        _ status: ReservationStatus
    ) -> Color {
        switch status {
        case .pending:
            return .orange
        case .accepted:
            return .green
        case .rejected:
            return .red
        case .cancelled:
            return .gray
        case .completed:
            return .blue
        }
    }

    private func openChat() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Oturum açmış kullanıcı bulunamadı.".localized
            showError = true
            return
        }

        let currentUserName: String
        let participantId: String
        let participantName: String

        if currentUserId == reservation.customerId {
            currentUserName = reservation.customerName
            participantId = reservation.providerId
            participantName = reservation.providerName
        } else if currentUserId == reservation.providerId {
            currentUserName = reservation.providerName
            participantId = reservation.customerId
            participantName = reservation.customerName
        } else {
            errorMessage = "Bu rezervasyon için mesajlaşma yetkiniz yok.".localized
            showError = true
            return
        }

        isOpeningChat = true
        defer { isOpeningChat = false }

        do {
            chatConversation = try await messageRepository.getOrCreateConversation(
                currentUserId: currentUserId,
                currentUserName: currentUserName,
                participantId: participantId,
                participantName: participantName
            )

            showChat = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func updateReservationStatusFromDetail(
        _ status: ReservationStatus
    ) async {
        guard canProviderDecide else {
            errorMessage = "Bu rezervasyon için karar verme yetkiniz yok.".localized
            showError = true
            return
        }

        isUpdatingStatus = true
        defer { isUpdatingStatus = false }

        do {
            try await reservationRepository.updateReservationStatus(
                reservationId: reservation.reservationId,
                status: status
            )

            reservation = updatedReservation(status: status)
            onStatusChanged?()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func cancelReservationFromDetail() async {
        guard canCustomerCancel else {
            errorMessage = "Bu rezervasyonu iptal edemezsiniz.".localized
            showError = true
            return
        }

        isUpdatingStatus = true
        defer { isUpdatingStatus = false }

        do {
            try await reservationRepository.cancelReservation(
                reservationId: reservation.reservationId
            )

            reservation = updatedReservation(status: .cancelled)
            onStatusChanged?()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func updatedReservation(
        status: ReservationStatus
    ) -> Reservation {
        Reservation(
            reservationId: reservation.reservationId,
            serviceId: reservation.serviceId,
            serviceTitle: reservation.serviceTitle,
            servicePrice: reservation.servicePrice,
            serviceDuration: reservation.serviceDuration,
            providerId: reservation.providerId,
            providerName: reservation.providerName,
            customerId: reservation.customerId,
            customerName: reservation.customerName,
            reservationDate: reservation.reservationDate,
            addressText: reservation.addressText,
            note: reservation.note,
            status: status,
            createdAt: reservation.createdAt,
            updatedAt: Date()
        )
    }

    private func formatDate(
        _ date: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.languageCode == "en" ? "en_US" : "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
