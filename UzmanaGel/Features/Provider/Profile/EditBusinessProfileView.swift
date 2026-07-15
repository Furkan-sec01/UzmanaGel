import SwiftUI
import PhotosUI

struct EditBusinessProfileView: View {
    @StateObject private var viewModel = EditBusinessProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var logoItem: PhotosPickerItem? = nil
    @State private var coverItem: PhotosPickerItem? = nil
    @State private var isAddingCategory = false
    
    let availableCategories = ["Temizlik", "Tesisatçı", "Elektrikçi", "Boya & Badana", "Marangoz", "Nakliyat", "Bahçe Bakım"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.spacingL) {
                        
                        // 1. Cover & Logo Header Section
                        headerPhotosSection
                        
                        // 2. Certification Status Box
                        certificationStatusBox
                            .padding(.horizontal)
                        
                        // 3. Business Info Form
                        CardView {
                            VStack(alignment: .leading, spacing: Constants.spacingM) {
                                Text("İşletme Bilgileri")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.themeSecondaryText)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("İşletme Adı")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    TextField("İşletme Adı", text: $viewModel.businessName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // Category Badge selection
                                VStack(alignment: .leading, spacing: Constants.spacingS) {
                                    HStack {
                                        Text("Hizmet Kategorileri")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                        Spacer()
                                        Button {
                                            isAddingCategory = true
                                        } label: {
                                            Text("+ Ekle")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(Color.themePrimary)
                                        }
                                    }
                                    
                                    HStack(spacing: 8) {
                                        ForEach(viewModel.selectedCategories, id: \.self) { cat in
                                            HStack(spacing: 4) {
                                                Text(cat)
                                                Button {
                                                    viewModel.removeCategory(cat)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(Color.themeSecondaryText)
                                                }
                                            }
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.themePrimary.opacity(0.12))
                                            .foregroundColor(Color.themePrimary)
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                                
                                // Description with character limit
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("İşletme Açıklaması")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                        Spacer()
                                        Text("\(viewModel.description.count)/\(viewModel.descriptionLimit)")
                                            .font(.caption2)
                                            .foregroundColor(viewModel.description.count >= viewModel.descriptionLimit ? Color.themeError : Color.themeSecondaryText)
                                    }
                                    
                                    TextEditor(text: $viewModel.description)
                                        .frame(height: 100)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.themeBorder, lineWidth: 1)
                                        )
                                        .onChange(of: viewModel.description) { _, _ in
                                            viewModel.enforceDescriptionLimit()
                                        }
                                }
                                
                                Button {
                                    Task {
                                        await viewModel.saveBusinessProfile()
                                    }
                                } label: {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Değişiklikleri Kaydet")
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
                        .padding(.horizontal)
                    }
                    .padding(.bottom, Constants.paddingXL)
                }
                
                // Toast overlays
                if let success = viewModel.successMessage {
                    toastOverlay(message: success, isError: false)
                }
                if let error = viewModel.errorMessage {
                    toastOverlay(message: error, isError: true)
                }
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isAddingCategory) {
                categorySelectionSheet
            }
            .onChange(of: logoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        viewModel.selectedLogoData = data
                    }
                }
            }
            .onChange(of: coverItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        viewModel.selectedCoverData = data
                    }
                }
            }
            .task {
                await viewModel.loadBusinessInfo()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerPhotosSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                // Cover Image Area
                Group {
                    if let coverData = viewModel.selectedCoverData, let uiImage = UIImage(data: coverData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else if let cover = viewModel.coverUrl, let url = URL(string: cover) {
                        AsyncImage(url: url) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Color.themeSecondaryText.opacity(0.15)
                        }
                    } else {
                        Color.themeSecondaryText.opacity(0.2)
                    }
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(
                    PhotosPicker(selection: $coverItem, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 32, height: 32)
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    }
                    .padding(8),
                    alignment: .topTrailing
                )
                
                // Business Logo (circular, overlaps cover)
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let logoData = viewModel.selectedLogoData, let uiImage = UIImage(data: logoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else if let logo = viewModel.logoUrl, let url = URL(string: logo) {
                            AsyncImage(url: url) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Color.white.shimmer()
                            }
                        } else {
                            ZStack {
                                Color.white
                                Image(systemName: "briefcase.fill")
                                    .font(.title3)
                                    .foregroundColor(Color.themeSecondaryText)
                            }
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 3.0))
                    .shadow(radius: 5)
                    
                    PhotosPicker(selection: $logoItem, matching: .images) {
                        Image(systemName: "pencil.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .symbolRenderingMode(.multicolor)
                            .background(Color.white.clipShape(Circle()))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .offset(x: 16, y: 40)
            }
            .padding(.bottom, 45) // Push details below logo
        }
    }
    
    private var certificationStatusBox: some View {
        CardView(cornerRadius: Constants.radiusM, shadowRadius: Constants.shadowRadiusS) {
            VStack(alignment: .leading, spacing: Constants.spacingS) {
                HStack {
                    Image(systemName: viewModel.isCertified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(viewModel.isCertified ? Color.themeSuccess : Color.themeWarning)
                        .font(.title3)
                    
                    Text(viewModel.isCertified ? "Onaylı Hesap" : "Belge Onayı Bekliyor")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    BadgeView(
                        text: viewModel.isCertified ? "Verified" : "Pending",
                        style: viewModel.isCertified ? .success : .warning
                    )
                }
                
                if !viewModel.isCertified {
                    Text("Uygulamada ilan verebilmek için kimlik ve yetkinlik belgelerinizi tamamlamanız gerekmektedir. Eksik belgeler:")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.missingDocuments, id: \.self) { doc in
                            HStack(spacing: 6) {
                                Image(systemName: "doc.plaintext.fill")
                                    .font(.caption2)
                                    .foregroundColor(Color.themeError)
                                Text(doc)
                                    .font(.caption)
                                    .foregroundColor(Color.themeText)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
    
    private var categorySelectionSheet: some View {
        NavigationStack {
            List(availableCategories, id: \.self) { cat in
                Button {
                    viewModel.addCategory(cat)
                    isAddingCategory = false
                } label: {
                    HStack {
                        Text(cat)
                            .foregroundColor(Color.themeText)
                        Spacer()
                        if viewModel.selectedCategories.contains(cat) {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.themePrimary)
                        }
                    }
                }
            }
            .navigationTitle("Kategori Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        isAddingCategory = false
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
    EditBusinessProfileView()
}
