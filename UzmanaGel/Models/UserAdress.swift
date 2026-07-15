//
//  UserAdress.swift
//  UzmanaGel
//
//  Created by Baran on 9.07.2026.
//

import Foundation
import FirebaseFirestore

struct UserAddress: Codable, Identifiable, Equatable {

    @DocumentID var id: String?

    var title: String          // Örn: "Ev", "İş", "Diğer"
    var fullAddress: String    // Açık adres
    var city: String
    var district: String
    var buildingNo: String
    var apartmentNo: String
    var floor: String
    var directionsNote: String // Tarif / Not
    var tag: String?           // İsteğe bağlı etiket
    var isDefault: Bool        // Varsayılan adres mi?

    var latitude: Double?
    var longitude: Double?
    var createdAt: Timestamp?

    // Boş model oluşturma yardımcısı
    static var empty: UserAddress {
        UserAddress(
            title: "Ev",
            fullAddress: "",
            city: "",
            district: "",
            buildingNo: "",
            apartmentNo: "",
            floor: "",
            directionsNote: "",
            tag: nil,
            isDefault: false,
            latitude: nil,
            longitude: nil,
            createdAt: nil
        )
    }
}
