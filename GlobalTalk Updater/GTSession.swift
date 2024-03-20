//
//  GTSession.swift
//  GlobalTalk Updater
//
//  Created by Sam Johnson on 3/19/24.
//

import Foundation
import AppKit
import GoogleSignIn
import os.log

class GTSession: ObservableObject {
    let scope = "https://www.googleapis.com/auth/spreadsheets.readonly"
    
    @Published var isSignedIn = false
    @Published var user: GIDGoogleUser?
    
    init(isSignedIn: Bool = false) {
        // This should only be set true for previews usage
        self.isSignedIn = isSignedIn
    }
    
    func handlePreviousSession(_ user: GIDGoogleUser?) {
        guard let user = user else { return }
        self.ensureScopes(user)
    }
    
    func signIn() {
        guard let window = NSApplication.shared.keyWindow else {
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: window, hint: "Sign in to allow GlobalTalk Updater to access the GlobalTalk spreadsheet.", additionalScopes: [self.scope]) { signInResult, error in
            guard let signInResult = signInResult else {
                os_log("Sign in error: \(error?.localizedDescription ?? "Unknown")")
                self.isSignedIn = false
                self.user = nil
                return
            }
            self.ensureScopes(signInResult.user)
        }
    }
    
    private func ensureScopes(_ user: GIDGoogleUser) {
        let grantedScopes = user.grantedScopes
        if grantedScopes == nil || !grantedScopes!.contains(self.scope) {
            // We do not have the required scope; request it
            guard let window = NSApplication.shared.keyWindow else {
                return
            }
            let additionalScopes = [self.scope]
            user.addScopes(additionalScopes, presenting: window) { signInResult, error in
                guard error == nil else { return }
                guard let signInResult = signInResult else { return }
                
                // Validate that the updated user returned contains the requested scope
                self.ensureScopes(signInResult.user)
            }
        } else if grantedScopes!.contains(self.scope) {
            // We have the required scope
            self.isSignedIn = true
            self.user = user
        } else {
            // Reset state
            self.isSignedIn = false
            self.user = nil
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        self.isSignedIn = false
        self.user = nil
    }
}
