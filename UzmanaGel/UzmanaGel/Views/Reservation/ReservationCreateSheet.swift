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
                Section("Randevu Bilgileri") {
                    DatePicker(
                        "Randevu Tarihi",
                        selection: $viewModel.reservationDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    TextField(
                        "Not ekle",
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
                            Text("Rezervasyon Talebi Oluştur")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(viewModel.isSubmitting)
                }
            }
            .navigationTitle("Rezervasyon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .alert("Hata", isPresented: $viewModel.showError) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Başarılı", isPresented: $viewModel.isSuccess) {
                Button("Tamam") {
                    dismiss()
                }
            } message: {
                Text("Rezervasyon talebiniz oluşturuldu.")
            }
        }
    }
}
