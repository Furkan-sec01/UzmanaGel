import SwiftUI
import Charts

struct ProviderStatsView: View {
    @StateObject private var viewModel = ProviderStatsViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.spacingL) {
                        
                        // 1. Date Range Picker
                        Picker("Tarih Aralığı", selection: $viewModel.selectedRangeIndex) {
                            Text("7 Gün").tag(0)
                            Text("30 Gün").tag(1)
                            Text("3 Ay").tag(2)
                            Text("1 Yıl").tag(3)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.top, Constants.paddingS)
                        
                        // 2. Animated Metrics Display
                        metricsGrid
                            .padding(.horizontal)
                        
                        // 3. Export Form actions
                        exportButtonsCard
                            .padding(.horizontal)
                        
                        // 4. Monthly trend visualization
                        CardView {
                            VStack(alignment: .leading, spacing: Constants.spacingM) {
                                Text("Aylara Göre Kazanç Dağılımı")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                Chart {
                                    BarMark(x: .value("Ay", "Oca"), y: .value("Kazanç", 4500))
                                    BarMark(x: .value("Ay", "Şub"), y: .value("Kazanç", 6200))
                                    BarMark(x: .value("Ay", "Mar"), y: .value("Kazanç", 5100))
                                    BarMark(x: .value("Ay", "Nis"), y: .value("Kazanç", 8200))
                                    BarMark(x: .value("Ay", "May"), y: .value("Kazanç", 10400))
                                    BarMark(x: .value("Ay", "Haz"), y: .value("Kazanç", viewModel.animatedEarnings))
                                }
                                .foregroundStyle(Color.themePrimary.gradient)
                                .frame(height: 180)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                if viewModel.isLoading {
                    LoadingView(message: "Rapor hazırlanıyor...")
                }
                
                if let success = viewModel.successMessage {
                    toastOverlay(message: success)
                }
            }
            .navigationTitle("Detaylı İstatistikler")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.startCounters()
            }
            .onChange(of: viewModel.selectedRangeIndex) { _, _ in
                viewModel.startCounters()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            metricCard(title: "Toplam Kazanç", value: "₺\(Int(viewModel.animatedEarnings))", icon: "turkishlirasign.circle", color: Color.themeSuccess)
            metricCard(title: "Tamamlanan İş", value: "\(Int(viewModel.animatedJobsCount)) adet", icon: "checkmark.circle", color: Color.themePrimary)
            metricCard(title: "Ortalama Puan", value: String(format: "%.1f", viewModel.animatedRating), icon: "star.fill", color: Color.themeWarning)
            metricCard(title: "Ziyaretçi Sayısı", value: "\(Int(viewModel.animatedViews))", icon: "person.2.fill", color: Color.themeSecondary)
        }
    }
    
    @ViewBuilder
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        CardView(cornerRadius: Constants.radiusM, shadowRadius: Constants.shadowRadiusS) {
            VStack(alignment: .leading, spacing: Constants.spacingS) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                }
                Text(title)
                    .font(.caption2)
                    .foregroundColor(Color.themeSecondaryText)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themeText)
            }
        }
    }
    
    private var exportButtonsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: Constants.spacingM) {
                Text("Rapor Dışa Aktarma")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                HStack(spacing: 12) {
                    exportButton(title: "PDF İndir", icon: "doc.richtext.fill") {
                        Task { await viewModel.exportPDF() }
                    }
                    exportButton(title: "CSV Aktar", icon: "tablecells.fill") {
                        Task { await viewModel.exportCSV() }
                    }
                    exportButton(title: "E-Posta", icon: "envelope.fill") {
                        Task { await viewModel.emailReport() }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func exportButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(Color.themePrimary)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themeText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.themeBackground)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.themeBorder, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func toastOverlay(message: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text(message)
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .padding()
            .background(Color.themeSuccess)
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
    ProviderStatsView()
}
