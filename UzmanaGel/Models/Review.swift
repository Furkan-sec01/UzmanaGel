//
//  Review.swift
//  UzmanaGel
//
//  Created by Antigravity on 22.07.2026.
//

import Foundation
import FirebaseFirestore

/// Hizmet kategorilerine göre detaylı değerlendirme başlıkları
enum ReviewCategory: String, CaseIterable, Identifiable, Codable {
    case professionalism = "Profesyonellik"
    case cleanliness = "Temizlik"
    case communication = "İletişim"
    case punctuality = "Zamanlama"
    case valueForMoney = "Fiyat/Performans"
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.localized
    }
}

/// Kullanıcı şikayet/raporlama kategorileri
enum ReviewReportCategory: String, CaseIterable, Identifiable {
    case inappropriate = "Uygunsuz İçerik"
    case spam = "Spam / Reklam"
    case fake = "Sahte Yorum"
    case personalAttack = "Kişisel Saldırı / Hakaret"
    case other = "Diğer"
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.localized
    }
}

/// Firebase reviews koleksiyonundaki her bir yorum dökümanını temsil eder
struct Review: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    
    var reviewId: String
    var bookingId: String
    var reservationId: String?
    var serviceId: String?
    var serviceTitle: String?
    var customerId: String
    var providerId: String
    var rating: Double // 1.0 - 5.0
    var comment: String
    var categoryRatings: [String: Double] // e.g. ["Profesyonellik": 5.0, ...]
    var photos: [String]
    var providerResponse: String?
    var providerResponseDate: Timestamp?
    var isReported: Bool
    var reportReason: String?
    var createdAt: Timestamp?
    var updatedAt: Timestamp?
    
    // Faydalı / Thumbs Up sayacı ve beğenen kullanıcı ID'leri
    var helpfulCount: Int
    var helpfulUsers: [String]
    
    // Müşteri gösterim bilgileri (Denormalized ya da servis tarafından doldurulan alanlar)
    var customerName: String
    var customerAvatarURL: String?
    var isVerifiedBooking: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case reviewId
        case bookingId
        case customerId
        case providerId
        case rating
        case comment
        case categoryRatings
        case photos
        case providerResponse
        case providerResponseDate
        case isReported
        case reportReason
        case createdAt
        case updatedAt
        case helpfulCount
        case helpfulUsers
        case customerName
        case customerAvatarURL
        case isVerifiedBooking
    }
    
    private enum AdditionalKeys: String, CodingKey {
        case reservationId
        case serviceId
        case serviceTitle
        case providerResponseAt
    }
    
    init(
        id: String? = nil,
        reviewId: String = UUID().uuidString,
        bookingId: String = "",
        reservationId: String? = nil,
        serviceId: String? = nil,
        serviceTitle: String? = nil,
        customerId: String = "",
        providerId: String = "",
        rating: Double = 5.0,
        comment: String = "",
        categoryRatings: [String: Double] = [:],
        photos: [String] = [],
        providerResponse: String? = nil,
        providerResponseDate: Timestamp? = nil,
        isReported: Bool = false,
        reportReason: String? = nil,
        createdAt: Timestamp? = Timestamp(date: Date()),
        updatedAt: Timestamp? = Timestamp(date: Date()),
        helpfulCount: Int = 0,
        helpfulUsers: [String] = [],
        customerName: String = "Müşteri",
        customerAvatarURL: String? = nil,
        isVerifiedBooking: Bool = true
    ) {
        self.id = id
        self.reviewId = reviewId
        self.bookingId = bookingId
        self.reservationId = reservationId ?? bookingId
        self.serviceId = serviceId
        self.serviceTitle = serviceTitle
        self.customerId = customerId
        self.providerId = providerId
        self.rating = rating
        self.comment = comment
        self.categoryRatings = categoryRatings
        self.photos = photos
        self.providerResponse = providerResponse
        self.providerResponseDate = providerResponseDate
        self.isReported = isReported
        self.reportReason = reportReason
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.helpfulCount = helpfulCount
        self.helpfulUsers = helpfulUsers
        self.customerName = customerName
        self.customerAvatarURL = customerAvatarURL
        self.isVerifiedBooking = isVerifiedBooking
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let addC = try? decoder.container(keyedBy: AdditionalKeys.self)
        
        let decodedID = try c.decodeIfPresent(String.self, forKey: .id)
        id = decodedID
        reviewId = try c.decodeIfPresent(String.self, forKey: .reviewId) ?? decodedID ?? UUID().uuidString
        
        let bId = (try? c.decodeIfPresent(String.self, forKey: .bookingId)) ?? (try? addC?.decodeIfPresent(String.self, forKey: .reservationId)) ?? ""
        bookingId = bId ?? ""
        reservationId = (try? addC?.decodeIfPresent(String.self, forKey: .reservationId)) ?? bookingId
        serviceId = try? addC?.decodeIfPresent(String.self, forKey: .serviceId)
        serviceTitle = try? addC?.decodeIfPresent(String.self, forKey: .serviceTitle)
        
        customerId = (try? c.decodeIfPresent(String.self, forKey: .customerId)) ?? ""
        providerId = (try? c.decodeIfPresent(String.self, forKey: .providerId)) ?? ""
        
        if let dVal = try? c.decode(Double.self, forKey: .rating) {
            rating = dVal
        } else if let iVal = try? c.decode(Int.self, forKey: .rating) {
            rating = Double(iVal)
        } else {
            rating = 5.0
        }
        
        comment = (try? c.decodeIfPresent(String.self, forKey: .comment)) ?? ""
        
        if let dDict = try? c.decode([String: Double].self, forKey: .categoryRatings) {
            categoryRatings = dDict
        } else if let iDict = try? c.decode([String: Int].self, forKey: .categoryRatings) {
            var converted: [String: Double] = [:]
            for (k, v) in iDict { converted[k] = Double(v) }
            categoryRatings = converted
        } else {
            categoryRatings = [:]
        }
        
        photos = (try? c.decodeIfPresent([String].self, forKey: .photos)) ?? []
        providerResponse = try? c.decodeIfPresent(String.self, forKey: .providerResponse)
        
        let pDate = (try? c.decodeIfPresent(Timestamp.self, forKey: .providerResponseDate)) ?? (try? addC?.decodeIfPresent(Timestamp.self, forKey: .providerResponseAt))
        providerResponseDate = pDate ?? nil
        
        isReported = (try? c.decodeIfPresent(Bool.self, forKey: .isReported)) ?? false
        reportReason = try? c.decodeIfPresent(String.self, forKey: .reportReason)
        createdAt = try? c.decodeIfPresent(Timestamp.self, forKey: .createdAt)
        updatedAt = try? c.decodeIfPresent(Timestamp.self, forKey: .updatedAt)
        
        if let hInt = try? c.decode(Int.self, forKey: .helpfulCount) {
            helpfulCount = hInt
        } else if let hDouble = try? c.decode(Double.self, forKey: .helpfulCount) {
            helpfulCount = Int(hDouble)
        } else {
            helpfulCount = 0
        }
        
        helpfulUsers = (try? c.decodeIfPresent([String].self, forKey: .helpfulUsers)) ?? []
        customerName = (try? c.decodeIfPresent(String.self, forKey: .customerName)) ?? "Müşteri"
        customerAvatarURL = try? c.decodeIfPresent(String.self, forKey: .customerAvatarURL)
        isVerifiedBooking = (try? c.decodeIfPresent(Bool.self, forKey: .isVerifiedBooking)) ?? true
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encode(reviewId, forKey: .reviewId)
        try c.encode(bookingId, forKey: .bookingId)
        try c.encode(customerId, forKey: .customerId)
        try c.encode(providerId, forKey: .providerId)
        try c.encode(rating, forKey: .rating)
        try c.encode(comment, forKey: .comment)
        try c.encode(categoryRatings, forKey: .categoryRatings)
        try c.encode(photos, forKey: .photos)
        try c.encodeIfPresent(providerResponse, forKey: .providerResponse)
        try c.encodeIfPresent(providerResponseDate, forKey: .providerResponseDate)
        try c.encode(isReported, forKey: .isReported)
        try c.encodeIfPresent(reportReason, forKey: .reportReason)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try c.encode(helpfulCount, forKey: .helpfulCount)
        try c.encode(helpfulUsers, forKey: .helpfulUsers)
        try c.encode(customerName, forKey: .customerName)
        try c.encodeIfPresent(customerAvatarURL, forKey: .customerAvatarURL)
        try c.encode(isVerifiedBooking, forKey: .isVerifiedBooking)
        
        var addC = encoder.container(keyedBy: AdditionalKeys.self)
        let finalResId = reservationId ?? (bookingId.isEmpty ? nil : bookingId)
        try addC.encodeIfPresent(finalResId, forKey: .reservationId)
        try addC.encodeIfPresent(serviceId, forKey: .serviceId)
        try addC.encodeIfPresent(serviceTitle, forKey: .serviceTitle)
        try addC.encodeIfPresent(providerResponseDate, forKey: .providerResponseAt)
    }
    
    init(fromDictionary dict: [String: Any], id: String) {
        self.id = id
        self.reviewId = dict["reviewId"] as? String ?? id
        let bId = dict["bookingId"] as? String ?? dict["reservationId"] as? String ?? ""
        self.bookingId = bId
        self.reservationId = dict["reservationId"] as? String ?? (bId.isEmpty ? nil : bId)
        self.serviceId = dict["serviceId"] as? String
        self.serviceTitle = dict["serviceTitle"] as? String
        self.customerId = dict["customerId"] as? String ?? ""
        self.providerId = dict["providerId"] as? String ?? ""
        
        if let dVal = dict["rating"] as? Double {
            self.rating = dVal
        } else if let iVal = dict["rating"] as? Int {
            self.rating = Double(iVal)
        } else if let nVal = dict["rating"] as? NSNumber {
            self.rating = nVal.doubleValue
        } else {
            self.rating = 5.0
        }
        
        self.comment = dict["comment"] as? String ?? ""
        
        if let catDict = dict["categoryRatings"] as? [String: Double] {
            self.categoryRatings = catDict
        } else if let catInt = dict["categoryRatings"] as? [String: Int] {
            var converted: [String: Double] = [:]
            for (k, v) in catInt { converted[k] = Double(v) }
            self.categoryRatings = converted
        } else {
            self.categoryRatings = [:]
        }
        
        self.photos = dict["photos"] as? [String] ?? []
        self.providerResponse = dict["providerResponse"] as? String
        self.providerResponseDate = dict["providerResponseDate"] as? Timestamp ?? dict["providerResponseAt"] as? Timestamp
        self.isReported = dict["isReported"] as? Bool ?? false
        self.reportReason = dict["reportReason"] as? String
        self.createdAt = dict["createdAt"] as? Timestamp
        self.updatedAt = dict["updatedAt"] as? Timestamp
        self.helpfulCount = dict["helpfulCount"] as? Int ?? 0
        self.helpfulUsers = dict["helpfulUsers"] as? [String] ?? []
        self.customerName = dict["customerName"] as? String ?? "Müşteri"
        self.customerAvatarURL = dict["customerAvatarURL"] as? String
        self.isVerifiedBooking = dict["isVerifiedBooking"] as? Bool ?? true
    }
    
    /// Yorum tarihi (formatlı)
    var formattedDateString: String {
        guard let date = createdAt?.dateValue() else { return "Az önce" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Anonim isim seçeneği (Örn: Baran A. -> B**** A.)
    func getAnonymizedName(isAnonymized: Bool) -> String {
        guard isAnonymized else { return customerName }
        let parts = customerName.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard let first = parts.first, !first.isEmpty else { return "Müşteri" }
        let firstLetter = String(first.prefix(1))
        if parts.count > 1, let last = parts.last {
            let lastLetter = String(last.prefix(1))
            return "\(firstLetter)**** \(lastLetter)."
        }
        return "\(firstLetter)****"
    }
}

/// Sağlayıcıya ait yorumların özet istatistiklerini tutan model
struct ProviderReviewSummary {
    let averageScore: Double
    let totalCount: Int
    let starDistribution: [Int: Int] // 5 -> 12, 4 -> 3, vb.
    let categoryAverages: [String: Double]
    
    static let empty = ProviderReviewSummary(
        averageScore: 0.0,
        totalCount: 0,
        starDistribution: [5: 0, 4: 0, 3: 0, 2: 0, 1: 0],
        categoryAverages: [:]
    )
    
    init(reviews: [Review]) {
        let count = reviews.count
        guard count > 0 else {
            self = .empty
            return
        }
        
        let sum = reviews.reduce(0.0) { $0 + $1.rating }
        self.averageScore = sum / Double(count)
        self.totalCount = count
        
        var dist: [Int: Int] = [5: 0, 4: 0, 3: 0, 2: 0, 1: 0]
        for r in reviews {
            let star = max(1, min(5, Int(r.rating.rounded())))
            dist[star, default: 0] += 1
        }
        self.starDistribution = dist
        
        var catSums: [String: Double] = [:]
        var catCounts: [String: Int] = [:]
        
        for r in reviews {
            for (cat, val) in r.categoryRatings {
                catSums[cat, default: 0.0] += val
                catCounts[cat, default: 0] += 1
            }
        }
        
        var catAvgs: [String: Double] = [:]
        for cat in ReviewCategory.allCases {
            if let c = catCounts[cat.rawValue], c > 0, let s = catSums[cat.rawValue] {
                catAvgs[cat.rawValue] = s / Double(c)
            } else {
                catAvgs[cat.rawValue] = self.averageScore
            }
        }
        self.categoryAverages = catAvgs
    }
    
    private init(averageScore: Double, totalCount: Int, starDistribution: [Int: Int], categoryAverages: [String: Double]) {
        self.averageScore = averageScore
        self.totalCount = totalCount
        self.starDistribution = starDistribution
        self.categoryAverages = categoryAverages
    }
}
