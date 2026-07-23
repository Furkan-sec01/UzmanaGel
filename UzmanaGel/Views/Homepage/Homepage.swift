import SwiftUI
import FirebaseAuth
import FirebaseFirestore
struct Homepage: View {
    
    @EnvironmentObject var session: SessionViewModel
    @StateObject private var vm = HomepageViewModel()
    @ObservedObject private var langManager = LanguageManager.shared
    
    @State private var showMenu = false
    @State private var showFilter = false
    @State private var showProfilePage = false
    @State private var showLocationPicker = false
    @State private var showMessagesPage = false
    @State private var showSettingsPage = false
    @State private var showReservationsPage = false
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
                                    Text("Konumunuz".localized)
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
                                
                                TextField("Hizmet, uzman veya kategori ara…".localized, text: $vm.searchText)
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
                                Text("\(vm.filter.activeFilterCount) Filtre Aktif".localized)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color("PrimaryColor"))
                                Spacer()
                                Button("Temizle".localized) {
                                #if os(iOS)
                                    UISelectionFeedbackGenerator().selectionChanged()
                                #endif
                                    withAnimation {
                                        vm.filter.reset()
                                    }
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.red)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color("PrimaryColor").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                                    .onAppear {
                                        /// Load the next page near the end
                                        let services = vm.filteredServices
                                        
                                        guard let lastService = services.last else {
                                            return
                                        }
                                        
                                        if item.serviceId == lastService.serviceId {
                                            vm.loadNextPage()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                if vm.isLoadingNextPage {
                                    HStack {
                                        Spacer()
                                        
                                        ProgressView()
                                            .padding(.vertical, 16)
                                        
                                        Spacer()
                                    }
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
                        Button {
                        #if os(iOS)
                            UISelectionFeedbackGenerator().selectionChanged()
                        #endif
                            showFilter = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: vm.filter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(vm.filter.isActive ? Color("PrimaryColor") : .white)

                                if vm.filter.activeFilterCount > 0 {
                                    Text("\(vm.filter.activeFilterCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 16, height: 16)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 6, y: -6)
                                }
                            }
                        }
                    }
                }
                .sheet(isPresented: $showMenu) {
                    SideMenuSheet(
                        onSignOut: {
                            session.signOut()
                        },
                        onMessagesTap: {
                            showMenu = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                showMessagesPage = true
                            }
                        },
                        onSettingsTap: {
                            showMenu = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                showSettingsPage = true
                            }
                        },
                        onProfileTap: {
                            showMenu = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                showProfilePage = true
                            }
                        },
                        onHomeTap: {
                            showMenu = false
                        },
                        onReservationsTap: {
                            showMenu = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                showReservationsPage = true
                            }
                        }
                    )
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
                }
                .navigationDestination(isPresented: $showProfilePage) {
                    ProfilePage()
                }
                .navigationDestination(isPresented: $showMessagesPage) {
                    MessagesPage()
                }
                .navigationDestination(isPresented: $showSettingsPage) {
                    SettingsPage()
                }
                .navigationDestination(isPresented: $showReservationsPage) {
                    MyReservationsPage()
                }
                .sheet(isPresented: $showFilter) {
                    FilterSheet(
                        filter: $vm.filter,
                        categories: vm.availableCategories,
                        locationManager: vm.locationManager,
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

}
