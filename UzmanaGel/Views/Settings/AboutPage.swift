//
//  AboutPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//

import SwiftUI

struct AboutPage: View {
    @ObservedObject private var langManager = LanguageManager.shared

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Color("PrimaryColor"))

            Text("UzmanaGel")
                .font(.system(size: 26, weight: .bold))

            Text("UzmanaGel, kullanıcıların ihtiyaç duydukları hizmetler için uygun uzmanlara ulaşmasını sağlayan bir platformdur.".localized)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            VStack(spacing: 6) {
                Text("\("Sürüm".localized) \(appVersion)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Text("Build \(buildNumber)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundColor"))
        .navigationTitle("Hakkında".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutPage()
    }
}
