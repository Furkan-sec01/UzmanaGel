import Foundation
import Combine
import SwiftUI

@MainActor
class ProviderStatsViewModel: ObservableObject {
    @Published var selectedRangeIndex = 1 // 0: 7 Gün, 1: 30 Gün, 2: 3 Ay, 3: 1 Yıl
    
    // Animated counter values
    @Published var animatedEarnings: Double = 0.0
    @Published var animatedJobsCount: Double = 0.0
    @Published var animatedRating: Double = 0.0
    @Published var animatedViews: Double = 0.0
    
    // Final Target totals
    let targetEarnings = 12450.0
    let targetJobsCount = 38.0
    let targetRating = 4.8
    let targetViews = 920.0
    
    @Published var isLoading = false
    @Published var successMessage: String?
    
    func startCounters() {
        animatedEarnings = 0
        animatedJobsCount = 0
        animatedRating = 0
        animatedViews = 0
        
        withAnimation(.easeOut(duration: 1.2)) {
            animatedEarnings = targetEarnings
            animatedJobsCount = targetJobsCount
            animatedRating = targetRating
            animatedViews = targetViews
        }
    }
    
    // Export simulation stubs
    func exportPDF() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        isLoading = false
        successMessage = "İstatistik raporu PDF olarak indirildi."
    }
    
    func exportCSV() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 800_000_000)
        isLoading = false
        successMessage = "Veriler CSV formatında dışa aktarıldı."
    }
    
    func emailReport() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
        successMessage = "Rapor e-posta adresinize gönderildi."
    }
}
