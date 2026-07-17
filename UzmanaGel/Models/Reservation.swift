//
//  Reservation.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 13.07.2026.
//

import Foundation

enum ReservationStatus: String, Codable, CaseIterable {
    case pending
    case accepted
    case rejected
    case cancelled
    case completed

    var title: String {
        switch self {
        case .pending:
            return "Beklemede".localized
        case .accepted:
            return "Onaylandı".localized
        case .rejected:
            return "Reddedildi".localized
        case .cancelled:
            return "İptal Edildi".localized
        case .completed:
            return "Tamamlandı".localized
        }
    }
}

struct Reservation: Identifiable, Codable, Hashable {
    let reservationId: String

    let serviceId: String
    let serviceTitle: String

    let providerId: String
    let providerName: String

    let customerId: String
    let customerName: String

    let reservationDate: Date
    let addressText: String
    let note: String
    let status: ReservationStatus

    let createdAt: Date
    let updatedAt: Date

    var id: String {
        reservationId
    }
}
