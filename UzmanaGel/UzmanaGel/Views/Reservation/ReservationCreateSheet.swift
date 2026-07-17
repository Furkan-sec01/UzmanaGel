//
//  ReservationCreateSheet.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 13.07.2026.
//

import SwiftUI

struct ReservationCreateSheet: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReservationViewModel()
    @State private var hasAcceptedTerms = false

    let serviceId: String
    let serviceTitle: String
    let providerId: String
    let providerName: String
    let servicePrice: Int
    let serviceDuration: String

    private var minimumReservationDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var formattedServicePrice: String {
        "\(servicePrice) ₺"
    }

    private let accentYellow = Color("TertiaryColor")
    private let bgColor      = Color("BackgroundColor")
    private let primaryColor = Color("PrimaryColor")

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        serviceInfoCard
                        datePickerCard
                        timeSlotsCard
                        addressCard
                        noteCard
                        termsCard
                        submitButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Rezervasyon".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat".localized) { dismiss() }
                        .foregroundColor(accentYellow)
                }
            }
            .task {
                await viewModel.loadBookedSlots(providerId: providerId)
            }
            .alert("Hata".localized, isPresented: $viewModel.showError) {
                Button("Tamam".localized, role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Başarılı".localized, isPresented: $viewModel.isSuccess) {
                Button("Tamam".localized) { dismiss() }
            } message: {
                Text(successAlertMessage)
            }
        }
    }

    private var successAlertMessage: String {
        let baseMessage = "Rezervasyon talebiniz oluşturuldu.".localized

        guard !viewModel.createdReservationId.isEmpty else {
            return baseMessage
        }

        let shortReservationCode = String(viewModel.createdReservationId.suffix(6)).uppercased()
        return "\(baseMessage)\n\("Rezervasyon No".localized): #RZV-\(shortReservationCode)"
    }

    // MARK: - Service Info Card
    private var serviceInfoCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentYellow.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 18))
                        .foregroundColor(accentYellow)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(serviceTitle)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(primaryColor)
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundColor(accentYellow)
                        Text(providerName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if !serviceDuration.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundColor(accentYellow)
                            Text(serviceDuration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                Text(formattedServicePrice)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(accentYellow)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentYellow.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: accentYellow.opacity(0.1), radius: 8, x: 0, y: 3)
    }

    // MARK: - Date Picker Card
    private var datePickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(accentYellow)
                Text("Randevu Tarihi".localized)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)
            }
            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.reservationDate },
                    set: { newDate in
                        Task {
                            await viewModel.setSelectedDate(newDate, providerId: providerId)
                        }
                    }
                ),
                in: minimumReservationDate...,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(accentYellow)
            .labelsHidden()
        }
        .padding(16)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentYellow.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Time Slots Card
    private var timeSlotsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(accentYellow)
                Text("Randevu Saati".localized)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)
                Spacer()
                if viewModel.isLoadingBookedSlots {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Picker(
                "Randevu Saati".localized,
                selection: Binding(
                    get: { viewModel.selectedTimeString },
                    set: { newTime in viewModel.setSelectedTime(newTime) }
                )
            ) {
                ForEach(viewModel.availableTimeSlots, id: \.self) { time in
                    Text(viewModel.isBooked(time) ? "\(time) - \("Dolu".localized)" : time)
                        .tag(time)
                        .disabled(viewModel.isBooked(time))
                }
            }
            .pickerStyle(.menu)
            .tint(accentYellow)
        }
        .padding(16)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentYellow.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Address Card
    private var addressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundColor(accentYellow)
                Text("Adres Bilgisi".localized)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)
            }
            TextField(
                "Adresinizi veya kısa konum notunuzu yazın".localized,
                text: $viewModel.addressText,
                axis: .vertical
            )
            .lineLimit(2...5)
            .font(.subheadline)
            .padding(12)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(accentYellow.opacity(0.3), lineWidth: 1)
            )
            Text("Uzmanın sizi doğru konumda bulabilmesi için açık adres veya kısa konum notu girin.".localized)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentYellow.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Note Card
    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundColor(accentYellow)
                Text("Not (İsteğe bağlı)".localized)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)
            }
            TextField(
                "Ustaya iletmek istediğiniz bilgiler...".localized,
                text: $viewModel.note,
                axis: .vertical
            )
            .lineLimit(3...6)
            .font(.subheadline)
            .padding(12)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(accentYellow.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(16)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentYellow.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Terms Card
    private var termsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(
                "Kullanım şartlarını ve iptal koşullarını kabul ediyorum.".localized,
                isOn: $hasAcceptedTerms
            )
            .tint(accentYellow)
            .font(.subheadline)
            
            Text("Rezervasyon talebiniz uzmana iletilecek. Uzman kabul edene kadar randevu beklemede kalır.".localized)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentYellow.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            Task {
                await viewModel.createReservation(
                    serviceId: serviceId,
                    serviceTitle: serviceTitle,
                    servicePrice: servicePrice,
                    serviceDuration: serviceDuration,
                    providerId: providerId,
                    providerName: providerName
                )
            }
        } label: {
            submitButtonLabel
        }
        .buttonStyle(.plain)
        .disabled(
            viewModel.isSubmitting ||
            viewModel.isLoadingBookedSlots ||
            viewModel.isBooked(viewModel.selectedTimeString) ||
            !hasAcceptedTerms
        )
    }

    private var submitButtonLabel: some View {
        HStack(spacing: 10) {
            if viewModel.isSubmitting {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.9)
            } else {
                Image(systemName: "checkmark.circle.fill")
            }
            Text("Rezervasyon Talebi Oluştur".localized)
                .font(.system(size: 15, weight: .bold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(accentYellow.opacity(
            (viewModel.isSubmitting || viewModel.isLoadingBookedSlots || viewModel.isBooked(viewModel.selectedTimeString) || !hasAcceptedTerms) ? 0.5 : 1.0
        ))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: accentYellow.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}
