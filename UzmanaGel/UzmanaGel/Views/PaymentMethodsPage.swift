//
//  PaymentMethodsPage.swift
//  UzmanaGel
//


//
//  PaymentMethodsPage.swift
//  UzmanaGel
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Model
struct SavedCard: Identifiable {
    let id: String
    let lastFour: String
    let cardHolder: String
    let expiryMonth: Int
    let expiryYear: Int
    let brand: String          // "visa" | "mastercard" | "other"
    var isDefault: Bool

    var brandIcon: String {
        switch brand.lowercased() {
        case "visa":       return "creditcard.fill"
        case "mastercard": return "creditcard.fill"
        default:           return "creditcard"
        }
    }

    var brandColor: Color {
        switch brand.lowercased() {
        case "visa":       return .blue
        case "mastercard": return .orange
        default:           return .gray
        }
    }

    var maskedNumber: String { "**** **** **** \(lastFour)" }
    var expiryDisplay: String { String(format: "%02d/%02d", expiryMonth, expiryYear % 100) }
}

// MARK: - View
struct PaymentMethodsPage: View {

    @State private var cards: [SavedCard] = []
    @State private var isLoading = true
    @State private var showAddCard = false
    @State private var cardToDelete: SavedCard?
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                if isLoading {
                    ProgressView()
                        .padding(.top, 60)
                } else if cards.isEmpty {
                    emptyState
                } else {
                    cardsSection
                }

                applePaySection
                addCardButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Ödeme Yöntemleri")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadCards() }
        .sheet(isPresented: $showAddCard) {
            AddCardSheet { newCard in
                cards.append(newCard)
                saveCard(newCard)
            }
        }
        .alert("Kartı Sil", isPresented: $showDeleteAlert, presenting: cardToDelete) { card in
            Button("Sil", role: .destructive) { deleteCard(card) }
            Button("İptal", role: .cancel) {}
        } message: { card in
            Text("**** \(card.lastFour) kartını silmek istediğinizden emin misiniz?")
        }
    }

    // MARK: - Cards Section
    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color("PrimaryColor"))
                Text("KAYITLI KARTLAR")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(cards) { card in
                    cardView(card)
                }
            }
        }
    }

    private func cardView(_ card: SavedCard) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    card.brandColor.opacity(0.85),
                    card.brandColor.opacity(0.55)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 140, height: 140)
                .offset(x: 180, y: -50)
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 100, height: 100)
                .offset(x: 220, y: 20)

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(card.brand.capitalized)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    if card.isDefault {
                        Text("Varsayılan")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Text(card.maskedNumber)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(2)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KART SAHİBİ")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))
                        Text(card.cardHolder.uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("SON KULLANMA")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))
                        Text(card.expiryDisplay)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 165)
        .contextMenu {
            if !card.isDefault {
                Button {
                    setDefault(card)
                } label: {
                    Label("Varsayılan Yap", systemImage: "checkmark.circle")
                }
            }
            Button(role: .destructive) {
                cardToDelete = card
                showDeleteAlert = true
            } label: {
                Label("Kartı Sil", systemImage: "trash")
            }
        }
    }

    // MARK: - Apple Pay Section
    private var applePaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
                Text("DİJİTAL CÜZDAN")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black)
                    Image(systemName: "apple.logo")
                        .foregroundColor(.white)
                        .font(.system(size: 22))
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Apple Pay")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color("Text"))
                    Text("Hızlı ve güvenli ödeme")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Aktif")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(14)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Add Card Button
    private var addCardButton: some View {
        Button {
            showAddCard = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text("Yeni Kart Ekle")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color("PrimaryColor"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 52))
                .foregroundColor(Color("PrimaryColor").opacity(0.5))
            Text("Kayıtlı kart bulunamadı")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("Text"))
            Text("Hızlı ödeme için kartınızı ekleyin.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Firestore
    private func loadCards() {
        guard let uid = Auth.auth().currentUser?.uid else { isLoading = false; return }
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("paymentMethods")
            .getDocuments { snap, _ in
                isLoading = false
                cards = snap?.documents.compactMap { doc -> SavedCard? in
                    let d = doc.data()
                    guard let last4 = d["lastFour"] as? String,
                          let holder = d["cardHolder"] as? String,
                          let expM = d["expiryMonth"] as? Int,
                          let expY = d["expiryYear"] as? Int else { return nil }
                    return SavedCard(
                        id: doc.documentID,
                        lastFour: last4,
                        cardHolder: holder,
                        expiryMonth: expM,
                        expiryYear: expY,
                        brand: d["brand"] as? String ?? "other",
                        isDefault: d["isDefault"] as? Bool ?? false
                    )
                } ?? []
            }
    }

    private func saveCard(_ card: SavedCard) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("paymentMethods").document(card.id)
            .setData([
                "lastFour": card.lastFour,
                "cardHolder": card.cardHolder,
                "expiryMonth": card.expiryMonth,
                "expiryYear": card.expiryYear,
                "brand": card.brand,
                "isDefault": card.isDefault,
                "createdAt": FieldValue.serverTimestamp()
            ])
    }

    private func deleteCard(_ card: SavedCard) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("paymentMethods").document(card.id)
            .delete()
        cards.removeAll { $0.id == card.id }
    }

    private func setDefault(_ card: SavedCard) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let ref = db.collection("users").document(uid).collection("paymentMethods")
        cards.indices.forEach { idx in
            let isNow = cards[idx].id == card.id
            ref.document(cards[idx].id).updateData(["isDefault": isNow])
            cards[idx].isDefault = isNow
        }
    }
}

// MARK: - Add Card Sheet
struct AddCardSheet: View {
    let onAdd: (SavedCard) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var cardNumber = ""
    @State private var cardHolder = ""
    @State private var expiryMonth = 1
    @State private var expiryYear = Calendar.current.component(.year, from: Date())
    @State private var cvv = ""
    @State private var isDefault = false
    @State private var showCVV = false
    @State private var errorMsg: String?

    private var formattedNumber: String {
        let digits = cardNumber.filter(\.isNumber).prefix(16)
        return stride(from: 0, to: digits.count, by: 4)
            .map { idx -> String in
                let start = digits.index(digits.startIndex, offsetBy: idx)
                let end = digits.index(start, offsetBy: min(4, digits.count - idx))
                return String(digits[start..<end])
            }
            .joined(separator: " ")
    }

    private var detectedBrand: String {
        let d = cardNumber.filter(\.isNumber)
        if d.hasPrefix("4") { return "visa" }
        if d.hasPrefix("5") || d.hasPrefix("2") { return "mastercard" }
        return "other"
    }

    private var years: [Int] {
        let y = Calendar.current.component(.year, from: Date())
        return Array(y...(y + 12))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Live card preview
                    cardPreview

                    // Form fields
                    VStack(spacing: 14) {
                        formField("Kart Numarası", systemImage: "creditcard") {
                            TextField("0000 0000 0000 0000", text: $cardNumber)
                                .keyboardType(.numberPad)
                                .onChange(of: cardNumber) { _, v in
                                    cardNumber = String(v.filter(\.isNumber).prefix(16))
                                }
                        }

                        formField("Kart Sahibi", systemImage: "person") {
                            TextField("AD SOYAD", text: $cardHolder)
                                .textInputAutocapitalization(.characters)
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Son Kullanma Tarihi")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                HStack(spacing: 8) {
                                    // Month picker
                                    Menu {
                                        ForEach(1...12, id: \.self) { m in
                                            Button(String(format: "%02d", m)) {
                                                expiryMonth = m
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(String(format: "%02d", expiryMonth))
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(Color("Text"))
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(Color("CardBackground"))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }

                                    Text("/")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.secondary)

                                    // Year picker
                                    Menu {
                                        ForEach(years, id: \.self) { y in
                                            Button(String(y)) {
                                                expiryYear = y
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(String(expiryYear))
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(Color("Text"))
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(Color("CardBackground"))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }

                        formField("CVV", systemImage: "lock.fill") {
                            HStack {
                                Group {
                                    if showCVV {
                                        TextField("000", text: $cvv)
                                    } else {
                                        SecureField("000", text: $cvv)
                                    }
                                }
                                .keyboardType(.numberPad)
                                .onChange(of: cvv) { _, v in cvv = String(v.filter(\.isNumber).prefix(4)) }
                                Button { showCVV.toggle() } label: {
                                    Image(systemName: showCVV ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Toggle("Varsayılan kart olarak ayarla", isOn: $isDefault)
                            .font(.system(size: 14))
                            .tint(Color("PrimaryColor"))
                            .padding(.horizontal, 4)
                    }

                    if let err = errorMsg {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }

                    Button {
                        addCard()
                    } label: {
                        Text("KARTI EKLE")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color("PrimaryColor"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(Color("BackgroundColor"))
            .navigationTitle("Yeni Kart Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }

    private var cardPreview: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                gradient: Gradient(colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.65)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 140)
                .offset(x: 200, y: -40)

            VStack(alignment: .leading, spacing: 16) {
                Text(detectedBrand.capitalized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                Text(formattedNumber.isEmpty ? "**** **** **** ****" : formattedNumber)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(2)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KART SAHİBİ").font(.system(size: 9)).foregroundColor(.white.opacity(0.6))
                        Text(cardHolder.isEmpty ? "AD SOYAD" : cardHolder.uppercased())
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("SON KULLANMA").font(.system(size: 9)).foregroundColor(.white.opacity(0.6))
                        Text(String(format: "%02d/%02d", expiryMonth, expiryYear % 100))
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func formField<Content: View>(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundColor(.secondary)
                    .frame(width: 18)
                content()
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func addCard() {
        let digits = cardNumber.filter(\.isNumber)
        guard digits.count >= 13 else { errorMsg = "Geçerli bir kart numarası girin."; return }
        guard !cardHolder.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Kart sahibi adını girin."; return }
        guard cvv.count >= 3 else { errorMsg = "Geçerli bir CVV girin."; return }
        errorMsg = nil
        let card = SavedCard(
            id: UUID().uuidString,
            lastFour: String(digits.suffix(4)),
            cardHolder: cardHolder.trimmingCharacters(in: .whitespaces),
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            brand: detectedBrand,
            isDefault: isDefault
        )
        onAdd(card)
        dismiss()
    }
}

#Preview {
    NavigationStack { PaymentMethodsPage() }
}
