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
    case inProgress
    case completed
    case rejected
    case cancelled
    case noShow

    var title: String {
        switch self {
        case .pending:
            return "Beklemede".localized
        case .accepted:
            return "Onaylandı".localized
        case .inProgress:
            return "Devam Ediyor".localized
        case .completed:
            return "Tamamlandı".localized
        case .rejected:
            return "Reddedildi".localized
        case .cancelled:
            return "İptal Edildi".localized
        case .noShow:
            return "Müşteri Gelmedi".localized
        }
    }

    func canTransition(to newStatus: ReservationStatus) -> Bool {
        switch self {
        case .pending:
            return newStatus == .accepted
                || newStatus == .rejected
                || newStatus == .cancelled

        case .accepted:
            return newStatus == .inProgress
                || newStatus == .noShow
                || newStatus == .cancelled

        case .inProgress:
            return newStatus == .completed

        case .completed, .rejected, .cancelled, .noShow:
            return false
        }
    }

    var isBlockingSlot: Bool {
        self == .pending
            || self == .accepted
            || self == .inProgress
    }
}

struct Reservation: Identifiable, Codable, Hashable {
    let reservationId: String

    let serviceId: String
    let serviceTitle: String
    let servicePrice: Int
    let serviceDuration: String

    let providerId: String
    let providerName: String

    let customerId: String
    let customerName: String

    let reservationDate: Date
    let addressText: String
    let note: String
    let status: ReservationStatus
    let rejectionReason: String

    let createdAt: Date
    let updatedAt: Date

    var id: String {
        reservationId
    }
}
