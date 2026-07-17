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

    var body: some View {
        NavigationStack {
            Form {
                Section("Hizmet Özeti".localized) {
                    reservationSummaryRow(
                        title: "Hizmet".localized,
                        value: serviceTitle
                    )

                    reservationSummaryRow(
                        title: "Uzman".localized,
                        value: providerName
                    )

                    if !serviceDuration.isEmpty {
                        reservationSummaryRow(
                            title: "Süre".localized,
                            value: serviceDuration
                        )
                    }

                    reservationSummaryRow(
                        title: "Tahmini Ücret".localized,
                        value: formattedServicePrice
                    )
                }

                Section("Randevu Bilgileri".localized) {
                    DatePicker(
                        "Randevu Günü".localized,
                        selection: Binding(
                            get: {
                                viewModel.reservationDate
                            },
                            set: { newDate in
                                Task {
                                    await viewModel.setSelectedDate(
                                        newDate,
                                        providerId: providerId
                                    )
                                }
                            }
                        ),
                        in: minimumReservationDate...,
                        displayedComponents: [.date]
                    )

                    if viewModel.isLoadingBookedSlots {
                        HStack {
                            ProgressView()
                            Text("Dolu saatler kontrol ediliyor...".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Picker(
                        "Randevu Saati".localized,
                        selection: Binding(
                            get: {
                                viewModel.selectedTimeString
                            },
                            set: { newTime in
                                viewModel.setSelectedTime(newTime)
                            }
                        )
                    ) {
                        ForEach(viewModel.availableTimeSlots, id: \.self) { time in
                            Text(viewModel.isBooked(time) ? "\(time) - \("Dolu".localized)" : time)
                                .tag(time)
                                .disabled(viewModel.isBooked(time))
                        }
                    }
                    .pickerStyle(.menu)

                    Section("Adres Bilgisi".localized) {
                        TextField(
                            "Adresinizi veya kısa konum notunuzu yazın".localized,
                            text: $viewModel.addressText,
                            axis: .vertical
                        )
                        .lineLimit(2...5)

                        Text("Uzmanın sizi doğru konumda bulabilmesi için açık adres veya kısa konum notu girin.".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    TextField(
                        "Not ekle".localized,
                        text: $viewModel.note,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                Section {
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
                        if viewModel.isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Rezervasyon Talebi Oluştur".localized)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(
                        viewModel.isSubmitting ||
                        viewModel.isLoadingBookedSlots ||
                        viewModel.isBooked(viewModel.selectedTimeString)
                    )
                }
            }
            .navigationTitle("Rezervasyon".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat".localized) {
                        dismiss()
                    }
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
                Button("Tamam".localized) {
                    dismiss()
                }
            } message: {
                Text("Rezervasyon talebiniz oluşturuldu.".localized)
            }
        }
    }
    private func reservationSummaryRow(
        title: String,
        value: String
    ) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }

}
