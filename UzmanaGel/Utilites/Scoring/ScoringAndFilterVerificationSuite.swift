//
//  ScoringAndFilterVerificationSuite.swift
//  UzmanaGel
//
//  Created by Antigravity on 21.07.2026.
//

import Foundation
import CoreLocation
import FirebaseFirestore

final class ScoringAndFilterVerificationSuite {
    
    static func runAllTests() {
        var logOutput = ""
        func log(_ text: String) {
            print(text)
            logOutput += text + "\n"
        }

        log("\n=======================================================")
        log("🧪 [TEST SUITE] Scoring Engine & Filter Verification Başlatıldı...")
        log("=======================================================\n")
        
        var passedCount = 0
        var failedCount = 0
        
        func assert(_ condition: Bool, _ testName: String, _ details: String = "") {
            if condition {
                passedCount += 1
                log("✅ [PASS] \(testName) \(details.isEmpty ? "" : "- \(details)")")
            } else {
                failedCount += 1
                log("❌ [FAIL] \(testName) \(details.isEmpty ? "" : "- \(details)")")
            }
        }
        
        // --- 1. HAVERSINE MESAFE VE NORMALİZASYON TESTİ ---
        let testGeo0Km = GeoPoint(latitude: 41.0082, longitude: 28.9784) // Sultanahmet
        let testGeo5Km = GeoPoint(latitude: 41.0531, longitude: 28.9868) // Taksim ~5 km
        let testGeo35Km = GeoPoint(latitude: 41.2500, longitude: 29.2000) // 35+ km
        let userCoord = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        
        var serviceNear = Service(serviceId: "1", title: "Ev Temizliği", category: "Temizlik", providerId: "p1", price: 500, rating: 4.8, locationGeo: testGeo0Km, completedJobsCount: 50)
        var serviceMid = Service(serviceId: "2", title: "Ev Temizliği", category: "Temizlik", providerId: "p2", price: 500, rating: 4.8, locationGeo: testGeo5Km, completedJobsCount: 50)
        var serviceFar = Service(serviceId: "3", title: "Ev Temizliği", category: "Temizlik", providerId: "p3", price: 500, rating: 4.8, locationGeo: testGeo35Km, completedJobsCount: 50)
        
        let scoreNear = ServiceScoringEngine.shared.calculateScore(for: serviceNear, userCoordinate: userCoord)
        let scoreMid = ServiceScoringEngine.shared.calculateScore(for: serviceMid, userCoordinate: userCoord)
        let scoreFar = ServiceScoringEngine.shared.calculateScore(for: serviceFar, userCoordinate: userCoord)
        
        assert(scoreNear.locationScore == 1.0, "Haversine Çok Yakın Mesafe (0 km -> 1.0)", "Score: \(scoreNear.locationScore)")
        assert(scoreMid.locationScore > 0.7 && scoreMid.locationScore < 0.9, "Haversine 5 km Normalizasyon (~0.83)", "Score: \(String(format: "%.2f", scoreMid.locationScore))")
        assert(scoreFar.locationScore == 0.0, "Haversine Yarıçap Dışı (35 km -> 0.0)", "Score: \(scoreFar.locationScore)")
        
        // --- 2. KATEGORİ HİYERARŞİSİ VE FUZZY MATCHING TESTİ ---
        var serviceCatSub = Service(serviceId: "4", title: "Detaylı Temizlik", category: "Ev Temizliği", providerId: "p4", price: 1000, rating: 4.5, completedJobsCount: 20)
        var serviceCatRel = Service(serviceId: "5", title: "Yerinde Yıkama", category: "Halı Yıkama", providerId: "p5", price: 800, rating: 4.5, completedJobsCount: 20)
        var serviceCatFuzzy = Service(serviceId: "6", title: "Boya Badana Tadilat işleri", category: "Temizlik", providerId: "p6", price: 2000, rating: 4.5, completedJobsCount: 20)
        
        let scoreCatSub = ServiceScoringEngine.shared.calculateScore(for: serviceCatSub, targetCategory: "Temizlik")
        let scoreCatRel = ServiceScoringEngine.shared.calculateScore(for: serviceCatRel, targetCategory: "Koltuk Yıkama")
        let scoreCatFuzzy = ServiceScoringEngine.shared.calculateScore(for: serviceCatFuzzy, targetQuery: "badana")
        
        assert(scoreCatSub.categoryScore == 0.8, "Alt Kategori Eşleşmesi (Temizlik -> Ev Temizliği: 0.8)", "Score: \(scoreCatSub.categoryScore)")
        assert(scoreCatRel.categoryScore == 0.5, "Kardeş/İlişkili Kategori (Koltuk -> Halı Yıkama: 0.5)", "Score: \(scoreCatRel.categoryScore)")
        assert(scoreCatFuzzy.categoryScore == 1.0, "Fuzzy/Query Eşleşmesi ('badana' in title: 1.0)", "Score: \(scoreCatFuzzy.categoryScore)")
        
        // --- 3. BAYESIAN RATING NORMALİZASYONU TESTİ ---
        var serviceHighRatingFewJobs = Service(serviceId: "7", title: "Taşıma", category: "Nakliyat", providerId: "p7", price: 1500, rating: 5.0, completedJobsCount: 1)
        var serviceHighRatingManyJobs = Service(serviceId: "8", title: "Taşıma", category: "Nakliyat", providerId: "p8", price: 1500, rating: 4.9, completedJobsCount: 200)
        
        let scoreFew = ServiceScoringEngine.shared.calculateScore(for: serviceHighRatingFewJobs)
        let scoreMany = ServiceScoringEngine.shared.calculateScore(for: serviceHighRatingManyJobs)
        
        assert(scoreMany.ratingScore > scoreFew.ratingScore, "Bayesian Dengeleme (200 İşli 4.9 > 1 İşli 5.0)", "Many: \(String(format: "%.3f", scoreMany.ratingScore)), Few: \(String(format: "%.3f", scoreFew.ratingScore))")
        
        // --- 4. MÜSAİTLİK VE DENEYİM SKORU TESTİ ---
        var serviceAvail = Service(serviceId: "9", title: "Usta", category: "Tadilat", providerId: "p9", price: 1000, experienceYears: 12, rating: 4.7, isAvailable: true, isCertified: true, completedJobsCount: 120)
        var serviceUnavail = Service(serviceId: "10", title: "Usta", category: "Tadilat", providerId: "p10", price: 1000, experienceYears: 2, rating: 4.7, isAvailable: false, isCertified: false, completedJobsCount: 10)
        
        let scoreAvail = ServiceScoringEngine.shared.calculateScore(for: serviceAvail)
        let scoreUnavail = ServiceScoringEngine.shared.calculateScore(for: serviceUnavail)
        
        assert(scoreAvail.availabilityScore >= 1.0, "Müsait + Aynı Gün Bonusu (Score >= 1.0)", "Score: \(scoreAvail.availabilityScore)")
        assert(scoreAvail.experienceScore >= 1.0, "Deneyim (12 Yıl + 120 İş + Sertifika -> 1.0)", "Score: \(scoreAvail.experienceScore)")
        assert(scoreUnavail.availabilityScore == 0.20, "Müsait Olmayan Servis Temel Skoru (0.20)", "Score: \(scoreUnavail.availabilityScore)")
        assert(scoreAvail.finalScore > scoreUnavail.finalScore, "Ağırlıklı Final Skor Sıralaması Doğrulaması", "Avail: \(String(format: "%.2f", scoreAvail.finalScore)) > Unavail: \(String(format: "%.2f", scoreUnavail.finalScore))")
        
        // --- 5. FİLTRELEME SİSTEMİ (`ServiceFilter`) & PIPELINE TESTİ ---
        var filter = ServiceFilter()
        assert(filter.activeFilterCount == 0 && !filter.isActive, "Varsayılan Filtre Durumu Temiz (0 aktif)")
        
        filter.minPrice = 500
        filter.maxPrice = 1500
        filter.minRating = 4.5
        filter.isCertifiedOnly = true
        filter.selectedServiceType = "Saatlik"
        filter.minCompletedJobs = 20
        assert(filter.activeFilterCount == 5 && filter.isActive, "Aktif Filtre Sayacı Doğrulaması (5 filtre aktif)", "Count: \(filter.activeFilterCount)")
        
        filter.reset()
        assert(filter.activeFilterCount == 0 && !filter.isActive, "Filtre Sıfırla (Reset) Fonksiyonu Doğrulaması")
        
        log("\n=======================================================")
        log("🎉 [TEST SONUÇLARI]: \(passedCount) Başarılı, \(failedCount) Başarısız")
        log("=======================================================\n")
        
        try? logOutput.write(toFile: "/Users/baran/UzmanaGel/build_tmp/test_report.txt", atomically: true, encoding: .utf8)
        try? logOutput.write(toFile: "/tmp/uzmanagel_test_report.txt", atomically: true, encoding: .utf8)
    }
}
