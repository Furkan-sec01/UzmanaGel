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

    private var minimumReservationDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        NavigationStack {
            Form {
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
}
