//
//  SettingsPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//

import SwiftUI
import UIKit
import AuthenticationServices

@MainActor
struct SettingsPage: View {

    @EnvironmentObject private var session: SessionViewModel

    @AppStorage("notificationEnabled")
    private var notificationEnabled = true

    @ObservedObject private var langManager = LanguageManager.shared

    @AppStorage("selectedAppearance")
    private var selectedAppearance = "system"

    @AppStorage("pref_theme")
    private var savedTheme = "system"

    @AppStorage("pref_language")
    private var selectedLanguageCode = "tr"

    @State private var hasReadKVKK = false
    @State private var deleteAlert: DeleteAlert?
    @State private var showAccountDeletionSheet = false

    // Theme colors
    private let bgColor = Color("BackgroundColor")
    private let cardColor = Color("CardBackground")
    private let accentYellow = Color("TertiaryColor")

    private enum DeleteAlert: Identifiable {
        case firstConfirmation
        case finalConfirmation

        var id: Int {
            switch self {
            case .firstConfirmation:
                return 1

            case .finalConfirmation:
                return 2
            }
        }
    }

    var body: some View {
        ZStack {
            bgColor
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    appSection
                    privacySection
                    accountSection
                    supportSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Ayarlar".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $deleteAlert) { alert in
            switch alert {
            case .firstConfirmation:
                return Alert(
                    title: Text("Hesabımı Sil"),
                    message: Text(
                        "Hesabınızı silmek istediğinizden emin misiniz?"
                    ),
                    primaryButton: .destructive(
                        Text("Devam Et")
                    ) {
                        showAlertAfterDismiss(
                            .finalConfirmation
                        )
                    },
                    secondaryButton: .cancel(
                        Text("Vazgeç")
                    )
                )

            case .finalConfirmation:
                return Alert(
                    title: Text("Son Onay"),
                    message: Text(
                        "Hesabınız ve size ait kişisel veriler kalıcı olarak silinecektir. Bu işlem geri alınamaz."
                    ),
                    primaryButton: .destructive(
                        Text("Hesabı Sil")
                    ) {
                        showDeletionSheetAfterDismiss()
                    },
                    secondaryButton: .cancel(
                        Text("Vazgeç")
                    )
                )
            }
        }
        .sheet(
            isPresented: $showAccountDeletionSheet
        ) {
            AccountDeletionSheet()
                .environmentObject(session)
        }
    }

    // MARK: - App Section

    private var appSection: some View {
        sectionCard(
            title: "Uygulama",
            icon: "gearshape.fill",
            iconColor: .blue
        ) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    iconBox(
                        "bell.fill",
                        tint: .orange
                    )

                    Text("Bildirimler".localized)
                        .font(
                            .system(
                                size: 15,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(.primary)

                    Spacer()

                    Toggle(
                        "",
                        isOn: $notificationEnabled
                    )
                    .tint(accentYellow)
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                customDivider()

                NavigationLink {
                    NotificationPreferencesPage()
                } label: {
                    navigationRowContent(
                        title: "Bildirim Tercihleri".localized,
                        icon: "bell.badge.fill",
                        tint: .red
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        sectionCard(
            title: "Gizlilik",
            icon: "lock.shield.fill",
            iconColor: .purple
        ) {
            VStack(spacing: 0) {
                NavigationLink {
                    Kvkk(
                        hasRead: $hasReadKVKK,
                        showsAcceptance: false
                    )
                } label: {
                    navigationRowContent(
                        title: "KVKK ve Gizlilik".localized,
                        icon: "hand.raised.fill",
                        tint: .purple
                    )
                }
                .buttonStyle(.plain)

                customDivider()

                NavigationLink {
                    TermsOfServicePage()
                } label: {
                    navigationRowContent(
                        title: "Kullanım Şartları".localized,
                        icon: "doc.text.fill",
                        tint: .indigo
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        sectionCard(
            title: "Hesap",
            icon: "person.crop.circle.badge.exclamationmark",
            iconColor: .red
        ) {
            Button {
                deleteAlert = .firstConfirmation
            } label: {
                HStack(spacing: 12) {
                    iconBox(
                        "trash.fill",
                        tint: .red
                    )

                    Text("Hesabımı Sil")
                        .font(
                            .system(
                                size: 15,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(.red)

                    Spacer()

                    Image(
                        systemName: "chevron.right"
                    )
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        sectionCard(
            title: "Destek",
            icon: "questionmark.circle.fill",
            iconColor: .green
        ) {
            VStack(spacing: 0) {
                NavigationLink {
                    HelpPage()
                } label: {
                    navigationRowContent(
                        title: "Yardım".localized,
                        icon: "questionmark.circle.fill",
                        tint: .green
                    )
                }
                .buttonStyle(.plain)

                customDivider()

                NavigationLink {
                    AboutPage()
                } label: {
                    navigationRowContent(
                        title: "Hakkında".localized,
                        icon: "info.circle.fill",
                        tint: .teal
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Components

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(
                        .system(
                            size: 13,
                            weight: .bold
                        )
                    )
                    .foregroundColor(iconColor)

                Text(title.localized)
                    .font(
                        .system(
                            size: 14,
                            weight: .bold
                        )
                    )
                    .foregroundColor(.primary)
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(cardColor)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .stroke(
                    Color.primary.opacity(0.08),
                    lineWidth: 1
                )
            )
            .shadow(
                color: Color.black.opacity(0.06),
                radius: 10,
                x: 0,
                y: 4
            )
        }
    }

    private func navigationRowContent(
        title: String,
        icon: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 12) {
            iconBox(
                icon,
                tint: tint
            )

            Text(title)
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func iconBox(
        _ name: String,
        tint: Color
    ) -> some View {
        Image(systemName: name)
            .font(
                .system(
                    size: 14,
                    weight: .semibold
                )
            )
            .foregroundColor(tint)
            .frame(
                width: 34,
                height: 34
            )
            .background(
                tint.opacity(0.15)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
            )
    }

    private func customDivider() -> some View {
        Divider()
            .background(
                Color.primary.opacity(0.06)
            )
            .padding(.leading, 62)
    }

    private func showAlertAfterDismiss(
        _ alert: DeleteAlert
    ) {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.25
        ) {
            deleteAlert = alert
        }
    }

    private func showDeletionSheetAfterDismiss() {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.25
        ) {
            showAccountDeletionSheet = true
        }
    }
}

// MARK: - Account Deletion Sheet

@MainActor
private struct AccountDeletionSheet: View {

    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel =
        AccountDeletionViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 22) {
                        warningHeader
                        authenticationContent
                    }
                    .padding(20)
                }

                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("Hesabı Sil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .topBarLeading
                ) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .interactiveDismissDisabled(
            viewModel.isLoading
        )
        .onAppear {
            viewModel.refreshAuthenticationMethod()
        }
        .onChange(
            of: viewModel.didDeleteAccount
        ) { didDeleteAccount in
            if didDeleteAccount {
                dismiss()
            }
        }
        .alert(
            "İşlem Başarısız",
            isPresented: errorAlertBinding
        ) {
            Button("Tamam") {
                viewModel.clearError()
            }
        } message: {
            Text(
                viewModel.errorMessage ?? ""
            )
        }
    }

    private var warningHeader: some View {
        VStack(spacing: 14) {
            Image(
                systemName: "exclamationmark.triangle.fill"
            )
            .font(.system(size: 44))
            .foregroundColor(.red)

            Text("Hesabınızı doğrulayın")
                .font(.title3.bold())

            Text(
                "Güvenliğiniz için hesabınızı silmeden önce giriş yönteminizi tekrar doğrulamanız gerekiyor."
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

            Text(
                "Bu işlem geri alınamaz."
            )
            .font(.subheadline.bold())
            .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            Color.red.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }

    @ViewBuilder
    private var authenticationContent: some View {
        switch viewModel.authenticationMethod {
        case .apple:
            appleDeletionContent

        case .google:
            googleDeletionContent

        case .password:
            passwordDeletionContent

        case .phone:
            phoneDeletionContent

        case .unsupported:
            unsupportedContent
        }
    }

    private var appleDeletionContent: some View {
        VStack(spacing: 16) {
            providerInformation(
                icon: "applelogo",
                title: "Apple ile doğrulama",
                message: "Apple hesabınızla tekrar giriş yaparak hesap silme işlemini tamamlayın."
            )

            SignInWithAppleButton(
                .continue
            ) { request in
                viewModel.prepareAppleRequest(
                    request
                )
            } onCompletion: { result in
                viewModel.handleAppleCompletion(
                    result,
                    session: session
                )
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
            .disabled(viewModel.isLoading)
        }
    }

    private var googleDeletionContent: some View {
        VStack(spacing: 16) {
            providerInformation(
                icon: "g.circle.fill",
                title: "Google ile doğrulama",
                message: "Google hesabınızı tekrar seçerek hesap silme işlemini tamamlayın."
            )

            destructiveButton(
                title: "Google ile Doğrula ve Sil",
                icon: "g.circle.fill"
            ) {
                guard let controller =
                        presentingViewController()
                else {
                    viewModel.errorMessage =
                        "Google giriş ekranı açılamadı."
                    return
                }

                viewModel.deleteWithGoogle(
                    presenting: controller,
                    session: session
                )
            }
        }
    }

    private var passwordDeletionContent: some View {
        VStack(spacing: 16) {
            providerInformation(
                icon: "envelope.fill",
                title: "Şifre ile doğrulama",
                message: "Hesabınıza ait mevcut şifreyi girin."
            )

            SecureField(
                "Mevcut şifre",
                text: $viewModel.password
            )
            .textContentType(.password)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(
                Color.primary.opacity(0.06)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )

            destructiveButton(
                title: "Şifreyi Doğrula ve Sil",
                icon: "trash.fill"
            ) {
                viewModel.deleteWithPassword(
                    session: session
                )
            }
        }
    }

    private var phoneDeletionContent: some View {
        VStack(spacing: 16) {
            providerInformation(
                icon: "phone.fill",
                title: "Telefon ile doğrulama",
                message: "Hesabınıza kayıtlı telefon numarasına doğrulama kodu gönderilecektir."
            )

            Button {
                viewModel.sendPhoneCode()
            } label: {
                HStack {
                    Image(
                        systemName: "message.fill"
                    )

                    Text(
                        viewModel.isPhoneCodeSent
                        ? "Kodu Tekrar Gönder"
                        : "SMS Kodu Gönder"
                    )
                    .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    Color.blue.opacity(0.12)
                )
                .foregroundColor(.blue)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)

            if viewModel.isPhoneCodeSent {
                TextField(
                    "SMS doğrulama kodu",
                    text: $viewModel.phoneCode
                )
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(
                    Color.primary.opacity(0.06)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )

                destructiveButton(
                    title: "Kodu Doğrula ve Sil",
                    icon: "trash.fill"
                ) {
                    viewModel.deleteWithPhoneCode(
                        session: session
                    )
                }
            }
        }
    }

    private var unsupportedContent: some View {
        VStack(spacing: 14) {
            Image(
                systemName: "person.crop.circle.badge.questionmark"
            )
            .font(.system(size: 38))
            .foregroundColor(.orange)

            Text("Giriş yöntemi bulunamadı")
                .font(.headline)

            Text(
                "Bu hesabın yeniden doğrulama yöntemi belirlenemedi. Çıkış yapıp tekrar giriş yaptıktan sonra yeniden deneyin."
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(20)
    }

    private func providerInformation(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 14
        ) {
            Image(systemName: icon)
                .font(
                    .system(
                        size: 22,
                        weight: .semibold
                    )
                )
                .foregroundColor(.primary)
                .frame(
                    width: 44,
                    height: 44
                )
                .background(
                    Color.primary.opacity(0.07)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func destructiveButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            action: action
        ) {
            HStack(spacing: 8) {
                Image(systemName: icon)

                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundColor(.white)
            .background(Color.red)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
        .opacity(
            viewModel.isLoading ? 0.6 : 1
        )
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black
                .opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)

                Text("Hesap siliniyor...")
                    .font(.headline)
            }
            .padding(24)
            .background(
                .ultraThinMaterial
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: {
                viewModel.errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                }
            }
        )
    }

    private func presentingViewController()
        -> UIViewController? {

        guard
            let windowScene =
                UIApplication.shared.connectedScenes
                    .compactMap({
                        $0 as? UIWindowScene
                    })
                    .first,
            let rootViewController =
                windowScene.windows
                    .first(where: {
                        $0.isKeyWindow
                    })?
                    .rootViewController
        else {
            return nil
        }

        return topViewController(
            from: rootViewController
        )
    }

    private func topViewController(
        from viewController: UIViewController
    ) -> UIViewController {
        if let presented =
            viewController.presentedViewController {
            return topViewController(
                from: presented
            )
        }

        if let navigationController =
            viewController as? UINavigationController,
           let visibleViewController =
            navigationController.visibleViewController {
            return topViewController(
                from: visibleViewController
            )
        }

        if let tabBarController =
            viewController as? UITabBarController,
           let selectedViewController =
            tabBarController.selectedViewController {
            return topViewController(
                from: selectedViewController
            )
        }

        return viewController
    }
}

#Preview {
    NavigationStack {
        SettingsPage()
            .environmentObject(
                SessionViewModel()
            )
    }
}
