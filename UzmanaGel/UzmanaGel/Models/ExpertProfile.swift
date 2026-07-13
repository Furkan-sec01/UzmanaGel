import Foundation
import FirebaseFirestore

enum BusinessType: String, Codable, CaseIterable {
    case individual = "sahis"
    case company = "sirket"

    var displayName: String {
        switch self {
        case .individual: return "Şahıs"
        case .company: return "Şirket"
        }
    }
}

enum ApplicationStatus: String, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
}

struct ExpertProfile: Codable, Identifiable {

    @DocumentID var id: String?

    var displayName: String
    var email: String
    var phoneNumber: String

    var businessName: String
    var serviceCategories: [String]
    var businessType: String
    var taxNumber: String?

    var experienceYears: Int
    var expertiseAreas: [String]
    var certificateURLs: [String]
    var educationLevel: String
    var schoolName: String

    var status: String
    var createdAt: Timestamp?

    /// Uzman profil fotoğrafı (Storage URL)
    var profileImageURL: String?

    // Çalışma detayları (profil tamamlama)
    var serviceCities: [String]
    /// Çalışılan günler: "1"=Pazartesi ... "7"=Pazar
    var workingDays: [String]
    var workingHoursStart: String?
    var workingHoursEnd: String?
    var minPrice: Int?
    var maxPrice: Int?
    var serviceType: String?

    // Banka bilgileri (güvenli saklama – Firestore rules ile kısıtlanmalı)
    var bankName: String?
    var iban: String?
    var accountHolderName: String?

    /// Portföy: önceki işlerden fotoğraflar (Storage URL’leri)
    var portfolioImageURLs: [String]

    /// Adres (görüntüleme / iletişim)
    var address: String?
    /// Hakkında (kısa tanıtım metni)
    var about: String?
    /// Konum (harita / navigasyon için; adres kaydedilirken geocode ile doldurulur)
    var locationGeo: GeoPoint?

    /// Kimlik belgesi ön yüz (Storage URL)
    var idFrontURL: String?
    /// Kimlik belgesi arka yüz (Storage URL)
    var idBackURL: String?

    enum CodingKeys: String, CodingKey {
        case displayName, email, phoneNumber, businessName, serviceCategories
        case businessType, taxNumber, experienceYears, expertiseAreas, certificateURLs
        case educationLevel, schoolName, status, createdAt
        case profileImageURL
        case serviceCities, workingDays, workingHoursStart, workingHoursEnd, minPrice, maxPrice, serviceType
        case bankName, iban, accountHolderName
        case portfolioImageURLs
        case address, about
        case locationGeo
        case idFrontURL, idBackURL
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        phoneNumber = try c.decodeIfPresent(String.self, forKey: .phoneNumber) ?? ""
        businessName = try c.decodeIfPresent(String.self, forKey: .businessName) ?? ""
        serviceCategories = try c.decodeIfPresent([String].self, forKey: .serviceCategories) ?? []
        businessType = try c.decodeIfPresent(String.self, forKey: .businessType) ?? ""
        taxNumber = try c.decodeIfPresent(String.self, forKey: .taxNumber)

        if let intVal = try? c.decode(Int.self, forKey: .experienceYears) {
            experienceYears = intVal
        } else if let dblVal = try? c.decode(Double.self, forKey: .experienceYears) {
            experienceYears = Int(dblVal)
        } else {
            experienceYears = 0
        }

        expertiseAreas = try c.decodeIfPresent([String].self, forKey: .expertiseAreas) ?? []
        certificateURLs = try c.decodeIfPresent([String].self, forKey: .certificateURLs) ?? []
        educationLevel = try c.decodeIfPresent(String.self, forKey: .educationLevel) ?? ""
        schoolName = try c.decodeIfPresent(String.self, forKey: .schoolName) ?? ""
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? "Pending"
        createdAt = try c.decodeIfPresent(Timestamp.self, forKey: .createdAt)
        profileImageURL = try c.decodeIfPresent(String.self, forKey: .profileImageURL)
        serviceCities = try c.decodeIfPresent([String].self, forKey: .serviceCities) ?? []
        workingDays = try c.decodeIfPresent([String].self, forKey: .workingDays) ?? []
        workingHoursStart = try c.decodeIfPresent(String.self, forKey: .workingHoursStart)
        workingHoursEnd = try c.decodeIfPresent(String.self, forKey: .workingHoursEnd)
        minPrice = try c.decodeIfPresent(Int.self, forKey: .minPrice)
            ?? (try? c.decode(Double.self, forKey: .minPrice)).map(Int.init)
        maxPrice = try c.decodeIfPresent(Int.self, forKey: .maxPrice)
            ?? (try? c.decode(Double.self, forKey: .maxPrice)).map(Int.init)
        serviceType = try c.decodeIfPresent(String.self, forKey: .serviceType)
        bankName = try c.decodeIfPresent(String.self, forKey: .bankName)
        iban = try c.decodeIfPresent(String.self, forKey: .iban)
        accountHolderName = try c.decodeIfPresent(String.self, forKey: .accountHolderName)
        portfolioImageURLs = try c.decodeIfPresent([String].self, forKey: .portfolioImageURLs) ?? []
        address = try c.decodeIfPresent(String.self, forKey: .address)
        about = try c.decodeIfPresent(String.self, forKey: .about)
        locationGeo = try c.decodeIfPresent(GeoPoint.self, forKey: .locationGeo)
        idFrontURL = try c.decodeIfPresent(String.self, forKey: .idFrontURL)
        idBackURL = try c.decodeIfPresent(String.self, forKey: .idBackURL)
    }

    init(id: String?, displayName: String, email: String, phoneNumber: String, businessName: String, serviceCategories: [String], businessType: String, taxNumber: String?, experienceYears: Int, expertiseAreas: [String], certificateURLs: [String], educationLevel: String, schoolName: String, status: String, createdAt: Timestamp?, profileImageURL: String? = nil, serviceCities: [String] = [], workingDays: [String] = [], workingHoursStart: String? = nil, workingHoursEnd: String? = nil, minPrice: Int? = nil, maxPrice: Int? = nil, serviceType: String? = nil, bankName: String? = nil, iban: String? = nil, accountHolderName: String? = nil, portfolioImageURLs: [String] = [], address: String? = nil, about: String? = nil, locationGeo: GeoPoint? = nil, idFrontURL: String? = nil, idBackURL: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.phoneNumber = phoneNumber
        self.businessName = businessName
        self.serviceCategories = serviceCategories
        self.businessType = businessType
        self.taxNumber = taxNumber
        self.experienceYears = experienceYears
        self.expertiseAreas = expertiseAreas
        self.certificateURLs = certificateURLs
        self.educationLevel = educationLevel
        self.schoolName = schoolName
        self.status = status
        self.createdAt = createdAt
        self.profileImageURL = profileImageURL
        self.serviceCities = serviceCities
        self.workingDays = workingDays
        self.workingHoursStart = workingHoursStart
        self.workingHoursEnd = workingHoursEnd
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.serviceType = serviceType
        self.bankName = bankName
        self.iban = iban
        self.accountHolderName = accountHolderName
        self.portfolioImageURLs = portfolioImageURLs
        self.address = address
        self.about = about
        self.locationGeo = locationGeo
        self.idFrontURL = idFrontURL
        self.idBackURL = idBackURL
    }

    /// Admin tarafından onaylanmış mı
    var isApproved: Bool {
        let s = status.lowercased()
        return s == "approved" || s == "onaylandı"
    }

    /// İlan açabilmek için profil %100 dolu ve başvuru onaylanmış olmalı. 24 alan (adres, hakkında, kimlik ön/arka dahil).
    var profileCompletionPercentage: Int {
        var filled = 0
        let total = 24
        if !displayName.isEmpty { filled += 1 }
        if !email.isEmpty { filled += 1 }
        if !phoneNumber.isEmpty { filled += 1 }
        if !businessName.isEmpty { filled += 1 }
        if !serviceCategories.isEmpty { filled += 1 }
        if !businessType.isEmpty { filled += 1 }
        if experienceYears > 0 { filled += 1 }
        if !expertiseAreas.isEmpty { filled += 1 }
        if !educationLevel.isEmpty { filled += 1 }
        if !schoolName.isEmpty { filled += 1 }
        if !serviceCities.isEmpty { filled += 1 }
        if !workingDays.isEmpty { filled += 1 }
        if let s = workingHoursStart, !s.isEmpty { filled += 1 }
        if let e = workingHoursEnd, !e.isEmpty { filled += 1 }
        if minPrice != nil { filled += 1 }
        if maxPrice != nil { filled += 1 }
        if let t = serviceType, !t.isEmpty { filled += 1 }
        if let b = bankName, !b.isEmpty { filled += 1 }
        if let i = iban, !i.isEmpty { filled += 1 }
        if let a = accountHolderName, !a.isEmpty { filled += 1 }
        if let addr = address, !addr.isEmpty { filled += 1 }
        if let ab = about, !ab.isEmpty { filled += 1 }
        if let f = idFrontURL, !f.isEmpty { filled += 1 }
        if let b = idBackURL, !b.isEmpty { filled += 1 }
        return min(100, (filled * 100) / total)
    }

    /// Profil %100 dolu ve admin onayı almışsa uzman ilan açabilir.
    var canOpenListing: Bool { profileCompletionPercentage >= 100 && isApproved }
}

struct ServiceCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String

    static let allCategories: [ServiceCategory] = [
        .init(name: "Temizlik", icon: "sparkles"),
        .init(name: "Tadilat & Renovasyon", icon: "hammer"),
        .init(name: "Boya & Badana", icon: "paintbrush"),
        .init(name: "Tesisatçı", icon: "wrench.and.screwdriver"),
        .init(name: "Elektrikçi", icon: "bolt"),
        .init(name: "Nakliyat", icon: "box.truck"),
        .init(name: "Bahçe Bakım", icon: "leaf"),
        .init(name: "Klima & Kombi", icon: "thermometer.snowflake"),
        .init(name: "Marangoz", icon: "square.stack.3d.up"),
        .init(name: "Çilingir", icon: "key"),
        .init(name: "Güzellik & Bakım", icon: "scissors"),
        .init(name: "Eğitim & Özel Ders", icon: "book"),
        .init(name: "Fotoğraf & Video", icon: "camera"),
        .init(name: "Yazılım & Teknoloji", icon: "desktopcomputer"),
        .init(name: "Sağlık & Terapi", icon: "heart"),
        .init(name: "Hukuk & Danışmanlık", icon: "building.columns"),
        .init(name: "Oto Bakım & Tamir", icon: "car"),
        .init(name: "Veteriner", icon: "pawprint"),
        .init(name: "Organizasyon", icon: "party.popper"),
        .init(name: "Diğer", icon: "ellipsis.circle")
    ]
}

struct ExpertiseArea: Identifiable, Hashable {
    let id = UUID()
    let name: String

    static func areas(for categories: Set<String>) -> [ExpertiseArea] {
        var result: [ExpertiseArea] = []

        let mapping: [String: [String]] = [
            "Temizlik": ["Ev Temizliği", "Ofis Temizliği", "İnşaat Sonrası Temizlik", "Halı Yıkama", "Koltuk Yıkama", "Cam Temizliği"],
            "Tadilat & Renovasyon": ["Mutfak Tadilat", "Banyo Tadilat", "Zemin Kaplama", "Alçıpan", "Seramik Döşeme", "Duvar Yıkım & Yapım"],
            "Boya & Badana": ["İç Cephe Boya", "Dış Cephe Boya", "Dekoratif Boya", "Lake Boya", "Duvar Kağıdı"],
            "Tesisatçı": ["Su Tesisatı", "Kalorifer Tesisatı", "Doğalgaz Tesisatı", "Kanalizasyon", "Petek Temizliği"],
            "Elektrikçi": ["Ev Elektrik", "Endüstriyel Elektrik", "Aydınlatma", "Güvenlik Sistemleri", "Akıllı Ev"],
            "Nakliyat": ["Evden Eve Nakliyat", "Ofis Taşıma", "Şehirler Arası Nakliyat", "Parça Eşya Taşıma", "Depolama"],
            "Bahçe Bakım": ["Çim Biçme", "Budama", "Peyzaj Düzenleme", "Sulama Sistemi", "Zararlı İlaçlama"],
            "Klima & Kombi": ["Klima Montaj", "Klima Bakım", "Kombi Bakım", "Kombi Tamiri", "Merkezi Isıtma"],
            "Marangoz": ["Mobilya Tamiri", "Özel Mobilya", "Kapı & Pencere", "Parke Döşeme", "Mutfak Dolabı"],
            "Çilingir": ["Kapı Açma", "Kilit Değişimi", "Çelik Kapı", "Oto Çilingir", "Kasa Açma"],
            "Güzellik & Bakım": ["Kuaför", "Cilt Bakımı", "Manikür & Pedikür", "Masaj", "Epilasyon"],
            "Eğitim & Özel Ders": ["Matematik", "Fen Bilimleri", "Yabancı Dil", "Müzik", "Sınav Hazırlık"],
            "Fotoğraf & Video": ["Düğün Fotoğraf", "Ürün Çekimi", "Drone Çekim", "Video Düzenleme", "Etkinlik Çekim"],
            "Yazılım & Teknoloji": ["Web Geliştirme", "Mobil Uygulama", "Bilgisayar Tamiri", "Ağ Kurulumu", "Veri Kurtarma"],
            "Sağlık & Terapi": ["Fizyoterapi", "Diyetisyen", "Psikoloji", "Evde Bakım", "Yaşlı Bakım"],
            "Hukuk & Danışmanlık": ["İş Hukuku", "Aile Hukuku", "Gayrimenkul", "Vergi Danışmanlık", "Şirket Kuruluş"],
            "Oto Bakım & Tamir": ["Motor Bakım", "Boya & Kaporta", "Lastik Değişim", "Cam Filmi", "Detaylı Temizlik"],
            "Veteriner": ["Ev Hayvanı Bakım", "Aşılama", "Tıraş & Bakım", "Acil Müdahale"],
            "Organizasyon": ["Düğün Organizasyon", "Doğum Günü", "Kurumsal Etkinlik", "Catering", "Ses & Işık"],
            "Diğer": ["Kurye", "Tercüme", "Özel Şoför", "Ev Tadilat Danışmanlık"]
        ]

        for cat in categories {
            if let areas = mapping[cat] {
                result.append(contentsOf: areas.map { ExpertiseArea(name: $0) })
            }
        }

        if result.isEmpty {
            result = mapping.values.flatMap { $0 }.map { ExpertiseArea(name: $0) }
        }

        return result
    }
}

enum EducationLevel: String, CaseIterable {
    case primary = "İlköğretim"
    case highSchool = "Lise"
    case associate = "Ön Lisans"
    case bachelor = "Lisans"
    case master = "Yüksek Lisans"
    case doctorate = "Doktora"
}
