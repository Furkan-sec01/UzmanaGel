import Foundation
import FirebaseFirestore

struct ServiceProvider: Identifiable, Codable {

    var id: String { providerId }

    let providerId: String
    let businessName: String
    let city: String
    let isActive: Bool

    // Opsiyonel alanlar (ileride eklenebilir)
    let description: String
    let image: String
    let phoneNumber: String
    let rating: Double
    let experienceYears: Int
    let isCertified: Bool
    let acceptsCreditCard: Bool
    let locationGeo: GeoPoint?

    enum CodingKeys: String, CodingKey {
        case providerId
        case businessName
        case city
        case isActive
        case description
        case image
        case phoneNumber
        case rating
        case experienceYears
        case isCertified
        case acceptsCreditCard
        case locationGeo
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        providerId   = try c.decodeIfPresent(String.self, forKey: .providerId) ?? ""
        businessName = try c.decodeIfPresent(String.self, forKey: .businessName) ?? ""
        city         = try c.decodeIfPresent(String.self, forKey: .city) ?? ""
        isActive     = try c.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        description  = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        image        = try c.decodeIfPresent(String.self, forKey: .image) ?? ""
        phoneNumber  = try c.decodeIfPresent(String.self, forKey: .phoneNumber) ?? ""
        isCertified  = try c.decodeIfPresent(Bool.self, forKey: .isCertified) ?? false
        acceptsCreditCard = try c.decodeIfPresent(Bool.self, forKey: .acceptsCreditCard) ?? false

        if let dblVal = try? c.decode(Double.self, forKey: .rating) {
            rating = dblVal
        } else if let intVal = try? c.decode(Int.self, forKey: .rating) {
            rating = Double(intVal)
        } else {
            rating = 0.0
        }

        if let intVal = try? c.decode(Int.self, forKey: .experienceYears) {
            experienceYears = intVal
        } else if let dblVal = try? c.decode(Double.self, forKey: .experienceYears) {
            experienceYears = Int(dblVal)
        } else {
            experienceYears = 0
        }

        locationGeo = try c.decodeIfPresent(GeoPoint.self, forKey: .locationGeo)
    }
}
