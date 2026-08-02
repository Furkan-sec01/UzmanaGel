import SwiftUI
import Charts

@MainActor
struct ProviderStatsView: View {
    @StateObject private var viewModel = ProviderStatsViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.spacingL) {
                        
                        // 1. Date Range Picker
                        Picker("Date Range", selection: $viewModel.selectedRangeIndex) {
                            Text("7 Days").tag(0)
                            Text("30 Days").tag(1)
                            Text("3 Months").tag(2)
                            Text("1 Year").tag(3)
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
                                Text("Aylık Kazanç Dağılımı")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                if viewModel.recentEarnings.isEmpty {
                                    Text("Henüz tamamlanan iş yok.")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                        .frame(height: 180)
                                } else {
                                    Chart {
                                        ForEach(viewModel.recentEarnings) { item in
                                            BarMark(
                                                x: .value("Ay", item.month),
                                                y: .value("Kazanç", item.amount)
                                            )
                                        }
                                    }
                                    .foregroundStyle(Color.themePrimary.gradient)
                                    .frame(height: 180)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                if viewModel.isLoading {
                    LoadingView(message: "Preparing report...")
                }
                
                if let success = viewModel.successMessage {
                    toastOverlay(message: success)
                }
            }
            .navigationTitle("Detaylı İstatistikler")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadStats()
            }
            .onChange(of: viewModel.selectedRangeIndex) { _, _ in
                Task { await viewModel.onRangeChanged() }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            metricCard(title: "Total Earnings", value: "₺\(Int(viewModel.animatedEarnings))", icon: "turkishlirasign.circle", color: Color.themeSuccess)
            metricCard(title: "Completed Jobs", value: "\(Int(viewModel.animatedJobsCount))", icon: "checkmark.circle", color: Color.themePrimary)
            metricCard(title: "Average Rating", value: String(format: "%.1f", viewModel.animatedRating), icon: "star.fill", color: Color.themeWarning)
            metricCard(title: "Visitor Count", value: "\(Int(viewModel.animatedViews))", icon: "person.2.fill", color: Color.themeSecondary)
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
                Text("Export Report")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                HStack(spacing: 12) {
                    exportButton(title: "Download PDF", icon: "doc.richtext.fill") {
                        Task { await viewModel.exportPDF() }
                    }
                    exportButton(title: "Export CSV", icon: "tablecells.fill") {
                        Task { await viewModel.exportCSV() }
                    }
                    exportButton(title: "Email", icon: "envelope.fill") {
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
