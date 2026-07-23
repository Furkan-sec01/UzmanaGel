//
//  ServiceScoringEngine.swift
//  UzmanaGel
//
//  Created by Antigravity on 21.07.2026.
//

import Foundation
import CoreLocation
import FirebaseFirestore

/// Detaylı Skorlama Çıktısı Modeli
struct ServiceScoreBreakdown: Equatable {
    let finalScore: Double
    let locationScore: Double
    let categoryScore: Double
    let ratingScore: Double
    let availabilityScore: Double
    let experienceScore: Double
    let distanceKm: Double?
}

/// Dökümantasyonda belirtilen 5 Ana Katmanlı Skorlama Sistemi (Scoring Engine)
/// Weights:
/// - Konum Uyumluluğu: 0.30
/// - Kategori Eşleşmesi: 0.25
/// - Rating Skoru: 0.20
/// - Müsaitlik Skoru: 0.15
/// - Deneyim Skoru: 0.10
final class ServiceScoringEngine {
    
    static let shared = ServiceScoringEngine()
    
    private init() {}
    
    // MARK: - Kategori Hiyerarşisi Ağacı (Category Hierarchy Tree & Related Map)
    
    private let categoryHierarchy: [String: [String]] = [
        "Temizlik": ["Ev Temizliği", "Ofis Temizliği", "Halı Yıkama", "Koltuk Yıkama", "İnşaat Sonrası Temizlik"],
        "Tadilat": ["Boya Badana", "Tesisat", "Elektrik", "Marangoz", "Seramik & Fayans", "Parke"],
        "Nakliyat": ["Evden Eve Nakliyat", "Ofis Taşımacılığı", "Parça Eşya Taşıma", "Şehirlerarası Nakliyat"],
        "Özel Ders": ["Matematik Dersi", "İngilizce Dersi", "Müzik Dersi", "Yazılım & Kodlama", "YKS & LGS Hazırlık"],
        "Sağlık & Bakım": ["Evde Bakım", "Fizyoterapi", "Diyetisyen", "Kişisel Antrenör", "Psikolojik Danışmanlık"],
        "Organizasyon": ["Düğün & Nişan", "Fotoğraf & Video", "Catering", "DJ & Müzik Ekibi"]
    ]
    
    /// Ana Skorlama Fonksiyonu
    /// - Parameters:
    ///   - service: Değerlendirilecek hizmet
    ///   - userCoordinate: Kullanıcının anlık GPS/Seçili koordinatı (Opsiyonel)
    ///   - targetCategory: Hedef arama/seçim kategorisi (Opsiyonel)
    ///   - targetQuery: Kullanıcı arama kelimesi (Opsiyonel)
    /// - Returns: Detaylı `ServiceScoreBreakdown` (0.0 - 1.0 arası değerler ve final skoru)
    func calculateScore(
        for service: Service,
        userCoordinate: CLLocationCoordinate2D? = nil,
        targetCategory: String? = nil,
        targetQuery: String? = nil
    ) -> ServiceScoreBreakdown {
        
        // 1. Konum Uyumluluğu (Weight: 0.30)
        let (locationScore, distanceKm) = calculateLocationScore(service: service, userCoordinate: userCoordinate)
        
        // 2. Kategori Eşleşmesi (Weight: 0.25)
        let categoryScore = calculateCategoryScore(service: service, targetCategory: targetCategory, query: targetQuery)
        
        // 3. Rating Skoru (Weight: 0.20)
        let ratingScore = calculateRatingScore(service: service)
        
        // 4. Müsaitlik Skoru (Weight: 0.15)
        let availabilityScore = calculateAvailabilityScore(service: service)
        
        // 5. Deneyim Skoru (Weight: 0.10)
        let experienceScore = calculateExperienceScore(service: service)
        
        // Final Weighted Sum
        let finalScore = (locationScore * 0.30) +
                         (categoryScore * 0.25) +
                         (ratingScore * 0.20) +
                         (availabilityScore * 0.15) +
                         (experienceScore * 0.10)
        
        return ServiceScoreBreakdown(
            finalScore: min(max(finalScore, 0.0), 1.0),
            locationScore: locationScore,
            categoryScore: categoryScore,
            ratingScore: ratingScore,
            availabilityScore: availabilityScore,
            experienceScore: experienceScore,
            distanceKm: distanceKm
        )
    }
    
    // MARK: - 1. Konum Uyumluluğu (Weight: 0.30)
    
    private func calculateLocationScore(service: Service, userCoordinate: CLLocationCoordinate2D?) -> (Double, Double?) {
        guard let userCoord = userCoordinate, let serviceGeo = service.locationGeo else {
            // Konum verisi yoksa nötr skor (0.50)
            return (0.50, nil)
        }
        
        // Haversine Distance hesaplama (metre cinsinden)
        let userLocation = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let serviceLocation = CLLocation(latitude: serviceGeo.latitude, longitude: serviceGeo.longitude)
        let distanceMeters = userLocation.distance(from: serviceLocation)
        let distanceKm = distanceMeters / 1000.0
        
        // Provider Service Radius kontrolü & Dinamik scaling (varsayılan max servis yarıçapı: 30 km)
        let maxRadiusKm: Double = 30.0
        
        if distanceKm <= 0.5 {
            return (1.0, distanceKm) // Çok yakın (500 metre altı) tam puan
        } else if distanceKm >= maxRadiusKm {
            return (0.0, distanceKm) // Servis yarıçapı dışında
        } else {
            // Distance normalization (0 - 1 arası lineer üstel azalım)
            let normalized = max(0.0, 1.0 - (distanceKm / maxRadiusKm))
            return (normalized, distanceKm)
        }
    }
    
    // MARK: - 2. Kategori Eşleşmesi (Weight: 0.25)
    
    private func calculateCategoryScore(service: Service, targetCategory: String?, query: String?) -> Double {
        let sCat = service.category.lowercased(with: Locale(identifier: "tr_TR"))
        let sTitle = service.title.lowercased(with: Locale(identifier: "tr_TR"))
        
        var maxScore: Double = 0.5 // Varsayılan genel skor
        
        if let target = targetCategory, !target.isEmpty {
            let tCat = target.lowercased(with: Locale(identifier: "tr_TR"))
            
            // Exact match: 1.0
            if sCat == tCat {
                maxScore = max(maxScore, 1.0)
            }
            // Sub-category match: 0.8 (Kategori hiyerarşi ağacında alt/üst ilişki)
            else if isSubCategoryMatch(parentOrChild: tCat, candidate: sCat) {
                maxScore = max(maxScore, 0.8)
            }
            // Related category: 0.5
            else if isRelatedCategoryMatch(cat1: tCat, cat2: sCat) {
                maxScore = max(maxScore, 0.5)
            } else {
                // Fuzzy matching (Benzerlik)
                let fuzzy = fuzzyMatchScore(str1: tCat, str2: sCat)
                if fuzzy > 0.6 {
                    maxScore = max(maxScore, fuzzy * 0.8)
                } else {
                    maxScore = 0.2 // Kategori uymuyorsa düşük skor
                }
            }
        }
        
        // Arama kelimesi (Query) varsa fuzzy ve başlık/açıklama eşleşmesi ekle
        if let q = query, !q.isEmpty {
            let qLower = q.lowercased(with: Locale(identifier: "tr_TR"))
            if sTitle.contains(qLower) || sCat.contains(qLower) {
                maxScore = max(maxScore, 1.0)
            } else {
                let fuzzyTitle = fuzzyMatchScore(str1: qLower, str2: sTitle)
                maxScore = max(maxScore, fuzzyTitle)
            }
        }
        
        return min(maxScore, 1.0)
    }
    
    private func isSubCategoryMatch(parentOrChild: String, candidate: String) -> Bool {
        for (parent, children) in categoryHierarchy {
            let pLower = parent.lowercased(with: Locale(identifier: "tr_TR"))
            let cLowers = children.map { $0.lowercased(with: Locale(identifier: "tr_TR")) }
            
            if (parentOrChild == pLower && cLowers.contains(candidate)) ||
               (candidate == pLower && cLowers.contains(parentOrChild)) {
                return true
            }
        }
        return false
    }
    
    private func isRelatedCategoryMatch(cat1: String, cat2: String) -> Bool {
        for (_, children) in categoryHierarchy {
            let cLowers = children.map { $0.lowercased(with: Locale(identifier: "tr_TR")) }
            if cLowers.contains(cat1) && cLowers.contains(cat2) && cat1 != cat2 {
                return true
            }
        }
        return false
    }
    
    /// Fuzzy String Matching (Levenshtein Benzerlik Oranı: 0.0 - 1.0)
    private func fuzzyMatchScore(str1: String, str2: String) -> Double {
        if str1 == str2 { return 1.0 }
        if str1.isEmpty || str2.isEmpty { return 0.0 }
        if str2.contains(str1) || str1.contains(str2) { return 0.85 }
        
        let s1 = Array(str1)
        let s2 = Array(str2)
        let count1 = s1.count
        let count2 = s2.count
        
        var matrix = Array(repeating: Array(repeating: 0, count: count2 + 1), count: count1 + 1)
        
        for i in 0...count1 { matrix[i][0] = i }
        for j in 0...count2 { matrix[0][j] = j }
        
        for i in 1...count1 {
            for j in 1...count2 {
                let cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // Deletion
                    matrix[i][j - 1] + 1,      // Insertion
                    matrix[i - 1][j - 1] + cost // Substitution
                )
            }
        }
        
        let distance = Double(matrix[count1][count2])
        let maxLen = Double(max(count1, count2))
        return max(0.0, 1.0 - (distance / maxLen))
    }
    
    // MARK: - 3. Rating Skoru (Weight: 0.20)
    
    private func calculateRatingScore(service: Service) -> Double {
        let rating = service.reviewCount > 0 ? service.rating : 0.0
        let jobs = Double(service.completedJobsCount)
        
        // Review count tahmini & Bayesian average (az yorumlu sağlayıcılar için dengeleme)
        // Formula: bayesianRating = ((C * m) + (v * R)) / (C + v)
        // C: platform ortalama yorum/iş sayısı (örn: 10.0), m: platform ortalama puanı (örn: 4.3)
        let C: Double = 10.0
        let m: Double = 4.3
        let v: Double = max(jobs * 0.4, 1.0) // Tahmini yorum sayısı
        
        let bayesianRating = ((C * m) + (v * rating)) / (C + v)
        
        // Average rating normalization (0-5 ölçeği 0-1 aralığına normalize edilir)
        let normalized = min(max(bayesianRating / 5.0, 0.0), 1.0)
        
        // Review count weighting bonus (çok yorumlu/iş bitirmiş sağlayıcılara ek +0.05 güven bonusu)
        let countBonus = min(0.05, (jobs / 200.0) * 0.05)
        
        return min(normalized + countBonus, 1.0)
    }
    
    // MARK: - 4. Müsaitlik Skoru (Weight: 0.15)
    
    private func calculateAvailabilityScore(service: Service) -> Double {
        var score: Double = 0.0
        
        // Real-time availability check
        if service.isAvailable {
            score += 0.70
            // Same-day availability bonus
            score += 0.30
        } else {
            // Müsait değilse ama aktif bir servis ise minimum temel skor
            score += 0.20
        }
        
        // Weekend / weekday weighting (Hafta sonu vs hafta içi analizi)
        let calendar = Calendar.current
        let isWeekend = calendar.isDateInWeekend(Date())
        if isWeekend && service.isAvailable {
            score += 0.05 // Hafta sonu aktif olanlara ek bonus
        }
        
        return min(max(score, 0.0), 1.0)
    }
    
    // MARK: - 5. Deneyim Skoru (Weight: 0.10)
    
    private func calculateExperienceScore(service: Service) -> Double {
        let years = Double(service.experienceYears)
        let jobs = Double(service.completedJobsCount)
        let isCertified = service.isCertified
        
        // Experience years normalization (10+ yıl = 1.0)
        let yearsNorm = min(1.0, years / 10.0)
        
        // Completed jobs normalization (100+ iş = 1.0)
        let jobsNorm = min(1.0, jobs / 100.0)
        
        // Certification / Completion rate bonus
        let certBonus: Double = isCertified ? 0.20 : 0.0
        
        // Ağırlıklı kombinasyon: %40 Yıl, %40 İş Sayısı, %20 Sertifika/Güvenilirlik
        let combined = (yearsNorm * 0.40) + (jobsNorm * 0.40) + certBonus
        
        return min(max(combined, 0.0), 1.0)
    }
}
