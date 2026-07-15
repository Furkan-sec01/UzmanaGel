import Foundation
import Combine
import PassKit

@MainActor
class PaymentMethodsViewModel: ObservableObject {
    @Published var cards: [PaymentCard] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Add Card Inputs
    @Published var cardHolderName = ""
    @Published var cardNumber = ""
    @Published var expiryDate = ""
    @Published var cvv = ""
    @Published var makeDefaultCard = false
    
    // 3D Secure Simulation
    @Published var show3DSecure = false
    @Published var is3DApproved = false
    
    private let paymentService: PaymentService
    
    init(paymentService: PaymentService = MockPaymentService()) {
        self.paymentService = paymentService
    }
    
    func loadCards() async {
        isLoading = true
        errorMessage = nil
        do {
            self.cards = try await paymentService.fetchCards()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func removeCard(id: String) async {
        isLoading = true
        do {
            try await paymentService.deleteCard(id: id)
            cards.removeAll(where: { $0.id == id })
            successMessage = "Kart başarıyla silindi."
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func makeDefault(id: String) async {
        isLoading = true
        do {
            try await paymentService.setDefaultCard(id: id)
            // Reload cards
            self.cards = try await paymentService.fetchCards()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // Formats card number input by adding spaces after every 4 digits
    func formatCardNumber() {
        let clean = cardNumber.replacingOccurrences(of: " ", with: "")
        let grouped = clean.map { String($0) }
            .enumerated()
            .map { index, element in
                return index > 0 && index % 4 == 0 ? " " + element : element
            }
            .joined()
        cardNumber = String(grouped.prefix(19)) // 16 digits + 3 spaces
    }
    
    // Formats expiration date input (MM/YY)
    func formatExpiryDate() {
        let clean = expiryDate.replacingOccurrences(of: "/", with: "")
        if clean.count >= 2 {
            let month = String(clean.prefix(2))
            let year = String(clean.suffix(from: clean.index(clean.startIndex, offsetBy: 2)).prefix(2))
            expiryDate = "\(month)/\(year)"
        } else {
            expiryDate = clean
        }
        expiryDate = String(expiryDate.prefix(5))
    }
    
    func formatCVV() {
        cvv = String(cvv.prefix(3))
    }
    
    // Trigger 3D Secure Step
    func startAddCardFlow() {
        guard !cardNumber.isEmpty && !expiryDate.isEmpty && !cvv.isEmpty else {
            errorMessage = "Lütfen tüm kart bilgilerini doldurun."
            return
        }
        show3DSecure = true
        is3DApproved = false
    }
    
    // Complete Card Addition
    func finalizeAddCard() async {
        isLoading = true
        show3DSecure = false
        errorMessage = nil
        do {
            let saved = try await paymentService.addCard(
                holderName: cardHolderName,
                number: cardNumber,
                expiry: expiryDate,
                cvv: cvv,
                isDefault: makeDefaultCard
            )
            cards.append(saved)
            successMessage = "Yeni kartınız başarıyla eklendi."
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // Apple Pay Simulation
    func processApplePay() async {
        isLoading = true
        do {
            let success = try await paymentService.startApplePayPayment(amount: 1.0)
            if success {
                successMessage = "Apple Pay doğrulandı."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func resetForm() {
        cardHolderName = ""
        cardNumber = ""
        expiryDate = ""
        cvv = ""
        makeDefaultCard = false
    }
}
