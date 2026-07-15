import SwiftUI

struct PaymentMethodsView: View {
    @StateObject private var viewModel = PaymentMethodsViewModel()
    @State private var showingAddCard = false
    @State private var selectedCardForDeletion: PaymentCard? = nil
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Constants.spacingL) {
                    
                    // Apple Pay Section
                    CardView {
                        VStack(spacing: Constants.spacingM) {
                            HStack {
                                Image(systemName: "applelogo")
                                    .font(.title2)
                                    .foregroundColor(Color.themeText)
                                Text("Apple Pay")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.themeText)
                                Spacer()
                            }
                            
                            Text("Apple Pay ile hızlı ve güvenli ödeme yapmak için Wallet entegrasyonunu kullanın.")
                                .font(.caption)
                                .foregroundColor(Color.themeSecondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button {
                                Task {
                                    await viewModel.processApplePay()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "applelogo")
                                    Text("Apple Pay ile Öde")
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Registered Cards Section
                    VStack(alignment: .leading, spacing: Constants.spacingS) {
                        Text("Kayıtlı Kartlar")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color.themeSecondaryText)
                            .padding(.horizontal, Constants.paddingL)
                        
                        if viewModel.isLoading && viewModel.cards.isEmpty {
                            LoadingView(message: "Kartlarınız yükleniyor...")
                                .frame(height: 150)
                        } else if viewModel.cards.isEmpty {
                            EmptyStateView(
                                iconName: "creditcard.trianglebadge.exclamationmark",
                                title: "Kayıtlı Kart Bulunamadı",
                                message: "Ödemelerinizi güvenle yapmak için kredi veya banka kartı ekleyin.",
                                buttonTitle: "Kart Ekle"
                            ) {
                                showingAddCard = true
                            }
                            .frame(height: 200)
                            .background(Color.themeCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.radiusL))
                            .overlay(RoundedRectangle(cornerRadius: Constants.radiusL).stroke(Color.themeBorder, lineWidth: 1))
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: Constants.spacingM) {
                                ForEach(viewModel.cards) { card in
                                    cardRow(card)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            
            // Status overlay toast notifications
            if let success = viewModel.successMessage {
                toastOverlay(message: success, isError: false)
            }
            if let error = viewModel.errorMessage {
                toastOverlay(message: error, isError: true)
            }
        }
        .navigationTitle("Ödeme Yöntemlerim")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddCard = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color.themePrimary)
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            addCardFormSheet
        }
        .alert(item: $selectedCardForDeletion) { card in
            Alert(
                title: Text("Kartı Sil"),
                message: Text("Son 4 hanesi \(card.last4) olan kartı silmek istediğinize emin misiniz?"),
                primaryButton: .destructive(Text("Sil")) {
                    Task {
                        await viewModel.removeCard(id: card.id)
                    }
                },
                secondaryButton: .cancel(Text("Vazgeç"))
            )
        }
        .task {
            await viewModel.loadCards()
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func cardRow(_ card: PaymentCard) -> some View {
        CardView(cornerRadius: Constants.radiusM, shadowRadius: Constants.shadowRadiusS) {
            VStack(alignment: .leading, spacing: Constants.spacingM) {
                HStack(alignment: .center) {
                    Image(systemName: card.cardType.iconName)
                        .font(.title2)
                        .foregroundColor(Color.themePrimary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("•••• •••• •••• \(card.last4)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.themeText)
                        
                        Text(card.cardHolderName)
                            .font(.caption2)
                            .foregroundColor(Color.themeSecondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        if card.isDefault {
                            BadgeView(text: "Varsayılan", style: .success)
                        } else {
                            Button {
                                Task {
                                    await viewModel.makeDefault(id: card.id)
                                }
                            } label: {
                                Text("Varsayılan Yap")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.themePrimary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Divider()
                    .background(Color.themeBorder)
                
                HStack {
                    Text("Son Kullanma: \(card.expiryDate)")
                        .font(.caption2)
                        .foregroundColor(Color.themeSecondaryText)
                    
                    Spacer()
                    
                    Button {
                        selectedCardForDeletion = card
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Sil")
                        }
                        .font(.caption2)
                        .foregroundColor(Color.themeError)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // Add Card Sheet view
    private var addCardFormSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.spacingM) {
                        CardView {
                            VStack(alignment: .leading, spacing: Constants.spacingM) {
                                Text("Kart Bilgileri")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.themeSecondaryText)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Kart Sahibi Adı")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    TextField("Ad Soyad", text: $viewModel.cardHolderName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Kart Numarası")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    TextField("0000 0000 0000 0000", text: $viewModel.cardNumber)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onChange(of: viewModel.cardNumber) { _, _ in
                                            viewModel.formatCardNumber()
                                        }
                                }
                                
                                HStack(spacing: Constants.spacingM) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Son Kullanma Tarihi")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                        TextField("AA/YY", text: $viewModel.expiryDate)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .onChange(of: viewModel.expiryDate) { _, _ in
                                                viewModel.formatExpiryDate()
                                            }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("CVV (Güvenlik Kodu)")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                        SecureField("123", text: $viewModel.cvv)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .onChange(of: viewModel.cvv) { _, _ in
                                                viewModel.formatCVV()
                                            }
                                    }
                                }
                                
                                Toggle("Varsayılan Ödeme Yöntemi Yap", isOn: $viewModel.makeDefaultCard)
                                    .tint(Color.themePrimary)
                                    .font(.subheadline)
                                    .padding(.vertical, 4)
                                
                                Button {
                                    viewModel.startAddCardFlow()
                                } label: {
                                    Text("Kartı Ekle (3D Secure)")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.themePrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Yeni Kart Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        showingAddCard = false
                    }
                }
            }
            .sheet(isPresented: $viewModel.show3DSecure) {
                secure3DOverlayView
            }
        }
    }
    
    // 3D Secure Web Simulator Sheet
    private var secure3DOverlayView: some View {
        NavigationStack {
            VStack(spacing: Constants.spacingL) {
                VStack(spacing: Constants.spacingS) {
                    Image(systemName: "lock.shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(Color.themeSuccess)
                    
                    Text("3D Secure Güvenli Ödeme Geçidi")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Bankanız tarafından gönderilen tek kullanımlık şifreyi giriniz veya simüle doğrulamayı başlatın.")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                CardView {
                    VStack(spacing: Constants.spacingM) {
                        Text("İşlem Tutarı: ₺0.00 (Doğrulama)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Button {
                            Task {
                                await viewModel.finalizeAddCard()
                                showingAddCard = false
                            }
                        } label: {
                            Text("Simülasyonu Başarılı Onayla")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.themeSuccess)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("3D Secure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        viewModel.show3DSecure = false
                    }
                }
            }
            .background(Color.themeBackground)
        }
    }
    
    // Custom Toast overlay helper
    @ViewBuilder
    private func toastOverlay(message: String, isError: Bool) -> some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                Text(message)
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .padding()
            .background(isError ? Color.themeError : Color.themeSuccess)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(radius: 5)
            .padding(.bottom, Constants.paddingXL)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if isError {
                        viewModel.errorMessage = nil
                    } else {
                        viewModel.successMessage = nil
                    }
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: isError ? viewModel.errorMessage : viewModel.successMessage)
    }
}

#Preview {
    NavigationStack {
        PaymentMethodsView()
    }
}
