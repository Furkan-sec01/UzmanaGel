import Foundation
import FirebaseFirestore

struct Service: Identifiable, Codable, Hashable {

    static func == (lhs: Service, rhs: Service) -> Bool {
        lhs.serviceId == rhs.serviceId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(serviceId)
    }

    var id: String { serviceId }

    var serviceId: String
    let title: String
    let category: String
    let duration: String
    let providerId: String

    let isActive: Bool

    let price: Int

    // Provider'dan gelen alanlar (birleştirme sonrası doldurulur)
    var providerName: String
    var city: String
    var description: String
    var image: String
    var experienceYears: Int
    var rating: Double
    var isAvailable: Bool
    var isCertified: Bool
    var acceptsCreditCard: Bool
    var locationGeo: GeoPoint?

    enum CodingKeys: String, CodingKey {
        case serviceId
        case title
        case category
        case duration
        case providerId
        case isActive
        case price
        case providerName
        case city
        case description
        case image
        case experienceYears
        case rating
        case isAvailable
        case isCertified
        case acceptsCreditCard
        case locationGeo
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        serviceId    = try c.decodeIfPresent(String.self, forKey: .serviceId) ?? ""
        title        = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        category     = try c.decodeIfPresent(String.self, forKey: .category) ?? ""
        duration     = try c.decodeIfPresent(String.self, forKey: .duration) ?? ""
        providerId   = try c.decodeIfPresent(String.self, forKey: .providerId) ?? ""

        isActive     = try c.decodeIfPresent(Bool.self, forKey: .isActive) ?? true

        // Firestore sayısal alanları Double olarak saklayabilir
        if let intVal = try? c.decode(Int.self, forKey: .price) {
            price = intVal
        } else if let dblVal = try? c.decode(Double.self, forKey: .price) {
            price = Int(dblVal)
        } else {
            price = 0
        }

        // Provider'dan gelen veya opsiyonel alanlar
        providerName = try c.decodeIfPresent(String.self, forKey: .providerName) ?? ""
        city         = try c.decodeIfPresent(String.self, forKey: .city) ?? ""
        description  = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        image        = try c.decodeIfPresent(String.self, forKey: .image) ?? ""

        isAvailable      = try c.decodeIfPresent(Bool.self, forKey: .isAvailable) ?? true
        isCertified      = try c.decodeIfPresent(Bool.self, forKey: .isCertified) ?? false
        acceptsCreditCard = try c.decodeIfPresent(Bool.self, forKey: .acceptsCreditCard) ?? false

        if let intVal = try? c.decode(Int.self, forKey: .experienceYears) {
            experienceYears = intVal
        } else if let dblVal = try? c.decode(Double.self, forKey: .experienceYears) {
            experienceYears = Int(dblVal)
        } else {
            experienceYears = 0
        }

        if let dblVal = try? c.decode(Double.self, forKey: .rating) {
            rating = dblVal
        } else if let intVal = try? c.decode(Int.self, forKey: .rating) {
            rating = Double(intVal)
        } else {
            rating = 0.0
        }

        locationGeo = try c.decodeIfPresent(GeoPoint.self, forKey: .locationGeo)
    }
}
