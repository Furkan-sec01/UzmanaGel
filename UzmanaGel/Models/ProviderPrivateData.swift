//
//  ProviderPrivateData.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 28.07.2026.
//

import Foundation
import FirebaseFirestore

struct ProviderPrivateData: Codable, Identifiable {

    @DocumentID var id: String?

    var providerId: String

    var email: String
    var phoneNumber: String

    var taxNumber: String?

    var bankName: String?
    var iban: String?
    var accountHolderName: String?

    var certificateURLs: [String]

    var idFrontURL: String?
    var idBackURL: String?

    var createdAt: Timestamp?
    var updatedAt: Timestamp?

    enum CodingKeys: String, CodingKey {
        case providerId
        case email
        case phoneNumber
        case taxNumber
        case bankName
        case iban
        case accountHolderName
        case certificateURLs
        case idFrontURL
        case idBackURL
        case createdAt
        case updatedAt
    }

    init(
        id: String? = nil,
        providerId: String,
        email: String = "",
        phoneNumber: String = "",
        taxNumber: String? = nil,
        bankName: String? = nil,
        iban: String? = nil,
        accountHolderName: String? = nil,
        certificateURLs: [String] = [],
        idFrontURL: String? = nil,
        idBackURL: String? = nil,
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.providerId = providerId
        self.email = email
        self.phoneNumber = phoneNumber
        self.taxNumber = taxNumber
        self.bankName = bankName
        self.iban = iban
        self.accountHolderName = accountHolderName
        self.certificateURLs = certificateURLs
        self.idFrontURL = idFrontURL
        self.idBackURL = idBackURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        providerId = try container.decodeIfPresent(
            String.self,
            forKey: .providerId
        ) ?? ""

        email = try container.decodeIfPresent(
            String.self,
            forKey: .email
        ) ?? ""

        phoneNumber = try container.decodeIfPresent(
            String.self,
            forKey: .phoneNumber
        ) ?? ""

        taxNumber = try container.decodeIfPresent(
            String.self,
            forKey: .taxNumber
        )

        bankName = try container.decodeIfPresent(
            String.self,
            forKey: .bankName
        )

        iban = try container.decodeIfPresent(
            String.self,
            forKey: .iban
        )

        accountHolderName = try container.decodeIfPresent(
            String.self,
            forKey: .accountHolderName
        )

        certificateURLs = try container.decodeIfPresent(
            [String].self,
            forKey: .certificateURLs
        ) ?? []

        idFrontURL = try container.decodeIfPresent(
            String.self,
            forKey: .idFrontURL
        )

        idBackURL = try container.decodeIfPresent(
            String.self,
            forKey: .idBackURL
        )

        createdAt = try container.decodeIfPresent(
            Timestamp.self,
            forKey: .createdAt
        )

        updatedAt = try container.decodeIfPresent(
            Timestamp.self,
            forKey: .updatedAt
        )
    }
}
