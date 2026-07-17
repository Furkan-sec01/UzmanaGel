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

    private let rejectionReasons = [
        "Takvimim bu saat için uygun değil",
        "Bu hizmet bölgesi dışında",
        "Müşteri bilgileri eksik",
        "Yoğunluk nedeniyle kabul edemiyorum",
        "Diğer"
    ]
    @State private var errorMessage = ""
    @State private var showError = false

    private let messageRepository = MessageRepository()
    private let reservationRepository = ReservationRepository()

    private let accentYellow = Color("TertiaryColor")
    private let bgColor      = Color("BackgroundColor")
    private let primaryColor = Color("PrimaryColor")
    private let cardSecondaryTextColor = Color.black.opacity(0.62)

    init(reservation: Reservation, onStatusChanged: (() -> Void)? = nil) {
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
            .background(bgColor.ignoresSafeArea())
            .navigationTitle("Rezervasyon Detayı".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat".localized) { dismiss() }
                        .foregroundColor(accentYellow)
                }
            }
            .navigationDestination(isPresented: $showChat) {
                if let chatConversation { ChatDetailPage(conversation: chatConversation) }
            }
            .alert("Hata".localized, isPresented: $showError) {
                Button("Tamam".localized, role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog("Rezervasyonu iptal et".localized,
                                isPresented: $showCancelConfirmation,
                                titleVisibility: .visible) {
                Button("İptal Et".localized, role: .destructive) {
                    Task { await cancelReservationFromDetail() }
                }
                Button("Vazgeç".localized, role: .cancel) { }
            } message: {
                Text("Bu rezervasyonu iptal etmek istediğinizden emin misiniz?".localized)
            }
            .confirmationDialog(
                "Red nedeni seç".localized,
                isPresented: $showRejectConfirmation,
                titleVisibility: .visible
            ) {
                ForEach(rejectionReasons, id: \.self) { reason in
                    Button(reason.localized, role: .destructive) {
                        Task {
                            await updateReservationStatusFromDetail(
                                .rejected,
                                rejectionReason: reason
                            )
                        }
                    }
                }

                Button("Vazgeç".localized, role: .cancel) { }
            } message: {
                Text(String(format: "%@ adlı müşterinin rezervasyon talebini neden reddetmek istiyorsunuz?".localized, reservation.customerName))
            }
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                // Yellow icon
                ZStack {
                    Circle()
                        .fill(accentYellow.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(accentYellow)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(reservation.serviceTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(primaryColor)

                    Text(reservation.providerName)
                        .font(.subheadline)
                        .foregroundColor(cardSecondaryTextColor)
                }

                Spacer()
                statusBadge(reservation.status)
            }

            Divider().background(accentYellow.opacity(0.3))

            infoRow(icon: "calendar", title: "Randevu Tarihi".localized, value: formatDate(reservation.reservationDate))
        }
        .padding(16)
        .background(Color.white.opacity(0.98))
        .environment(\.colorScheme, .light)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentYellow.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: accentYellow.opacity(0.12), radius: 10, x: 0, y: 4)
    }

    // MARK: - Detail Section
    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "list.bullet.clipboard", title: "Bilgiler".localized)

            VStack(spacing: 10) {
                infoRow(icon: "person", title: "Müşteri".localized, value: reservation.customerName)
                Divider().background(accentYellow.opacity(0.2))
                infoRow(icon: "briefcase", title: "Hizmet".localized, value: reservation.serviceTitle)
                if !reservation.serviceDuration.isEmpty {
                    Divider().background(accentYellow.opacity(0.2))
                    infoRow(icon: "timer", title: "Süre".localized, value: reservation.serviceDuration)
                }
                Divider().background(accentYellow.opacity(0.2))
                infoRow(icon: "turkishlirasign.circle", title: "Tahmini Ücret".localized, value: "\(reservation.servicePrice) ₺")
                Divider().background(accentYellow.opacity(0.2))
                infoRow(icon: "clock", title: "Oluşturulma Tarihi".localized, value: formatDate(reservation.createdAt))
            }
            .padding(16)
            .background(Color.white.opacity(0.98))
        .environment(\.colorScheme, .light)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentYellow.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "mappin.and.ellipse", title: "Adres".localized)

            Text(reservation.addressText.isEmpty ? "Adres eklenmemiş.".localized : reservation.addressText)
                .font(.subheadline)
                .foregroundColor(cardSecondaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white.opacity(0.98))
        .environment(\.colorScheme, .light)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentYellow.opacity(0.25), lineWidth: 1)
                )
        }
    }

    // MARK: - Note Section
    @ViewBuilder
    private var rejectionReasonSection: some View {
        if reservation.status == .rejected && !reservation.rejectionReason.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Red Sebebi".localized)
                    .font(.headline)

                Text(reservation.rejectionReason)
                    .font(.subheadline)
                    .foregroundColor(cardSecondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white.opacity(0.98))
                .environment(\.colorScheme, .light)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "note.text", title: "Not".localized)

            Text(reservation.note.isEmpty ? "Not eklenmemiş.".localized : reservation.note)
                .font(.subheadline)
                .foregroundColor(cardSecondaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white.opacity(0.98))
        .environment(\.colorScheme, .light)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentYellow.opacity(0.25), lineWidth: 1)
                )
        }
    }

    // MARK: - Action Section
    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "bolt.fill", title: "İşlemler".localized)
            messageButton
            if canProviderDecide { providerDecisionButtons }
            if canCustomerCancel { cancelButton }
        }
    }

    // MARK: - Section Header
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(accentYellow)
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(primaryColor)
        }
    }

    // MARK: - Message Button
    private var messageButton: some View {
        Button {
            Task { await openChat() }
        } label: {
            HStack(spacing: 10) {
                if isOpeningChat {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "message.fill")
                }
                Text("Mesaj Gönder".localized)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [accentYellow, accentYellow.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: accentYellow.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isOpeningChat || isUpdatingStatus)
    }

    // MARK: - Provider Decision Buttons
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
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.red.opacity(0.25), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isUpdatingStatus)

            Button {
                Task { await updateReservationStatusFromDetail(.accepted) }
            } label: {
                HStack(spacing: 8) {
                    if isUpdatingStatus {
                        ProgressView().scaleEffect(0.8).tint(.white)
                    }
                    Text("Kabul Et".localized)
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(accentYellow)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: accentYellow.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(isUpdatingStatus)
        }
    }

    // MARK: - Cancel Button
    private var cancelButton: some View {
        Button {
            showCancelConfirmation = true
        } label: {
            HStack(spacing: 8) {
                if isUpdatingStatus {
                    ProgressView().scaleEffect(0.8).tint(.red)
                }
                Text("Rezervasyonu İptal Et".localized)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isUpdatingStatus)
    }

    // MARK: - Info Row
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentYellow.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(accentYellow)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(cardSecondaryTextColor)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(primaryColor)
                    .textSelection(.enabled)
            }
            Spacer()
        }
    }

    // MARK: - Status Badge
    private func statusBadge(_ status: ReservationStatus) -> some View {
        Text(status.title)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor(status).opacity(0.13))
            .foregroundColor(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: ReservationStatus) -> Color {
        switch status {
        case .pending:   return .orange
        case .accepted:  return accentYellow
        case .rejected:  return .red
        case .cancelled: return .gray
        case .completed: return primaryColor
        }
    }

    // MARK: - Logic
    private var canCustomerCancel: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return uid == reservation.customerId
            && (reservation.status == .pending || reservation.status == .accepted)
    }

    private var canProviderDecide: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return uid == reservation.providerId && reservation.status == .pending
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
        _ status: ReservationStatus,
        rejectionReason: String? = nil
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
                reservationId: reservation.reservationId, status: status)
            reservation = updatedReservation(
                status: status,
                rejectionReason: rejectionReason
            )
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
            try await reservationRepository.cancelReservation(reservationId: reservation.reservationId)
            reservation = updatedReservation(status: .cancelled)
            onStatusChanged?()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func updatedReservation(
        status: ReservationStatus,
        rejectionReason: String? = nil
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
            rejectionReason: rejectionReason ?? reservation.rejectionReason,
            createdAt: reservation.createdAt,
            updatedAt: Date()
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.languageCode == "en" ? "en_US" : "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
