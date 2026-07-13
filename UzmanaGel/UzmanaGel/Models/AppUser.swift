//
//  AppUser.swift
//  UzmanaGel
//
//  Created by Abdullah B on 5.02.2026.
//

import Foundation
import FirebaseFirestore


struct AppUser: Codable, Identifiable {

    @DocumentID var id: String?

    var displayName: String
    var email: String
    var phoneNumber: String?
    var photoURL: String?
    var role: String?
    var createdAt: Timestamp?

    var isExpert: Bool {
        role == "expert"
    }
}
