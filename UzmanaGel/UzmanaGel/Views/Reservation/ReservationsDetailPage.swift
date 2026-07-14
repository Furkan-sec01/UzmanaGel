//
//  ReservationsDetailPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 14.07.2026.
//

import SwiftUI

struct ReservationDetailPage: View {

    let reservation: Reservation

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    detailSection
                    noteSection
                }
                .padding(20)
            }
            .background(Color("BackgroundColor"))
            .navigationTitle("Rezervasyon Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
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
                title: "Randevu Tarihi",
                value: formatDate(reservation.reservationDate)
            )
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bilgiler")
                .font(.headline)

            VStack(spacing: 12) {
                infoRow(
                    icon: "person",
                    title: "Müşteri",
                    value: reservation.customerName
                )

                infoRow(
                    icon: "briefcase",
                    title: "Hizmet",
                    value: reservation.serviceTitle
                )

        

                infoRow(
                    icon: "clock",
                    title: "Oluşturulma Tarihi",
                    value: formatDate(reservation.createdAt)
                )
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Not")
                .font(.headline)

            Text(reservation.note.isEmpty ? "Not eklenmemiş." : reservation.note)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
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

    private func formatDate(
        _ date: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
