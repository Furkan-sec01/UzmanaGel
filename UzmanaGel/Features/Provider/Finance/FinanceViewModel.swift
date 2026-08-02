import Foundation
import Combine
import SwiftUI
import FirebaseAuth

@MainActor
class FinanceViewModel: ObservableObject {
    @Published var earnings: [Earning] = []
    @Published var requests: [WithdrawalRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // Computed balances (gerçek veri)
    @Published var totalBalance: Double = 0.0
    @Published var withdrawableBalance: Double = 0.0
    @Published var pendingBalance: Double = 0.0

    // Withdrawal Form Inputs
    @Published var withdrawAmount = ""
    @Published var selectedBank = "Garanti BBVA"
    @Published var iban = ""

    // Monthly invoice summaries (kazançların aylık özeti)
    struct Invoice: Identifiable {
        let id: String
        let period: String
        let amount: Double
        let date: Date
    }

    @Published var invoices: [Invoice] = []
    @Published var selectedInvoice: Invoice? = nil

    let bankList = ["Garanti BBVA", "Akbank", "Yapı Kredi", "Ziraat Bankası", "İş Bankası", "Halkbank", "VakıfBank"]

    private let repo = FinanceRepository()

    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - Load

    func loadFinanceData() async {
        guard let uid = currentUID else {
            errorMessage = "Giriş yapılmamış."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let earningsTask = repo.fetchEarnings(providerId: uid)
            async let pendingTask = repo.fetchPendingEarnings(providerId: uid)
            async let requestsTask = repo.fetchWithdrawalRequests(providerId: uid)

            let (fetchedEarnings, fetchedPending, fetchedRequests) = try await (earningsTask, pendingTask, requestsTask)

            earnings = fetchedEarnings
            requests = fetchedRequests

            // Bakiye hesapla
            totalBalance = repo.calculateTotalBalance(earnings: fetchedEarnings)
            withdrawableBalance = repo.calculateWithdrawableBalance(
                earnings: fetchedEarnings,
                requests: fetchedRequests
            )
            pendingBalance = fetchedPending.reduce(0) { $0 + $1.amount }

            // Aylık fatura özeti oluştur
            invoices = buildMonthlyInvoices(from: fetchedEarnings)

            print("✅ Finans yüklendi – Toplam: ₺\(totalBalance), Çekilebilir: ₺\(withdrawableBalance)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Finans yükleme hatası: \(error)")
        }
    }

    // MARK: - Withdrawal

    func submitWithdrawal() async {
        guard let uid = currentUID else {
            errorMessage = "Giriş yapılmamış."
            return
        }

        guard let amount = Double(withdrawAmount), amount > 0 else {
            errorMessage = "Lütfen geçerli bir tutar girin."
            return
        }

        guard amount <= withdrawableBalance else {
            errorMessage = "Çekilebilir bakiyeden fazla tutar çekemezsiniz."
            return
        }

        let cleanIBAN = iban.replacingOccurrences(of: " ", with: "")
        guard cleanIBAN.count == 26 else {
            errorMessage = "Lütfen geçerli bir IBAN numarası girin (26 Hane)."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let req = try await repo.createWithdrawalRequest(
                providerId: uid,
                amount: amount,
                bankName: selectedBank,
                iban: iban
            )

            requests.insert(req, at: 0)
            withdrawableBalance -= amount
            successMessage = "Para çekim talebi oluşturuldu."
            withdrawAmount = ""
            print("✅ Para çekme talebi oluşturuldu: ₺\(amount)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Para çekme hatası: \(error)")
        }
    }

    // MARK: - IBAN Formatter

    func formatIBAN() {
        var clean = iban.replacingOccurrences(of: " ", with: "").uppercased()
        if !clean.hasPrefix("TR") {
            clean = "TR" + clean.replacingOccurrences(of: "TR", with: "")
        }

        let grouped = clean.map { String($0) }
            .enumerated()
            .map { index, element in
                return index > 0 && index % 4 == 0 ? " " + element : element
            }
            .joined()

        iban = String(grouped.prefix(32))
    }

    // MARK: - Monthly Invoice Builder

    private func buildMonthlyInvoices(from earnings: [Earning]) -> [Invoice] {
        guard !earnings.isEmpty else { return [] }

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"

        // Kazançları aya göre grupla
        var monthlyTotals: [Date: Double] = [:]
        for earning in earnings {
            let components = calendar.dateComponents([.year, .month], from: earning.date)
            if let monthStart = calendar.date(from: components) {
                monthlyTotals[monthStart, default: 0] += earning.amount
            }
        }

        return monthlyTotals.sorted { $0.key > $1.key }.map { date, amount in
            Invoice(
                id: "inv_\(Int(date.timeIntervalSince1970))",
                period: formatter.string(from: date),
                amount: amount,
                date: date
            )
        }
    }
}
