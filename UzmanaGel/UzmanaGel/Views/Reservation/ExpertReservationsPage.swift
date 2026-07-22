//
//  ExpertReservationsPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 13.07.2026.
//

import SwiftUI

private enum ExpertReservationFilter: String, CaseIterable, Identifiable {
    case pending
    case today
    case upcoming
    case past

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending:  return "Bekleyen".localized
        case .today:    return "Bugün".localized
        case .upcoming: return "Yaklaşan".localized
        case .past:     return "Geçmiş".localized
        }
    }
}

struct ExpertReservationsPage: View {

    @StateObject private var viewModel = ExpertReservationsViewModel()
    @State private var selectedFilter: ExpertReservationFilter = .pending
    @State private var reservationToReject: Reservation?
    @State private var showRejectConfirmation = false
    @State private var reservationToShowDetail: Reservation?

    private let rejectionReasons = [
        "Takvimim bu saat için uygun değil",
        "Bu hizmet bölgesi dışında",
        "Müşteri bilgileri eksik",
        "Yoğunluk nedeniyle kabul edemiyorum",
        "Diğer"
    ]

    private let accentYellow = Color("TertiaryColor")
    private let bgColor      = Color("BackgroundColor")
    private let cardSecondaryTextColor = Color.black.opacity(0.62)

    private var filteredReservations: [Reservation] {
        switch selectedFilter {
        case .pending:
            return viewModel.reservations.filter { $0.status == .pending }
        case .today:
            return viewModel.reservations.filter {
                isActive($0) && Calendar.current.isDateInToday($0.reservationDate)
            }
        case .upcoming:
            return viewModel.reservations.filter {
                isActive($0) && $0.reservationDate > endOfToday
            }
        case .past:
            return viewModel.reservations.filter {
                $0.status == .completed
                    || $0.status == .rejected
                    || $0.status == .cancelled
                    || $0.status == .noShow
                    || $0.reservationDate < startOfToday
            }
        }
    }

    private var startOfToday: Date { Calendar.current.startOfDay(for: Date()) }
    private var endOfToday: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(accentYellow)
                            .scaleEffect(1.4)
                        Text("Rezervasyonlar yükleniyor...".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        filterPicker
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)

                        if filteredReservations.isEmpty {
                            emptyState
                        } else {
                            reservationsList
                        }
                    }
                }
            }
        }
        .navigationTitle("Gelen Rezervasyonlar".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadReservations() }
        .refreshable { await viewModel.loadReservations() }
        .alert("Hata".localized, isPresented: $viewModel.showError) {
            Button("Tamam".localized, role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .confirmationDialog(
            "Red nedeni seç".localized,
            isPresented: $showRejectConfirmation,
            titleVisibility: .visible
        ) {
            ForEach(rejectionReasons, id: \.self) { reason in
                Button(reason.localized, role: .destructive) {
                    guard let reservation = reservationToReject else { return }

                    Task {
                        await viewModel.rejectReservation(reservation, reason: reason)
                        reservationToReject = nil
                    }
                }
            }

            Button("Vazgeç".localized, role: .cancel) {
                reservationToReject = nil
            }
        } message: {
            if let reservation = reservationToReject {
                Text(String(format: "%@ adlı müşterinin rezervasyon talebini neden reddetmek istiyorsunuz?".localized, reservation.customerName))
            } else {
                Text("Bu rezervasyonu neden reddetmek istiyorsunuz?".localized)
            }
        }
        .sheet(item: $reservationToShowDetail) { reservation in
            ReservationDetailPage(reservation: reservation)
        }
    }

    // MARK: - Filter Picker
    private var filterPicker: some View {
        HStack(spacing: 0) {
            ForEach(ExpertReservationFilter.allCases) { filter in
                let isSelected = selectedFilter == filter
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = filter }
                } label: {
                    Text(filter.title)
                        .font(.caption)
                        .fontWeight(isSelected ? .bold : .regular)
                        .foregroundColor(isSelected ? .white : accentYellow)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(isSelected ? accentYellow : accentYellow.opacity(0.12))
                }
                .buttonStyle(.plain)
                if filter != ExpertReservationFilter.allCases.last {
                    Divider().background(accentYellow.opacity(0.3))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentYellow.opacity(0.4), lineWidth: 1)
        )
        .frame(height: 44)
    }

    // MARK: - Reservations List
    private var reservationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredReservations) { reservation in
                    reservationCard(reservation)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(accentYellow.opacity(0.12))
                    .frame(width: 90, height: 90)
                Circle()
                    .fill(accentYellow.opacity(0.07))
                    .frame(width: 118, height: 118)
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 38))
                    .foregroundColor(accentYellow)
            }
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.headline)
                    .foregroundColor(Color("PrimaryColor"))
                Text(emptyStateSubtitle)
                    .font(.subheadline)
                    .foregroundColor(cardSecondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .pending:  return "Bekleyen rezervasyon yok".localized
        case .today:    return "Bugün için rezervasyon yok".localized
        case .upcoming: return "Yaklaşan rezervasyon yok".localized
        case .past:     return "Geçmiş rezervasyon yok".localized
        }
    }

    private var emptyStateSubtitle: String {
        switch selectedFilter {
        case .pending:  return "Müşterilerden gelen yeni rezervasyon talepleri burada görünür.".localized
        case .today:    return "Bugünkü aktif rezervasyonlar burada görünür.".localized
        case .upcoming: return "Bugünden sonraki aktif rezervasyonlar burada görünür.".localized
        case .past:     return "Tamamlanan, reddedilen veya iptal edilen rezervasyonlar burada görünür.".localized
        }
    }

    // MARK: - Card
    private func reservationCard(_ reservation: Reservation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reservation.serviceTitle)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("PrimaryColor"))
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundColor(accentYellow)
                        Text(reservation.customerName)
                            .font(.caption)
                            .foregroundColor(cardSecondaryTextColor)
                    }
                }
                Spacer()
                statusBadge(reservation.status)
            }

            Divider().background(accentYellow.opacity(0.25))

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(accentYellow)
                    .font(.subheadline)
                Text(formatDate(reservation.reservationDate))
                    .font(.subheadline)
                    .foregroundColor(Color("PrimaryColor").opacity(0.8))
            }

            if !reservation.note.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundColor(accentYellow.opacity(0.7))
                    Text(reservation.note)
                        .font(.caption)
                        .foregroundColor(cardSecondaryTextColor)
                        .lineLimit(2)
                }
            }

            // Detail button
            Button {
                reservationToShowDetail = reservation
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("Detayı Gör".localized)
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(accentYellow)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(accentYellow.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)

            if reservation.status == .pending {
                pendingActionButtons(for: reservation)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.98))
        .environment(\.colorScheme, .light)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentYellow.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: accentYellow.opacity(0.1), radius: 8, x: 0, y: 3)
    }

    private func pendingActionButtons(for reservation: Reservation) -> some View {
        let isUpdating = viewModel.updatingReservationId == reservation.reservationId

        return HStack(spacing: 10) {
            Button {
                reservationToReject = reservation
                showRejectConfirmation = true
            } label: {
                Text("Reddet".localized)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .disabled(isUpdating)

            Button {
                Task { await viewModel.acceptReservation(reservation) }
            } label: {
                HStack(spacing: 6) {
                    if isUpdating {
                        ProgressView().scaleEffect(0.8).tint(.white)
                    }
                    Text("Kabul Et".localized)
                }
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(accentYellow)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .disabled(isUpdating)
        }
    }

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
        case .pending:    return .orange
        case .accepted:   return accentYellow
        case .inProgress: return .blue
        case .completed:  return Color("PrimaryColor")
        case .rejected:   return .red
        case .cancelled:  return .gray
        case .noShow:     return .gray
        }
    }

    private func isActive(_ reservation: Reservation) -> Bool {
        reservation.status == .pending
            || reservation.status == .accepted
            || reservation.status == .inProgress
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.languageCode == "en" ? "en_US" : "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
