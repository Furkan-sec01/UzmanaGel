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
        case .active:    return "Aktif".localized
        case .past:      return "Geçmiş".localized
        case .cancelled: return "İptal Edildi".localized
        }
    }

    var icon: String {
        switch self {
        case .active:    return "calendar.badge.checkmark"
        case .past:      return "clock.arrow.circlepath"
        case .cancelled: return "xmark.circle"
        }
    }

    var activeColor: Color {
        switch self {
        case .active:    return Color("TertiaryColor")
        case .past:      return Color("PrimaryColor")
        case .cancelled: return .red
        }
    }
}

struct MyReservationsPage: View {

    @StateObject private var viewModel = MyReservationsViewModel()
    @State private var selectedFilter: ReservationFilter = .active
    @State private var selectedReservation: Reservation?

    // MARK: - Yellow accent
    private let accentYellow = Color("TertiaryColor")
    private let bgColor      = Color("BackgroundColor")

    private var filteredReservations: [Reservation] {
        switch selectedFilter {
        case .active:
            return viewModel.reservations.filter { $0.status == .pending || $0.status == .accepted }
        case .past:
            return viewModel.reservations.filter { $0.status == .completed || $0.status == .rejected }
        case .cancelled:
            return viewModel.reservations.filter { $0.status == .cancelled }
        }
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
                            .padding(.top, 12)
                            .padding(.bottom, 4)

                        if filteredReservations.isEmpty {
                            emptyState
                        } else {
                            reservationsList
                        }
                    }
                }
            }
        }
        .navigationTitle("Rezervasyonlarım".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadReservations() }
        .refreshable { await viewModel.loadReservations() }
        .alert("Hata".localized, isPresented: $viewModel.showError) {
            Button("Tamam".localized, role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Rezervasyonu İptal Et".localized, isPresented: $viewModel.showCancelConfirmation) {
            Button("Vazgeç".localized, role: .cancel) { }
            Button("İptal Et".localized, role: .destructive) {
                Task { await viewModel.cancelSelectedReservation() }
            }
        } message: {
            Text("Bu rezervasyon talebini iptal etmek istediğinize emin misiniz?".localized)
        }
        .sheet(item: $selectedReservation) { reservation in
            ReservationDetailPage(reservation: reservation)
        }
    }

    // MARK: - Filter Picker
    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ReservationFilter.allCases) { filter in
                    filterTab(filter)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private func filterTab(_ filter: ReservationFilter) -> some View {
        let isSelected = selectedFilter == filter
        let count = countFor(filter)

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: filter.icon)
                    .font(.system(size: 13, weight: isSelected ? .bold : .regular))

                Text(filter.title)
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? filter.activeColor : .white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            isSelected
                                ? Color.white.opacity(0.9)
                                : filter.activeColor.opacity(0.5)
                        )
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .white : filter.activeColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        filter.activeColor
                    } else {
                        filter.activeColor.opacity(0.1)
                    }
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : filter.activeColor.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? filter.activeColor.opacity(0.35) : .clear,
                radius: 8, x: 0, y: 3
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selectedFilter)
    }

    private func countFor(_ filter: ReservationFilter) -> Int {
        switch filter {
        case .active:
            return viewModel.reservations.filter { $0.status == .pending || $0.status == .accepted }.count
        case .past:
            return viewModel.reservations.filter { $0.status == .completed || $0.status == .rejected }.count
        case .cancelled:
            return viewModel.reservations.filter { $0.status == .cancelled }.count
        }
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
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 38))
                    .foregroundColor(accentYellow)
            }
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.headline)
                    .foregroundColor(Color("PrimaryColor"))
                Text(emptyStateSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .active:    return "Aktif rezervasyon yok".localized
        case .past:      return "Geçmiş rezervasyon yok".localized
        case .cancelled: return "İptal edilen rezervasyon yok".localized
        }
    }

    private var emptyStateSubtitle: String {
        switch selectedFilter {
        case .active:    return "Bir hizmet detayından rezervasyon talebi oluşturabilirsiniz.".localized
        case .past:      return "Tamamlanan veya reddedilen rezervasyonlar burada görünür.".localized
        case .cancelled: return "İptal edilen rezervasyonlar burada görünür.".localized
        }
    }

    // MARK: - Card
    private func reservationCard(_ reservation: Reservation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title + badge
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
                        Text(reservation.providerName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                statusBadge(reservation.status)
            }

            Divider().background(accentYellow.opacity(0.25))

            // Date row
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(accentYellow)
                    .font(.subheadline)
                Text(formatDate(reservation.reservationDate))
                    .font(.subheadline)
                    .foregroundColor(Color("PrimaryColor").opacity(0.8))
            }

            // Note
            if !reservation.note.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundColor(accentYellow.opacity(0.7))
                    Text(reservation.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            // Buttons
            HStack(spacing: 10) {
                Button {
                    selectedReservation = reservation
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "info.circle")
                        Text("Detay".localized)
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

                if canCancel(reservation) {
                    Button {
                        viewModel.requestCancel(reservation)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "xmark.circle")
                            Text("İptal Et".localized)
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isCancelling)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentYellow.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: accentYellow.opacity(0.1), radius: 8, x: 0, y: 3)
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
        case .accepted:  return .green
        case .rejected:  return .red
        case .cancelled: return .gray
        case .completed: return Color("PrimaryColor")
        }
    }

    private func canCancel(_ reservation: Reservation) -> Bool {
        reservation.status == .pending || reservation.status == .accepted
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.languageCode == "en" ? "en_US" : "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
