import Foundation
import Combine
import SwiftUI

@MainActor
class FinanceViewModel: ObservableObject {
    @Published var earnings: [Earning] = []
    @Published var requests: [WithdrawalRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Balance details
    @Published var totalBalance = 2850.0
    @Published var withdrawableBalance = 2250.0
    
    // Withdrawal Form Inputs
    @Published var withdrawAmount = ""
    @Published var selectedBank = "Garanti BBVA"
    @Published var iban = ""
    
    // Mock Invoices
    struct Invoice: Identifiable {
        let id: String
        let period: String
        let amount: Double
        let date: Date
    }
    
    @Published var invoices: [Invoice] = []
    @Published var selectedInvoice: Invoice? = nil
    
    let bankList = ["Garanti BBVA", "Akbank", "Yapı Kredi", "Ziraat Bankası", "İş Bankası"]
    
    private let financeService: FinanceService
    
    init(financeService: FinanceService = MockFinanceService()) {
        self.financeService = financeService
    }
    
    func loadFinanceData() async {
        isLoading = true
        errorMessage = nil
        do {
            self.earnings = try await financeService.fetchEarnings()
            self.requests = try await financeService.fetchWithdrawalRequests()
            
            // Populate mock invoices
            self.invoices = [
                .init(id: "inv_1", period: "Haziran 2026", amount: 480.0, date: Date().addingTimeInterval(-86400 * 15)),
                .init(id: "inv_2", period: "Mayıs 2026", amount: 650.0, date: Date().addingTimeInterval(-86400 * 45)),
                .init(id: "inv_3", period: "Nisan 2026", amount: 320.0, date: Date().addingTimeInterval(-86400 * 75))
            ]
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func submitWithdrawal() async {
        guard let amount = Double(withdrawAmount), amount > 0 else {
            errorMessage = "Lütfen geçerli bir tutar girin."
            return
        }
        
        guard amount <= withdrawableBalance else {
            errorMessage = "Çekilebilir bakiyeden fazla tutar çekemezsiniz."
            return
        }
        
        guard iban.replacingOccurrences(of: " ", with: "").count == 26 else {
            errorMessage = "Lütfen geçerli bir IBAN numarası girin (26 Hane)."
            return
        }
        
        isLoading = true
        errorMessage = nil
        do {
            let req = try await financeService.requestWithdrawal(
                amount: amount,
                bankName: selectedBank,
                iban: iban
            )
            requests.insert(req, at: 0)
            withdrawableBalance -= amount
            successMessage = "Para çekim talebi oluşturuldu."
            withdrawAmount = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // Auto formats IBAN prefix with spaces: e.g. TRxx xxxx xxxx xxxx xxxx xxxx xx
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
        
        iban = String(grouped.prefix(32)) // TR + 24 digits + spaces
    }
}
