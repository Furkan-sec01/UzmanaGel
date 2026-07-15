import SwiftUI
import PhotosUI

struct PortfolioView: View {
    @StateObject private var viewModel = PortfolioViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var uploadDescription = ""
    @State private var showUploadForm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView(message: "Portfolyo yükleniyor...")
                } else if viewModel.portfolioItems.isEmpty {
                    EmptyStateView(
                        iconName: "photo.on.rectangle.angled",
                        title: "Galeri Henüz Boş",
                        message: "Yaptığınız işlerden fotoğraflar ekleyerek müşterilere kalitenizi gösterin.",
                        buttonTitle: "Fotoğraf Ekle"
                    ) {
                        showUploadForm = true
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Constants.spacingM) {
                            Text("Sürükleyip bırakarak fotoğrafların sırasını değiştirebilirsiniz.")
                                .font(.caption)
                                .foregroundColor(Color.themeSecondaryText)
                                .padding(.horizontal)
                                .padding(.top, Constants.paddingS)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(viewModel.portfolioItems) { item in
                                    portfolioCell(item)
                                        .onDrag {
                                            NSItemProvider(object: item.id as NSString)
                                        }
                                        .onDrop(of: [.text], delegate: PortfolioDropDelegate(item: item, viewModel: viewModel))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, Constants.paddingXL)
                    }
                }
                
                // Toast overlays
                if let success = viewModel.successMessage {
                    toastOverlay(message: success)
                }
            }
            .navigationTitle("Portfolyo Galerisi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.resetForm()
                        showUploadForm = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.themePrimary)
                    }
                }
            }
            // Fullscreen photo viewer sheet
            .fullScreenCover(item: $viewModel.fullscreenItem) { item in
                fullscreenViewer(item)
            }
            // Upload Form dialog sheet
            .sheet(isPresented: $showUploadForm) {
                uploadPhotoSheet
            }
            .task {
                await viewModel.loadPortfolio()
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func portfolioCell(_ item: PortfolioItem) -> some View {
        CardView(cornerRadius: Constants.radiusM, shadowRadius: Constants.shadowRadiusS) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: item.imageUrl)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.themeSecondaryText.opacity(0.1).shimmer()
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: Constants.radiusS))
                
                Text(item.description)
                    .font(.caption2)
                    .foregroundColor(Color.themeText)
                    .lineLimit(2)
                    .frame(height: 28)
                
                Button {
                    viewModel.fullscreenItem = item
                } label: {
                    Text("Görüntüle")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.themePrimary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var uploadPhotoSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Constants.spacingM) {
                        CardView {
                            VStack(alignment: .leading, spacing: Constants.spacingM) {
                                Text("Fotoğraf Detayları")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.themeSecondaryText)
                                
                                PhotosPicker(selection: $selectedItems, maxSelectionCount: 3, matching: .images) {
                                    HStack {
                                        Image(systemName: "photo.stack")
                                        Text("Fotoğraf Seç (\(selectedItems.count) adet)")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.themePrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Açıklama (Müşterilere Gösterilecek)")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    TextField("Yaptığınız işi kısaca tanımlayın", text: $uploadDescription)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                Button {
                                    if let item = selectedItems.first {
                                        Task {
                                            if let data = try? await item.loadTransferable(type: Data.self) {
                                                viewModel.addPortfolioItem(description: uploadDescription, imageData: data)
                                                showUploadForm = false
                                                selectedItems = []
                                                uploadDescription = ""
                                            }
                                        }
                                    }
                                } label: {
                                    Text("Galeriye Ekle")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.themeSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(selectedItems.isEmpty)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Yeni Fotoğraf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        showUploadForm = false
                        selectedItems = []
                        uploadDescription = ""
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func fullscreenViewer(_ item: PortfolioItem) -> some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    AsyncImage(url: URL(string: item.imageUrl)) { img in
                        img.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView().tint(.white)
                    }
                    .frame(maxHeight: 400)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.description)
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Text("Yükleme: " + dateString(for: item.createdAt))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    .padding()
                    
                    Spacer()
                    
                    HStack(spacing: 40) {
                        Button {
                            viewModel.showCropFilterSimulator = true
                        } label: {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                Text("Filtre / Kırp")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Capsule())
                        }
                        
                        Button {
                            viewModel.deleteItem(id: item.id)
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Fotoğrafı Sil")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Portfolyo Detay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        viewModel.fullscreenItem = nil
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $viewModel.showCropFilterSimulator) {
                cropFilterSimulatorSheet
            }
        }
    }
    
    private var cropFilterSimulatorSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Görsel Filtre & Kırpma Simülasyonu")
                    .font(.headline)
                    .padding(.top)
                
                Spacer()
                
                // Show simple filters selector
                HStack(spacing: 15) {
                    filterButton(name: "Orijinal", icon: "photo")
                    filterButton(name: "Siyah Beyaz", icon: "photo.fill")
                    filterButton(name: "Sıcak Ton", icon: "sun.max.fill")
                }
                
                Spacer()
                
                Button("Filtreyi Uygula ve Kaydet") {
                    viewModel.showCropFilterSimulator = false
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.themePrimary)
                .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                .padding()
            }
            .navigationTitle("Filtre / Kırp")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.themeBackground)
        }
    }
    
    @ViewBuilder
    private func filterButton(name: String, icon: String) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(Color.themePrimary)
            Text(name)
                .font(.caption)
        }
        .padding()
        .background(Color.themeCardBackground)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.themeBorder, lineWidth: 1))
    }
    
    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
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

// MARK: - Drop Delegate for Reordering
struct PortfolioDropDelegate: DropDelegate {
    let item: PortfolioItem
    let viewModel: PortfolioViewModel
    
    func performDrop(info: DropInfo) -> Bool {
        viewModel.dragOverId = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let provider = info.itemProviders(for: [.text]).first else { return }
        provider.loadObject(ofClass: NSString.self) { idString, _ in
            if let sourceId = idString as? String {
                DispatchQueue.main.async {
                    viewModel.moveItem(from: sourceId, to: item.id)
                }
            }
        }
    }
}

#Preview {
    PortfolioView()
}
