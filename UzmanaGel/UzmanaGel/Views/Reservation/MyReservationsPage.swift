//
//  MyReservationsPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 13.07.2026.
//

import SwiftUI

private enum ReservationFilter: String, CaseIterable, Identifiable {
    case active
    case past
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active:
            return "Aktif".localized
        case .past:
            return "Geçmiş".localized
        case .cancelled:
            return "İptal Edildi".localized
        }
    }
}

struct MyReservationsPage: View {

    @StateObject private var viewModel = MyReservationsViewModel()
    @State private var selectedFilter: ReservationFilter = .active
    @State private var selectedReservation: Reservation?

    private var filteredReservations: [Reservation] {
        switch selectedFilter {
        case .active:
            return viewModel.reservations.filter {
                $0.status == .pending || $0.status == .accepted
            }
        case .past:
            return viewModel.reservations.filter {
                $0.status == .completed || $0.status == .rejected
            }
        case .cancelled:
            return viewModel.reservations.filter {
                $0.status == .cancelled
            }
        }
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
        .navigationTitle("Rezervasyonlarım".localized)
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
        .alert(
            "Rezervasyonu İptal Et".localized,
            isPresented: $viewModel.showCancelConfirmation
        ) {
            Button("Vazgeç".localized, role: .cancel) { }

            Button("İptal Et".localized, role: .destructive) {
                Task {
                    await viewModel.cancelSelectedReservation()
                }
            }
        } message: {
            Text("Bu rezervasyon talebini iptal etmek istediğinize emin misiniz?".localized)
        }
        .sheet(item: $selectedReservation) { reservation in
            ReservationDetailPage(reservation: reservation)
        }
    }

    private var filterPicker: some View {
        Picker("Rezervasyon filtresi".localized, selection: $selectedFilter) {
            ForEach(ReservationFilter.allCases) { filter in
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

            Image(systemName: "calendar.badge.clock")
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
        case .active:
            return "Aktif rezervasyon yok".localized
        case .past:
            return "Geçmiş rezervasyon yok".localized
        case .cancelled:
            return "İptal edilen rezervasyon yok".localized
        }
    }

    private var emptyStateSubtitle: String {
        switch selectedFilter {
        case .active:
            return "Bir hizmet detayından rezervasyon talebi oluşturabilirsiniz.".localized
        case .past:
            return "Tamamlanan veya reddedilen rezervasyonlar burada görünür.".localized
        case .cancelled:
            return "İptal edilen rezervasyonlar burada görünür.".localized
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

                    Text(reservation.providerName)
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
            
            Button {
                selectedReservation = reservation
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                    Text("Detay".localized)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("PrimaryColor"))
            }
            .buttonStyle(.plain)
            
            if canCancel(reservation) {
                Button {
                    viewModel.requestCancel(reservation)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                        Text("İptal Et".localized)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isCancelling)
            }
        }
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

    private func canCancel(
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
