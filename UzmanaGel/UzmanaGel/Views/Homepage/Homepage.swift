import SwiftUI

struct Homepage: View {

    @EnvironmentObject var session: SessionViewModel
    @StateObject private var vm = HomepageViewModel()

    @State private var showMenu = false
    @State private var showFilter = false
    @State private var showProfilePage = false
    @State private var showLocationPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        Button { showLocationPicker = true } label: {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Konumunuz")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 4) {
                                        Text(vm.selectedLocation)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)

                                        if vm.locationManager.isLoading {
                                            ProgressView()
                                                .scaleEffect(0.6)
                                        }
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color("CardBackground"))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)

                        // MARK: - Arama Çubuğu
                        HStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)

                                TextField("Hizmet, uzman veya kategori ara…", text: $vm.searchText)
                                    .font(.system(size: 14))
                                    .autocorrectionDisabled()

                                if !vm.searchText.isEmpty {
                                    Button {
                                        vm.searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 15))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(10)
                            .background(Color("CardBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            // Mikrofon butonu
                            Button {
                                vm.speechRecognizer.toggleListening()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(vm.speechRecognizer.isListening
                                              ? Color.red
                                              : Color("PrimaryColor"))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: vm.speechRecognizer.isListening
                                          ? "waveform"
                                          : "mic.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .symbolEffect(.variableColor.iterative,
                                                       isActive: vm.speechRecognizer.isListening)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)

                        if let error = vm.errorMessage {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 28))
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("Tekrar Dene") {
                                    vm.clearError()
                                    vm.load()
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color("PrimaryColor"))
                            }
                            .padding()
                        } else if !vm.isLoading && vm.filteredServices.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: vm.searchText.isEmpty ? "tray" : "magnifyingglass")
                                    .font(.system(size: 28))
                                    .foregroundColor(.secondary)
                                Text(vm.searchText.isEmpty
                                     ? "Henüz hizmet bulunamadı"
                                     : "\"\(vm.searchText)\" için sonuç bulunamadı")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 40)
                            .padding(.horizontal, 32)
                        }

                        if vm.filter.isActive {
                            HStack {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .foregroundColor(Color("PrimaryColor"))
                                Text("Filtre aktif")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color("PrimaryColor"))
                                Spacer()
                                Button("Temizle") {
                                    vm.filter.reset()
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.red)
                            }
                            .padding(.horizontal, 16)
                        }

                        LazyVStack(spacing: 16) {
                            ForEach(vm.filteredServices) { item in
                                NavigationLink {
                                    ServiceDetailPage(
                                        service: item,
                                        imageURL: vm.imageURLs[item.serviceId],
                                        isFavorite: vm.isFavorite(serviceId: item.serviceId)
                                    )
                                } label: {
                                    ServiceCard(
                                        service: item,
                                        distanceText: vm.distanceText(for: item),
                                        imageURL: vm.imageURLs[item.serviceId],
                                        isFavorite: vm.isFavorite(serviceId: item.serviceId),
                                        onToggleFavorite: {
                                            vm.toggleFavorite(serviceId: item.serviceId)
                                        }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                }

                if vm.isLoading {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
            .task {
                vm.load()
            }
            .refreshable {
                vm.load()
            }
            .toolbarBackground(Color("PrimaryColor"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showMenu = true } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
            }
            .sheet(isPresented: $showMenu) {
                SideMenuSheet(
                    onSignOut: { session.signOut() },
                    onProfileTap: {
                        showMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showProfilePage = true
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .navigationDestination(isPresented: $showProfilePage) {
                ProfilePage()
            }
            .sheet(isPresented: $showFilter) {
                FilterSheet(
                    filter: $vm.filter,
                    categories: vm.availableCategories,
                    onApply: { showFilter = false }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerSheet(
                    locationManager: vm.locationManager,
                    onDismiss: { showLocationPicker = false }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}
