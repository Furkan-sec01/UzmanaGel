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
        case .pending:
            return "Bekleyen".localized
        case .today:
            return "Bugün".localized
        case .upcoming:
            return "Yaklaşan".localized
        case .past:
            return "Geçmiş".localized
        }
    }
}

struct ExpertReservationsPage: View {

    @StateObject private var viewModel = ExpertReservationsViewModel()
    @State private var selectedFilter: ExpertReservationFilter = .pending
    @State private var reservationToReject: Reservation?
    @State private var showRejectConfirmation = false
    @State private var reservationToShowDetail: Reservation?
    private var filteredReservations: [Reservation] {
        switch selectedFilter {
        case .pending:
            return viewModel.reservations.filter {
                $0.status == .pending
            }

        case .today:
            return viewModel.reservations.filter {
                isActive($0)
                && Calendar.current.isDateInToday($0.reservationDate)
            }

        case .upcoming:
            return viewModel.reservations.filter {
                isActive($0)
                && $0.reservationDate > endOfToday
            }

        case .past:
            return viewModel.reservations.filter {
                $0.status == .completed
                || $0.status == .rejected
                || $0.status == .cancelled
                || $0.reservationDate < startOfToday
            }
        }
    }

    private var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var endOfToday: Date {
        Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: startOfToday
        ) ?? Date()
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Rezervasyonlar yükleniyor...".localized)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    filterPicker

                    if filteredReservations.isEmpty {
                        emptyState
                    } else {
                        reservationsList
                    }
                }
            }
        }
        .navigationTitle("Gelen Rezervasyonlar".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadReservations()
        }
        .refreshable {
            await viewModel.loadReservations()
        }
        .alert("Hata".localized, isPresented: $viewModel.showError) {
            Button("Tamam".localized, role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .confirmationDialog(
            "Rezervasyonu reddet".localized,
            isPresented: $showRejectConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reddet".localized, role: .destructive) {
                guard let reservation = reservationToReject else { return }

                Task {
                    await viewModel.rejectReservation(reservation)
                    reservationToReject = nil
                }
            }

            Button("Vazgeç".localized, role: .cancel) {
                reservationToReject = nil
            }
        } message: {
            if let reservation = reservationToReject {
                Text(String(format: "%@ adlı müşterinin rezervasyon talebini reddetmek istediğinizden emin misiniz?".localized, reservation.customerName))
            } else {
                Text("Bu rezervasyonu reddetmek istediğinizden emin misiniz?".localized)
            }
        }
        .sheet(item: $reservationToShowDetail) { reservation in
            ReservationDetailPage(reservation: reservation)
        }
    }

    private var filterPicker: some View {
        Picker("Rezervasyon filtresi".localized, selection: $selectedFilter) {
            ForEach(ExpertReservationFilter.allCases) { filter in
                Text(filter.title)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var reservationsList: some View {
        List {
            ForEach(filteredReservations) { reservation in
                reservationCard(reservation)
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundColor(.secondary)

            Text(emptyStateTitle)
                .font(.headline)

            Text(emptyStateSubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .pending:
            return "Bekleyen rezervasyon yok".localized
        case .today:
            return "Bugün için rezervasyon yok".localized
        case .upcoming:
            return "Yaklaşan rezervasyon yok".localized
        case .past:
            return "Geçmiş rezervasyon yok".localized
        }
    }

    private var emptyStateSubtitle: String {
        switch selectedFilter {
        case .pending:
            return "Müşterilerden gelen yeni rezervasyon talepleri burada görünür.".localized
        case .today:
            return "Bugünkü aktif rezervasyonlar burada görünür.".localized
        case .upcoming:
            return "Bugünden sonraki aktif rezervasyonlar burada görünür.".localized
        case .past:
            return "Tamamlanan, reddedilen veya iptal edilen rezervasyonlar burada görünür.".localized
        }
    }

    private func reservationCard(
        _ reservation: Reservation
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reservation.serviceTitle)
                        .font(.headline)

                    Text(reservation.customerName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                statusBadge(reservation.status)
            }

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)

                Text(formatDate(reservation.reservationDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if !reservation.note.isEmpty {
                Text(reservation.note)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            detailButton(for: reservation)

            if reservation.status == .pending {
                pendingActionButtons(for: reservation)
            }        }
        .padding(.vertical, 8)
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
    
    private func detailButton(
        for reservation: Reservation
    ) -> some View {
        Button {
            reservationToShowDetail = reservation
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                Text("Detayı Gör".localized)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(Color("PrimaryColor"))
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(Color("PrimaryColor").opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
    
    private func pendingActionButtons(
        for reservation: Reservation
    ) -> some View {
        let isUpdating = viewModel.updatingReservationId == reservation.reservationId

        return HStack(spacing: 10) {
            Button {
                reservationToReject = reservation
                showRejectConfirmation = true
            } label: {
                Text("Reddet".localized)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(isUpdating)

            Button {
                Task {
                    await viewModel.acceptReservation(reservation)
                }
            } label: {
                HStack(spacing: 6) {
                    if isUpdating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }

                    Text("Kabul Et".localized)
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(isUpdating)
        }
        .padding(.top, 6)
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

    private func isActive(
        _ reservation: Reservation
    ) -> Bool {
        reservation.status == .pending || reservation.status == .accepted
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
