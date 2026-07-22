import SwiftUI
import Charts

struct ProviderDashboardView: View {
    @StateObject private var viewModel = ProviderDashboardViewModel()
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView(message: "Dashboard yükleniyor...")
                } else {
                    ScrollView {
                        VStack(spacing: Constants.spacingL) {
                            
                            // 1. Quick Info & Availability Toggle
                            availabilityHeader
                                .padding(.horizontal)
                            
                            // 2. Real reservation metrics
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ],
                                spacing: 16
                            ) {
                                StatCard(
                                    title: "Bugünkü Randevu",
                                    value: String(
                                        viewModel.todayAppointments.count
                                    ),
                                    changeText: nil,
                                    iconName: "calendar",
                                    color: Color.themeSuccess
                                )

                                StatCard(
                                    title: "Bekleyen Talep",
                                    value: String(
                                        viewModel.pendingBookingsCount
                                    ),
                                    changeText: nil,
                                    iconName: "hourglass",
                                    color: Color.themeWarning
                                )

                                StatCard(
                                    title: "Yaklaşan Randevu",
                                    value: String(
                                        viewModel.upcomingBookingsCount
                                    ),
                                    changeText: nil,
                                    iconName: "calendar.badge.clock",
                                    color: Color.themeSecondary
                                )

                                StatCard(
                                    title: "Tamamlanan İş",
                                    value: viewModel.totalJobsCount,
                                    changeText: nil,
                                    iconName: "checkmark.circle",
                                    color: Color.themePrimary
                                )
                            }
                            .padding(.horizontal)

                            // 3. Today's appointments
                            todayAppointmentsSection
                                .padding(.horizontal)

                            // 4. Real reservation statistics
                            chartsSection
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Usta Paneli")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditProfile = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Color.themePrimary)
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditBusinessProfileView()
            }
            .task {
                await viewModel.loadDashboardData()
            }
            .refreshable {
                await viewModel.loadDashboardData()
            }
            .alert(
                "Hata".localized,
                isPresented: $viewModel.showError
            ) {
                Button("Tamam".localized, role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var availabilityHeader: some View {
        CardView(cornerRadius: Constants.radiusL, shadowRadius: Constants.shadowRadiusS) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Çalışma Durumu")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                    Text(viewModel.isAvailable ? "Yeni İşlere Açıksınız" : "Müsait Değilsiniz")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.isAvailable ? Color.themeSuccess : Color.themeError)
                }
                Spacer()
                
                Toggle(
                    "",
                    isOn: Binding(
                        get: {
                            viewModel.isAvailable
                        },
                        set: { newValue in
                            Task {
                                await viewModel.updateAvailability(
                                    to: newValue
                                )
                            }
                        }
                    )
                )
                .labelsHidden()
                .tint(Color.themeSuccess)
                .disabled(viewModel.isUpdatingAvailability)
            }
        }
    }
    
    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            quickActionItem(icon: "calendar.badge.clock", count: viewModel.pendingBookingsCount, title: "Bekleyenler", color: Color.themeWarning)
            quickActionItem(icon: "bubble.left.and.bubble.right", count: viewModel.unreadMessagesCount, title: "Mesajlar", color: Color.themePrimary)
        }
    }
    
    @ViewBuilder
    private func quickActionItem(icon: String, count: Int, title: String, color: Color) -> some View {
        CardView(cornerRadius: Constants.radiusM, shadowRadius: Constants.shadowRadiusS) {
            HStack(spacing: Constants.spacingM) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.subheadline)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                    
                    HStack(spacing: 6) {
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.themeText)
                        
                        Text("Yeni")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
        }
    }
    
    private var todayAppointmentsSection: some View {
        VStack(alignment: .leading, spacing: Constants.spacingS) {
            Text("Bugünün Randevuları")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color.themeSecondaryText)
                .padding(.horizontal, Constants.paddingS)
            
            if viewModel.todayAppointments.isEmpty {
                CardView {
                    Text("Bugün için planlanmış bir randevunuz bulunmamaktadır.")
                        .font(.footnote)
                        .foregroundColor(Color.themeSecondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.todayAppointments) { app in
                        HStack(spacing: Constants.spacingM) {
                            VStack(alignment: .center) {
                                Text(app.timeString)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.themePrimary)
                            }
                            .frame(width: 60)
                            .padding(.vertical, 8)
                            .background(Color.themePrimary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: Constants.radiusS))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(app.customerName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.themeText)
                                
                                Text(app.serviceTitle)
                                    .font(.caption2)
                                    .foregroundColor(Color.themeSecondaryText)
                            }
                            Spacer()
                            Text("₺\(Int(app.price))")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themeText)
                        }
                        .padding()
                        .background(Color.themeCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                        .overlay(RoundedRectangle(cornerRadius: Constants.radiusM).stroke(Color.themeBorder, lineWidth: 1))
                    }
                }
            }
        }
    }
    
    private var chartsSection: some View {
        VStack(
            alignment: .leading,
            spacing: Constants.spacingL
        ) {
            Text("İş İstatistikleri")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color.themeSecondaryText)
                .padding(.horizontal, Constants.paddingS)

            CardView {
                VStack(
                    alignment: .leading,
                    spacing: Constants.spacingM
                ) {
                    Text("Son 6 Ay Tamamlanan İşler")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeText)

                    if viewModel.monthlyJobs.allSatisfy({
                        $0.count == 0
                    }) {
                        dashboardEmptyState(
                            icon: "chart.bar.xaxis",
                            title: "Henüz tamamlanan iş yok",
                            message:
                                "Son altı aya ait tamamlanan iş " +
                                "verisi bulunmuyor."
                        )
                    } else {
                        Chart {
                            ForEach(viewModel.monthlyJobs) { item in
                                BarMark(
                                    x: .value(
                                        "Ay",
                                        item.monthName
                                    ),
                                    y: .value(
                                        "Tamamlanan İş",
                                        item.count
                                    )
                                )
                                .foregroundStyle(
                                    Color.themePrimary.gradient
                                )
                                .cornerRadius(4)
                            }
                        }
                        .frame(height: 180)
                    }
                }
            }

            CardView {
                VStack(
                    alignment: .leading,
                    spacing: Constants.spacingM
                ) {
                    Text("Tamamlanan Hizmet Dağılımı")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeText)

                    if viewModel.popularServices.isEmpty {
                        dashboardEmptyState(
                            icon: "chart.pie",
                            title: "Hizmet verisi bulunmuyor",
                            message:
                                "Tamamlanan işler oluştuğunda hizmet " +
                                "dağılımı burada gösterilecek."
                        )
                    } else {
                        Chart {
                            ForEach(
                                viewModel.popularServices.prefix(5)
                            ) { item in
                                SectorMark(
                                    angle: .value(
                                        "Tamamlanan İş",
                                        item.value
                                    ),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 2
                                )
                                .foregroundStyle(
                                    by: .value(
                                        "Hizmet",
                                        item.serviceName
                                    )
                                )
                                .cornerRadius(5)
                            }
                        }
                        .frame(height: 220)
                    }
                }
            }
        }
    }

    private func dashboardEmptyState(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(Color.themeSecondaryText)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.themeText)

            Text(message)
                .font(.caption)
                .foregroundColor(Color.themeSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .padding(.horizontal)
    }

}

#Preview {
    ProviderDashboardView()
}
