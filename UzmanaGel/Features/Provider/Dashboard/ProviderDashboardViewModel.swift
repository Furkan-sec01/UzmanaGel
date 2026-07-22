import Foundation
import Combine
import FirebaseAuth

private enum DashboardError: LocalizedError {
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Kullanıcı oturumu bulunamadı."
        }
    }
}

@MainActor
final class ProviderDashboardViewModel: ObservableObject {

    @Published var isAvailable = true
    @Published var isUpdatingAvailability = false

    // These metrics need payment, review, and analytics data.
    @Published var todayEarnings = "—"
    @Published var averageRating = "—"
    @Published var profileViewsCount = "—"
    @Published var responseRate = "—"

    @Published var totalJobsCount = "0"
    @Published var pendingBookingsCount = 0
    @Published var upcomingBookingsCount = 0
    @Published var unreadMessagesCount = 0

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

    struct Appointment: Identifiable {
        let id: String
        let customerName: String
        let timeString: String
        let serviceTitle: String
        let price: Double
    }

    @Published var todayAppointments: [Appointment] = []

    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false

    private let reservationRepository: ReservationRepository
    private let userRepository: UserRepository

    init(
        reservationRepository: ReservationRepository =
            ReservationRepository(),
        userRepository: UserRepository = UserRepository()
    ) {
        self.reservationRepository = reservationRepository
        self.userRepository = userRepository
    }

    func loadDashboardData() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = ""
        showError = false

        defer {
            isLoading = false
        }

        do {
            guard let uid = Auth.auth().currentUser?.uid else {
                throw DashboardError.userNotFound
            }

            let reservations =
                try await reservationRepository.fetchProviderReservations()

            let availability =
                try await userRepository.fetchExpertAvailability(uid: uid)

            isAvailable = availability
            updateMetrics(from: reservations)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func updateAvailability(to newValue: Bool) async {
        guard !isUpdatingAvailability else { return }
        guard newValue != isAvailable else { return }

        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = DashboardError.userNotFound.localizedDescription
            showError = true
            return
        }

        let previousValue = isAvailable

        isAvailable = newValue
        isUpdatingAvailability = true
        errorMessage = ""
        showError = false

        defer {
            isUpdatingAvailability = false
        }

        do {
            try await userRepository.updateExpertAvailability(
                uid: uid,
                isAvailable: newValue
            )
        } catch {
            isAvailable = previousValue
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func updateMetrics(from reservations: [Reservation]) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(
            byAdding: .day,
            value: 1,
            to: startOfToday
        ) ?? Date()

        totalJobsCount = String(
            reservations.filter { $0.status == .completed }.count
        )

        pendingBookingsCount = reservations.filter {
            $0.status == .pending
        }.count

        upcomingBookingsCount = reservations.filter {
            isActiveAppointment($0)
                && $0.reservationDate >= startOfTomorrow
        }.count

        let todayReservations = reservations
            .filter {
                isActiveAppointment($0)
                    && calendar.isDateInToday($0.reservationDate)
            }
            .sorted {
                $0.reservationDate < $1.reservationDate
            }

        todayAppointments = todayReservations.map { reservation in
            Appointment(
                id: reservation.reservationId,
                customerName: reservation.customerName,
                timeString: timeFormatter.string(
                    from: reservation.reservationDate
                ),
                serviceTitle: reservation.serviceTitle,
                price: Double(reservation.servicePrice)
            )
        }

        monthlyJobs = makeMonthlyJobs(from: reservations)
        popularServices = makePopularServices(from: reservations)
    }

    private func isActiveAppointment(
        _ reservation: Reservation
    ) -> Bool {
        reservation.status == .accepted
            || reservation.status == .inProgress
    }

    private func makeMonthlyJobs(
        from reservations: [Reservation]
    ) -> [MonthlyJob] {
        let calendar = Calendar.current
        let now = Date()

        return (0..<6).reversed().compactMap { offset in
            guard let monthDate = calendar.date(
                byAdding: .month,
                value: -offset,
                to: now
            ) else {
                return nil
            }

            let count = reservations.filter {
                $0.status == .completed
                    && calendar.isDate(
                        $0.reservationDate,
                        equalTo: monthDate,
                        toGranularity: .month
                    )
            }.count

            return MonthlyJob(
                monthName: monthFormatter.string(from: monthDate),
                count: count
            )
        }
    }

    private func makePopularServices(
        from reservations: [Reservation]
    ) -> [ServiceShare] {
        let completedReservations = reservations.filter {
            $0.status == .completed
        }

        let groupedServices = Dictionary(
            grouping: completedReservations,
            by: \.serviceTitle
        )

        return groupedServices
            .map { serviceTitle, reservations in
                ServiceShare(
                    serviceName: serviceTitle,
                    value: Double(reservations.count)
                )
            }
            .sorted {
                $0.value > $1.value
            }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMM"
        return formatter
    }
}
