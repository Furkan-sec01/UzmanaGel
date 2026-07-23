import Foundation
import FirebaseFirestore

///Service, bir hizmet ilanını ve o hizmete sonradan eklenen uzman/provider bilgilerini temsil eden modeldir; Firestore’daki eksik ve farklı sayı tiplerini güvenli şekilde decode eder.

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

    // Provider profile photo from service_providers.
    var providerImageURL: String = ""

    var experienceYears: Int
    var rating: Double
    var reviewCount: Int
    var isAvailable: Bool
    var providerIsAvailable: Bool = true
    var isCertified: Bool
    var acceptsCreditCard: Bool
    var locationGeo: GeoPoint?

    // Gelişmiş filtreler için ek alanlar (opsiyonel / varsayılanlar)
    var completedJobsCount: Int
    var serviceType: String
    var paymentMethods: [String]
    var languages: [String]

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
        case reviewCount
        case isAvailable
        case isCertified
        case acceptsCreditCard
        case locationGeo
        case completedJobsCount
        case serviceType
        case paymentMethods
        case languages
    }

    init(
        serviceId: String = "",
        title: String = "",
        category: String = "",
        duration: String = "",
        providerId: String = "",
        isActive: Bool = true,
        price: Int = 0,
        providerName: String = "",
        city: String = "",
        description: String = "",
        image: String = "",
        experienceYears: Int = 0,
        rating: Double = 0.0,
        reviewCount: Int = 0,
        isAvailable: Bool = true,
        isCertified: Bool = false,
        acceptsCreditCard: Bool = false,
        locationGeo: GeoPoint? = nil,
        completedJobsCount: Int = 0,
        serviceType: String = "",
        paymentMethods: [String] = [],
        languages: [String] = ["Türkçe"]
    ) {
        self.serviceId = serviceId
        self.title = title
        self.category = category
        self.duration = duration
        self.providerId = providerId
        self.isActive = isActive
        self.price = price
        self.providerName = providerName
        self.city = city
        self.description = description
        self.image = image
        self.experienceYears = experienceYears
        self.rating = rating
        self.reviewCount = reviewCount
        self.isAvailable = isAvailable
        self.isCertified = isCertified
        self.acceptsCreditCard = acceptsCreditCard
        self.locationGeo = locationGeo
        self.completedJobsCount = completedJobsCount
        self.serviceType = serviceType
        self.paymentMethods = paymentMethods
        self.languages = languages
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

        isAvailable = try c.decodeIfPresent(
            Bool.self,
            forKey: .isAvailable
        ) ?? true
        providerIsAvailable = true
        isCertified = try c.decodeIfPresent(
            Bool.self,
            forKey: .isCertified
        ) ?? false
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

        if let intVal = try? c.decode(Int.self, forKey: .reviewCount) {
            reviewCount = intVal
        } else if let dblVal = try? c.decode(Double.self, forKey: .reviewCount) {
            reviewCount = Int(dblVal)
        } else {
            reviewCount = 0
        }

        locationGeo = try c.decodeIfPresent(GeoPoint.self, forKey: .locationGeo)

        if let intVal = try? c.decode(Int.self, forKey: .completedJobsCount) {
            completedJobsCount = intVal
        } else if let dblVal = try? c.decode(Double.self, forKey: .completedJobsCount) {
            completedJobsCount = Int(dblVal)
        } else {
            completedJobsCount = 0
        }

        serviceType = try c.decodeIfPresent(String.self, forKey: .serviceType) ?? ""
        paymentMethods = try c.decodeIfPresent([String].self, forKey: .paymentMethods) ?? []
        languages = try c.decodeIfPresent([String].self, forKey: .languages) ?? ["Türkçe"]
    }
}
