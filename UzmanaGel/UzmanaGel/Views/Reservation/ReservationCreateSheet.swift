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

    var body: some View {
        NavigationStack {
            Form {
                Section("Randevu Bilgileri".localized) {
                    DatePicker(
                        "Randevu Tarihi".localized,
                        selection: $viewModel.reservationDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )

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
                    .disabled(viewModel.isSubmitting)
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
