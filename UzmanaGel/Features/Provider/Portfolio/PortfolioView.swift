import SwiftUI
import PhotosUI

@MainActor
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
                        title: "Gallery is Empty",
                        message: "Show your quality to customers by adding photos of your work.",
                        buttonTitle: "Add Photo"
                    ) {
                        showUploadForm = true
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Constants.spacingM) {
                            Text("You can change the order of photos by dragging and dropping.")
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
                
                // Upload yükleme spinner overlay
                if viewModel.isUploading {
                    ZStack {
                        Color.black.opacity(0.35).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.4)
                                .tint(.white)
                            Text("Fotoğraf yükleniyor...")
                                .font(.callout)
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        }
                        .padding(32)
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                
                // Toast overlays
                if let success = viewModel.successMessage {
                    toastOverlay(message: success)
                }
                if let error = viewModel.errorMessage {
                    toastOverlay(message: error, isError: true)
                }
            }
            .navigationTitle("Portfolio Gallery")
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
                Color.clear
                    .frame(height: 120)
                    .overlay(
                        AsyncImage(url: URL(string: item.imageUrl)) { img in
                            img
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.themeSecondaryText.opacity(0.1).shimmer()
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Constants.radiusS))
                
                Text(item.description)
                    .font(.caption2)
                    .foregroundColor(Color.themeText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 32, alignment: .topLeading)
                
                Spacer(minLength: 0)
                
                Button {
                    viewModel.fullscreenItem = item
                } label: {
                    Text("View")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.themePrimary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(height: 200, alignment: .top)
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
                                Text("Photo Details")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.themeSecondaryText)
                                
                                PhotosPicker(selection: $selectedItems, maxSelectionCount: 3, matching: .images) {
                                    HStack {
                                        Image(systemName: "photo.stack")
                                        Text("Select Photo (\(selectedItems.count) items)")
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
                                    Text("Description (Visible to Customers)")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    TextField("Briefly describe the work you did", text: $uploadDescription)
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
                                    Text("Add to Gallery")
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
            .navigationTitle("New Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
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
                        
                        Text("Uploaded: " + dateString(for: item.createdAt))
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
                                Text("Filter / Crop")
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
                                Text("Delete Photo")
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
            .navigationTitle("Portfolio Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
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
                Text("Image Filter & Cropping Simulation")
                    .font(.headline)
                    .padding(.top)
                
                Spacer()
                
                // Show simple filters selector
                HStack(spacing: 15) {
                    filterButton(name: "Original", icon: "photo")
                    filterButton(name: "Black & White", icon: "photo.fill")
                    filterButton(name: "Warm Tone", icon: "sun.max.fill")
                }
                
                Spacer()
                
                Button("Apply Filter and Save") {
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
            .navigationTitle("Filter / Crop")
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
    private func toastOverlay(message: String, isError: Bool = false) -> some View {
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
