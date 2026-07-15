import SwiftUI

struct CustomerProfileView: View {
    @StateObject private var viewModel = CustomerProfileViewModel()
    @State private var showingEditProfile = false
    @ObservedObject private var langManager = LanguageManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView(message: "Profil yükleniyor...")
                } else if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        Task { await viewModel.loadProfile() }
                    }
                } else if let profile = viewModel.userProfile {
                    ScrollView {
                        VStack(spacing: Constants.spacingL) {
                            // Header Card
                            headerCard(profile: profile)
                                .padding(.horizontal)
                            
                            // Menu Sections
                            VStack(spacing: Constants.spacingM) {
                                menuGroup(title: "Hesap Bilgileri".localized) {
                                    NavigationLink {
                                        EditProfileView(profile: profile) { updatedProfile in
                                            viewModel.userProfile = updatedProfile
                                        }
                                    } label: {
                                        menuRow(icon: "person.text.rectangle", title: "Kişisel Bilgiler".localized, subtitle: "Bilgilerinizi ve şifrenizi güncelleyin".localized)
                                    }
                                    
                                    NavigationLink {
                                        CustomerAddressListView()
                                    } label: {
                                        menuRow(icon: "mappin.and.ellipse", title: "Adreslerim".localized, subtitle: "Kayıtlı teslimat adresleri".localized)
                                    }
                                    
                                    NavigationLink {
                                        PaymentMethodsView()
                                    } label: {
                                        menuRow(icon: "creditcard", title: "Ödeme Yöntemlerim".localized, subtitle: "Kayıtlı kartlarınız ve Apple Pay".localized)
                                    }
                                }
                                
                                menuGroup(title: "Ayarlar ve Tercihler".localized) {
                                    NavigationLink {
                                        PreferencesView()
                                    } label: {
                                        menuRow(icon: "sliders.horizontal.3", title: "Tercihler".localized, subtitle: "Bildirim, tema ve dil ayarları".localized)
                                    }
                                    
                                    NavigationLink {
                                        HistoryFavoritesView()
                                    } label: {
                                        menuRow(icon: "clock.arrow.circlepath", title: "Geçmiş ve Favoriler".localized, subtitle: "Geçmiş siparişleriniz ve favori ustalar".localized)
                                    }
                                }
                                
                                menuGroup(title: "Yardım".localized) {
                                    NavigationLink {
                                        Text("Destek ve Yardım Ekranı".localized)
                                            .font(.headline)
                                    } label: {
                                        menuRow(icon: "questionmark.circle", title: "Destek".localized, subtitle: "Yardım merkezi ve müşteri hizmetleri".localized)
                                    }
                                }
                                
                                // Logout Button
                                Button {
                                    withAnimation {
                                        viewModel.logout()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .foregroundColor(Color.themeError)
                                        Text("Çıkış Yap")
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color.themeError)
                                        Spacer()
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .glassmorphic(cornerRadius: Constants.radiusM)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                } else {
                    EmptyStateView(iconName: "person.crop.circle.badge.exclamationmark", title: "Profil Bulunamadı", message: "Profil bilgilerinizi yükleyemedik. Lütfen tekrar giriş yapın.") {
                        Task { await viewModel.loadProfile() }
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadProfile()
            }
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func headerCard(profile: UserProfile) -> some View {
        CardView(cornerRadius: Constants.radiusXL, shadowRadius: Constants.shadowRadiusM) {
            VStack(spacing: Constants.spacingM) {
                HStack(spacing: Constants.spacingM) {
                    AvatarView(imageURLString: profile.photoURL, size: 76, isEditable: false)
                    
                    VStack(alignment: .leading, spacing: Constants.spacingXS) {
                        Text(profile.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color.themeText)
                        
                        Text(profile.email)
                            .font(.footnote)
                            .foregroundColor(Color.themeSecondaryText)
                        
                        if let phone = profile.phoneNumber {
                            Text(phone)
                                .font(.footnote)
                                .foregroundColor(Color.themeSecondaryText)
                        }
                    }
                    Spacer()
                }
                
                Divider()
                    .background(Color.themeBorder)
                
                HStack {
                    HStack(spacing: Constants.spacingXS) {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                            .foregroundColor(Color.themePrimary)
                        Text("Üyelik Süresi:")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                        BadgeView(text: viewModel.membershipDurationText, style: .primary)
                    }
                    Spacer()
                    
                    NavigationLink {
                        EditProfileView(profile: profile) { updatedProfile in
                            viewModel.userProfile = updatedProfile
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Düzenle")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.themePrimary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    @ViewBuilder
    private func menuGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Constants.spacingS) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color.themeSecondaryText)
                .padding(.horizontal, Constants.paddingL)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color.themeCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Constants.radiusL))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.radiusL)
                    .stroke(Color.themeBorder, lineWidth: 1)
            )
            .padding(.horizontal)
            .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
        }
    }
    
    @ViewBuilder
    private func menuRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Constants.spacingM) {
            ZStack {
                Circle()
                    .fill(Color.themePrimary.opacity(0.08))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.themePrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themeText)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Color.themeSecondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color.themeSecondaryText.opacity(0.7))
        }
        .padding()
        .contentShape(Rectangle())
    }
}

#Preview {
    CustomerProfileView()
}
