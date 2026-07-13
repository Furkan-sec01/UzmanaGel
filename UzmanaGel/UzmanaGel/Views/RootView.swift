//
//  RootView.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject var session: SessionViewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if session.isAuthenticated && session.isCheckingProfile {
                ProgressView("Profil kontrol ediliyor...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("BackgroundColor").ignoresSafeArea())
            } else if session.isAuthenticated && session.isInExpertSignupFlow,
                      let vm = session.expertSignUpViewModel {
                ExpertSignUpView(vm: vm)
                    .environmentObject(session)
            } else if session.isAuthenticated && session.isExpert {
                ExpertHomepage()
                    .environmentObject(session)
            } else if session.isAuthenticated && session.needsProfileSetup {
                CompleteProfileView()
                    .environmentObject(session)
            } else if session.isAuthenticated {
                Homepage()
            } else {
                LoginPage()
            }
        }
    }
}
