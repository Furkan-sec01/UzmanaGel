//
//  LoginAttemptTracker.swift
//  UzmanaGel
//
//  Created by Abdullah B on 23.02.2026.
//

import Foundation

@MainActor
final class LoginAttemptTracker {

    static let shared = LoginAttemptTracker()

    private let maxAttempts = 3
    private let lockMinutes = 30

    private var failedAttempts: Int {
        get { UserDefaults.standard.integer(forKey: "loginFailedAttempts") }
        set { UserDefaults.standard.set(newValue, forKey: "loginFailedAttempts") }
    }

    private var lockedUntil: Date? {
        get { UserDefaults.standard.object(forKey: "loginLockedUntil") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "loginLockedUntil") }
    }

    var isLocked: Bool {
        guard let until = lockedUntil else { return false }
        if Date() < until { return true }
        lockedUntil = nil
        return false
    }

    let lockMessage = "Çok fazla hatalı giriş denemesi yaptınız. Lütfen 30 dakika sonra tekrar deneyin."

    private init() {}

    func recordFailure() {
        failedAttempts += 1
        if failedAttempts >= maxAttempts {
            lockedUntil = Date().addingTimeInterval(TimeInterval(lockMinutes * 60))
            failedAttempts = 0
        }
    }

    func recordSuccess() {
        failedAttempts = 0
        lockedUntil = nil
    }
}
