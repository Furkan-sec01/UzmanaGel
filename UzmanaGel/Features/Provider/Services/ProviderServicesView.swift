import SwiftUI
import PhotosUI

struct ProviderServicesView: View {
    @StateObject private var viewModel = ProviderServicesViewModel()
    @State private var showingAddEditSheet = false
    @State private var editingService: ExpertService? = nil
    @State private var serviceToDelete: ExpertService? = nil
    @State private var imageItems: [PhotosPickerItem] = []
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.services.isEmpty {
                LoadingView(message: "Hizmetleriniz yükleniyor...")
            } else if viewModel.services.isEmpty {
                EmptyStateView(
                    iconName: "square.dashed.badge.plus",
                    title: "Hizmet Bulunamadı",
                    message: "Müşterilere sunabileceğiniz hizmetlerinizi ekleyerek kazanmaya başlayın.",
                    buttonTitle: "Yeni Hizmet Ekle"
                ) {
                    editingService = nil
                    viewModel.resetForm()
                    showingAddEditSheet = true
                }
            } else {
                List {
                    ForEach(viewModel.services) { service in
                        serviceCard(service)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await viewModel.loadServices()
                }
            }
            
            // Toast overlays
            if let success = viewModel.successMessage {
                toastOverlay(message: success, isError: false)
            }
            if let error = viewModel.errorMessage {
                toastOverlay(message: error, isError: true)
            }
        }
        .navigationTitle("Hizmet Yönetimi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editingService = nil
                    viewModel.resetForm()
                    showingAddEditSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color.themePrimary)
                }
            }
        }
        .sheet(isPresented: $showingAddEditSheet) {
            addEditServiceFormSheet
        }
        .alert(item: $serviceToDelete) { service in
            Alert(
                title: Text("Hizmeti Sil"),
                message: Text("'\(service.title)' hizmetini silmek istediğinize emin misiniz?"),
                primaryButton: .destructive(Text("Sil")) {
                    Task {
                        await viewModel.softDeleteService(id: service.id)
                    }
                },
                secondaryButton: .cancel(Text("Vazgeç"))
            )
        }
        .task {
            await viewModel.loadServices()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func serviceCard(_ service: ExpertService) -> some View {
        CardView(cornerRadius: Constants.radiusM, shadowRadius: Constants.shadowRadiusS) {
            VStack(alignment: .leading, spacing: Constants.spacingS) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(service.title)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.themeText)
                        
                        Text(service.description)
                            .font(.caption2)
                            .foregroundColor(Color.themeSecondaryText)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { service.isActive },
                        set: { _ in
                            Task {
                                await viewModel.toggleServiceActive(id: service.id)
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(Color.themeSuccess)
                }
                
                HStack {
                    Text("₺\(Int(service.price)) / \(service.pricingType.rawValue)")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themePrimary)
                    
                    Spacer()
                    
                    Text("Tahmini Süre: \(service.durationMinutes) dk")
                        .font(.caption2)
                        .foregroundColor(Color.themeSecondaryText)
                }
                
                Divider()
                    .background(Color.themeBorder)
                
                HStack(spacing: Constants.spacingM) {
                    Spacer()
                    
                    Button {
                        editingService = service
                        viewModel.populateForm(with: service)
                        showingAddEditSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Düzenle")
                        }
                        .font(.caption2)
                        .foregroundColor(Color.themePrimary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        serviceToDelete = service
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
        .opacity(service.isActive ? 1.0 : 0.6)
    }
    
    // Add/Edit Form view sheet
    private var addEditServiceFormSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.spacingM) {
                        CardView {
                            VStack(alignment: .leading, spacing: Constants.spacingM) {
                                Text(editingService == nil ? "Yeni Hizmet Ekle" : "Hizmeti Düzenle")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.themeSecondaryText)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Hizmet Başlığı")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    TextField("Örn: Kombi Bakımı", text: $viewModel.title)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Açıklama")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    TextEditor(text: $viewModel.description)
                                        .frame(height: 85)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.themeBorder, lineWidth: 1)
                                        )
                                }
                                
                                Picker("Fiyat Tipi", selection: $viewModel.pricingType) {
                                    Text("Saatlik").tag(ExpertService.PricingType.hourly)
                                    Text("Proje Bazlı").tag(ExpertService.PricingType.fixed)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                
                                HStack(spacing: Constants.spacingM) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Fiyat (₺)")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                        TextField("Fiyat", text: $viewModel.price)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Süre (Dakika)")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                        TextField("Süre", text: $viewModel.duration)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                }
                                
                                // Images Picker
                                VStack(alignment: .leading, spacing: Constants.spacingS) {
                                    Text("Hizmet Görselleri")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    
                                    PhotosPicker(selection: $imageItems, maxSelectionCount: 5, matching: .images) {
                                        HStack {
                                            Image(systemName: "photo.stack")
                                            Text("Görsel Seç (\(viewModel.selectedImagesData.count)/5)")
                                        }
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.themePrimary.opacity(0.12))
                                        .foregroundColor(Color.themePrimary)
                                        .clipShape(Capsule())
                                    }
                                }
                                
                                Toggle("Hizmeti Aktifleştir", isOn: $viewModel.isActive)
                                    .tint(Color.themePrimary)
                                    .font(.subheadline)
                                    .padding(.vertical, 4)
                                
                                Button {
                                    Task {
                                        if let existing = editingService {
                                            await viewModel.updateService(id: existing.id)
                                        } else {
                                            await viewModel.addService()
                                        }
                                        showingAddEditSheet = false
                                    }
                                } label: {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(editingService == nil ? "Ekle" : "Değişiklikleri Kaydet")
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
            .navigationTitle(editingService == nil ? "Yeni Hizmet" : "Hizmet Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        showingAddEditSheet = false
                    }
                }
            }
            .onChange(of: imageItems) { _, items in
                Task {
                    var dataArray: [Data] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            dataArray.append(data)
                        }
                    }
                    viewModel.selectedImagesData = dataArray
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
    NavigationStack {
        ProviderServicesView()
    }
}
