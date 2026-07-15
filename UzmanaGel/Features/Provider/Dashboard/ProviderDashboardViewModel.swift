import Foundation
import Combine

@MainActor
class ProviderDashboardViewModel: ObservableObject {
    // Availability
    @Published var isAvailable = true
    
    // Statistics metrics
    @Published var todayEarnings = "₺1,500"
    @Published var totalJobsCount = "124"
    @Published var averageRating = "4.8"
    @Published var profileViewsCount = "1,840"
    @Published var responseRate = "%98"
    
    // Chart Data Structs
    struct WeeklyEarning: Identifiable {
        let id = UUID()
        let dayName: String
        let amount: Double
    }
    
    struct MonthlyJob: Identifiable {
        let id = UUID()
        let monthName: String
        let count: Int
    }
    
    struct SatisfactionTrend: Identifiable {
        let id = UUID()
        let date: String
        let rating: Double
    }
    
    struct ServiceShare: Identifiable {
        let id = UUID()
        let serviceName: String
        let value: Double
    }
    
    @Published var weeklyEarnings: [WeeklyEarning] = []
    @Published var monthlyJobs: [MonthlyJob] = []
    @Published var satisfactionTrends: [SatisfactionTrend] = []
    @Published var popularServices: [ServiceShare] = []
    
    // Today's appointments
    struct Appointment: Identifiable {
        let id: String
        let customerName: String
        let timeString: String
        let serviceTitle: String
        let price: Double
    }
    
    @Published var todayAppointments: [Appointment] = []
    @Published var pendingBookingsCount = 3
    @Published var unreadMessagesCount = 5
    
    @Published var isLoading = false
    
    private let providerService: ProviderService
    private let scheduleService: ScheduleService
    
    init(providerService: ProviderService = MockProviderService(),
         scheduleService: ScheduleService = MockScheduleService()) {
        self.providerService = providerService
        self.scheduleService = scheduleService
    }
    
    func loadDashboardData() async {
        isLoading = true
        // Simulate loading delays
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Populate chart data
        weeklyEarnings = [
            .init(dayName: "Pzt", amount: 800),
            .init(dayName: "Sal", amount: 1500),
            .init(dayName: "Çar", amount: 950),
            .init(dayName: "Per", amount: 1200),
            .init(dayName: "Cum", amount: 1750),
            .init(dayName: "Cmt", amount: 2400),
            .init(dayName: "Paz", amount: 600)
        ]
        
        monthlyJobs = [
            .init(monthName: "Oca", count: 12),
            .init(monthName: "Şub", count: 18),
            .init(monthName: "Mar", count: 15),
            .init(monthName: "Nis", count: 22),
            .init(monthName: "May", count: 28),
            .init(monthName: "Haz", count: 35)
        ]
        
        satisfactionTrends = [
            .init(date: "Oca", rating: 4.5),
            .init(date: "Şub", rating: 4.6),
            .init(date: "Mar", rating: 4.7),
            .init(date: "Nis", rating: 4.6),
            .init(date: "May", rating: 4.8),
            .init(date: "Haz", rating: 4.8)
        ]
        
        popularServices = [
            .init(serviceName: "Petek Bakımı", value: 45),
            .init(serviceName: "Kombi Montajı", value: 30),
            .init(serviceName: "Tıkanıklık Açma", value: 15),
            .init(serviceName: "Diğer", value: 10)
        ]
        
        todayAppointments = [
            .init(id: "app_1", customerName: "Ayşe Yılmaz", timeString: "10:30", serviceTitle: "Petek Temizliği", price: 1500.0),
            .init(id: "app_2", customerName: "Caner Kaya", timeString: "14:00", serviceTitle: "Tıkanıklık Açma", price: 600.0)
        ]
        
        isLoading = false
    }
    
    func toggleAvailability() {
        isAvailable.toggle()
    }
}
