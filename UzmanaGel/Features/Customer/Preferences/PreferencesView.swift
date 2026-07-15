import SwiftUI

struct PreferencesView: View {
    @StateObject private var viewModel = PreferencesViewModel()
    @ObservedObject private var langManager = LanguageManager.shared
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            if viewModel.isLoading {
                LoadingView(message: "Tercihleriniz yükleniyor...".localized)
            } else {
                ScrollView {
                    VStack(spacing: Constants.spacingL) {
                        
                        // 1. Notification Settings
                        VStack(alignment: .leading, spacing: Constants.spacingS) {
                            Text("Bildirim Ayarları".localized)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themeSecondaryText)
                                .padding(.horizontal, Constants.paddingL)
                            
                            CardView {
                                VStack(spacing: Constants.spacingM) {
                                    Toggle("Anlık Bildirimler (Push)".localized, isOn: $viewModel.pushNotificationsEnabled)
                                        .tint(Color.themePrimary)
                                    Divider()
                                    Toggle("E-posta Bildirimleri".localized, isOn: $viewModel.emailNotificationsEnabled)
                                        .tint(Color.themePrimary)
                                    Divider()
                                    Toggle("SMS Bildirimleri".localized, isOn: $viewModel.smsNotificationsEnabled)
                                        .tint(Color.themePrimary)
                                    
                                    Group {
                                        Divider()
                                        Toggle("Rezervasyon Güncellemeleri".localized, isOn: $viewModel.bookingNotificationsEnabled)
                                            .tint(Color.themePrimary)
                                        Divider()
                                        Toggle("Kampanya ve Tanıtımlar".localized, isOn: $viewModel.promoNotificationsEnabled)
                                            .tint(Color.themePrimary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // 2. Appearance settings
                        VStack(alignment: .leading, spacing: Constants.spacingS) {
                            Text("Görünüm Ayarları".localized)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themeSecondaryText)
                                .padding(.horizontal, Constants.paddingL)
                            
                            CardView {
                                VStack(alignment: .leading, spacing: Constants.spacingM) {
                                    Text("Uygulama Teması".localized)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Picker("Tema Seçimi".localized, selection: $viewModel.themeSelection) {
                                        ForEach(AppTheme.allCases, id: \.self) { theme in
                                            Text(theme.rawValue.localized).tag(theme)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .onChange(of: viewModel.themeSelection) { _, newTheme in
                                        viewModel.applyTheme(newTheme)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // 3. Language settings
                        VStack(alignment: .leading, spacing: Constants.spacingS) {
                            Text("Dil Ayarları".localized)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themeSecondaryText)
                                .padding(.horizontal, Constants.paddingL)
                            
                            CardView {
                                HStack {
                                    Text("Uygulama Dili".localized)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Picker("Dil".localized, selection: $viewModel.selectedLanguage) {
                                        ForEach(Language.allCases, id: \.self) { lang in
                                            Text(lang.displayName).tag(lang)
                                        }
                                    }
                                    .onChange(of: viewModel.selectedLanguage) { _, _ in
                                        viewModel.triggerLanguageAlert()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // 4. Privacy Settings
                        VStack(alignment: .leading, spacing: Constants.spacingS) {
                            Text("Gizlilik Ayarları".localized)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themeSecondaryText)
                                .padding(.horizontal, Constants.paddingL)
                            
                            CardView {
                                VStack(spacing: Constants.spacingM) {
                                    Toggle("Konum Paylaşımı".localized, isOn: $viewModel.locationSharingEnabled)
                                        .tint(Color.themePrimary)
                                    Divider()
                                    Toggle("Profil Görünürlüğü (Herkese Açık)".localized, isOn: $viewModel.profileVisibilityPublic)
                                        .tint(Color.themePrimary)
                                    Divider()
                                    Toggle("Kullanım Verisi Analiz İzni".localized, isOn: $viewModel.dataCollectionConsent)
                                        .tint(Color.themePrimary)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Save Button
                        Button {
                            Task {
                                await viewModel.savePreferences()
                            }
                        } label: {
                            Text("Ayarları Kaydet".localized)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.themePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            
            if let success = viewModel.successMessage {
                toastOverlay(message: success.localized)
            }
        }
        .navigationTitle("Tercihler".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPreferences()
        }
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
    NavigationStack {
        PreferencesView()
    }
}
