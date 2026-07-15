import SwiftUI

struct FinanceView: View {
    @StateObject private var viewModel = FinanceViewModel()
    @State private var showingWithdrawalForm = false
    @State private var showingInvoicePreview = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.spacingL) {
                        
                        // 1. Balance Summary Card
                        balanceCardSection
                            .padding(.horizontal)
                            .padding(.top, Constants.paddingS)
                        
                        // 2. Earnings History List
                        earningsHistorySection
                            .padding(.horizontal)
                        
                        // 3. Payout Requests (durum takibi)
                        payoutRequestsSection
                            .padding(.horizontal)
                        
                        // 4. Invoices & Taxes
                        invoicesSection
                            .padding(.horizontal)
                    }
                    .padding(.bottom, Constants.paddingXL)
                }
                
                if let success = viewModel.successMessage {
                    toastOverlay(message: success, isError: false)
                }
                if let error = viewModel.errorMessage {
                    toastOverlay(message: error, isError: true)
                }
            }
            .navigationTitle("Finansal Yönetim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingWithdrawalForm = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "banknote")
                            Text("Para Çek")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themePrimary)
                    }
                }
            }
            .sheet(isPresented: $showingWithdrawalForm) {
                withdrawalFormSheet
            }
            .fullScreenCover(item: $viewModel.selectedInvoice) { inv in
                invoicePDFPreviewSheet(inv)
            }
            .task {
                await viewModel.loadFinanceData()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var balanceCardSection: some View {
        CardView(cornerRadius: Constants.radiusXL, shadowRadius: Constants.shadowRadiusM) {
            VStack(spacing: Constants.spacingM) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Toplam Bakiye")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                        Text("₺\(String(format: "%.2f", viewModel.totalBalance))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.themeText)
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Çekilebilir Bakiye")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                        Text("₺\(String(format: "%.2f", viewModel.withdrawableBalance))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color.themeSuccess)
                    }
                }
                
                Divider()
                    .background(Color.themeBorder)
                
                Button {
                    showingWithdrawalForm = true
                } label: {
                    Text("Banka Hesabına Aktar")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var earningsHistorySection: some View {
        VStack(alignment: .leading, spacing: Constants.spacingS) {
            Text("Kazanç Geçmişi")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color.themeSecondaryText)
                .padding(.horizontal, Constants.paddingS)
            
            CardView {
                VStack(spacing: 0) {
                    ForEach(viewModel.earnings) { earn in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(earn.jobTitle)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.themeText)
                                
                                Text(earn.description)
                                    .font(.caption2)
                                    .foregroundColor(Color.themeSecondaryText)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("₺\(Int(earn.amount))")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(earn.isPending ? Color.themeWarning : Color.themeSuccess)
                                
                                Text(earn.isPending ? "Beklemede" : "Tamamlandı")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(earn.isPending ? Color.themeWarning : Color.themeSuccess)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        if earn.id != viewModel.earnings.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private var payoutRequestsSection: some View {
        VStack(alignment: .leading, spacing: Constants.spacingS) {
            Text("Para Çekme Talepleri")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color.themeSecondaryText)
                .padding(.horizontal, Constants.paddingS)
            
            if viewModel.requests.isEmpty {
                CardView {
                    Text("Henüz para çekme talebiniz bulunmamaktadır.")
                        .font(.footnote)
                        .foregroundColor(Color.themeSecondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                CardView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.requests) { req in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(req.bankName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.themeText)
                                    
                                    Text("IBAN: •••• " + String(req.iban.suffix(4)))
                                        .font(.caption2)
                                        .foregroundColor(Color.themeSecondaryText)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("₺\(Int(req.amount))")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    
                                    BadgeView(
                                        text: req.status.rawValue,
                                        style: req.status == .approved ? .success : (req.status == .pending ? .warning : .error)
                                    )
                                }
                            }
                            .padding(.vertical, 8)
                            
                            if req.id != viewModel.requests.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var invoicesSection: some View {
        VStack(alignment: .leading, spacing: Constants.spacingS) {
            Text("Faturalar ve Vergiler")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color.themeSecondaryText)
                .padding(.horizontal, Constants.paddingS)
            
            CardView {
                VStack(spacing: 0) {
                    ForEach(viewModel.invoices) { inv in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(inv.period)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.themeText)
                                Text("Komisyon Faturası")
                                    .font(.caption2)
                                    .foregroundColor(Color.themeSecondaryText)
                            }
                            Spacer()
                            
                            Button {
                                viewModel.selectedInvoice = inv
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.text")
                                    Text("Görüntüle")
                                }
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.themePrimary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 8)
                        
                        if inv.id != viewModel.invoices.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    // Withdrawal Request form panel sheet
    private var withdrawalFormSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.spacingM) {
                        CardView {
                            VStack(alignment: .leading, spacing: Constants.spacingM) {
                                Text("Çekim Talebi Oluştur")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.themeSecondaryText)
                                
                                Text("Çekilebilir Tutar: ₺\(Int(viewModel.withdrawableBalance))")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.themeSuccess)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Çekilecek Tutar (₺)")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    TextField("Tutar", text: $viewModel.withdrawAmount)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Banka Seçimi")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    
                                    Picker("Banka", selection: $viewModel.selectedBank) {
                                        ForEach(viewModel.bankList, id: \.self) { bank in
                                            Text(bank).tag(bank)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(.vertical, 4)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("IBAN Numarası")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    TextField("TR00 0000 0000 0000 0000 0000 00", text: $viewModel.iban)
                                        .keyboardType(.default)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onChange(of: viewModel.iban) { _, _ in
                                            viewModel.formatIBAN()
                                        }
                                }
                                
                                Button {
                                    Task {
                                        await viewModel.submitWithdrawal()
                                        showingWithdrawalForm = false
                                    }
                                } label: {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Talep Gönder")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.themePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                                .disabled(viewModel.isLoading)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Para Çek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        showingWithdrawalForm = false
                    }
                }
            }
        }
    }
    
    // Invoice PDF Preview Sheet Simulator
    @ViewBuilder
    private func invoicePDFPreviewSheet(_ invoice: FinanceViewModel.Invoice) -> some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    CardView {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(Color.themeSuccess)
                                    .font(.title2)
                                Text("UzmanaGel Dijital Fatura")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Fatura Dönemi:")
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondaryText)
                                Spacer()
                                Text(invoice.period)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Fatura Numarası:")
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondaryText)
                                Spacer()
                                Text("INV-2026-00" + invoice.id.suffix(2))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Hizmet Komisyon Bedeli:")
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondaryText)
                                Spacer()
                                Text("₺" + String(format: "%.2f", invoice.amount))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.themePrimary)
                            }
                            
                            Divider()
                            
                            Text("Bu fatura elektronik imza ile imzalanmıştır. Maliye Bakanlığı standartlarına uygundur.")
                                .font(.system(size: 8))
                                .italic()
                                .foregroundColor(Color.themeSecondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button {
                        // Action to share or export
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Paylaş veya İndir")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.themePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                        .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical)
            }
            .navigationTitle("Fatura Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        viewModel.selectedInvoice = nil
                    }
                }
            }
        }
    }
    
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    viewModel.successMessage = nil
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: viewModel.successMessage)
    }
}

#Preview {
    FinanceView()
}
