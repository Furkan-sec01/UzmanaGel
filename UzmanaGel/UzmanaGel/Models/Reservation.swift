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
            return "Beklemede"
        case .accepted:
            return "Onaylandı"
        case .rejected:
            return "Reddedildi"
        case .cancelled:
            return "İptal Edildi"
        case .completed:
            return "Tamamlandı"
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
    let note: String
    let status: ReservationStatus

    let createdAt: Date
    let updatedAt: Date

    var id: String {
        reservationId
    }
}
