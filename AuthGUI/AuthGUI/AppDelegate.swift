//
//  AppDelegate.swift
//  AuthGUI
//
//  Created by Ben Leggiero on 2019-12-03.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Cocoa
import AuthBackend
import SpecialString



@NSApplicationMain
class AppDelegate: NSObject {

    @IBOutlet fileprivate weak var window: NSWindow!
    @IBOutlet fileprivate weak var displayNameTextField: NSTextField!
    @IBOutlet fileprivate weak var passwordTextField: NSSecureTextField!
    @IBOutlet fileprivate weak var registeringCheckbox: NSButton!
    @IBOutlet fileprivate weak var actionButton: NSButton!
}



extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}



private extension AppDelegate {
    
    @IBAction func didToggleRegisteringCheckBox(_ sender: NSButton) {
        switch sender.state {
        case .on:
            actionButton.title = "Register"
            
        case .off:
            actionButton.title = "Login"
            
        default:
            actionButton.title = "Go"
        }
    }
    
    
    @IBAction func didPressLoginButton(_ sender: NSButton) {
        Authenticator.beginAuthenticationProcess(delegate: self)
    }
}



extension AppDelegate: Authenticator.Delegate {
    
    // MARK: End States
    
    func authenticationFailed(cause: AuthenticationFailure) {
        
        func printFailureToConsole() {
            print(cause.localizedDescription)
        }
        
        
        func alertUserOfFailure() {
            printFailureToConsole()
            
            let alert = NSAlert()
            alert.messageText = cause.localizedDescription
            alert.beginSheetModal(for: window, completionHandler: nil)
        }
        
        
        switch cause {
        case .delegateDecidedFailure(delegateError: _),
             .displayNameInvalid,
             .displayNameAlreadyInUse,
             .passwordIncorrect:
            printFailureToConsole()
            
        case .cryptoError,
             .tooManyBadPasswordAttempts,
             .unexpectedErrorOccurred(error: _):
            alertUserOfFailure()
        }
    }
    
    
    func authenticationSuccessful(account: UserAccount, sessionToken: SessionToken) {
        let alert = NSAlert()
        alert.messageText = "Authentication successful!"
        alert.informativeText = "Welcome, \(account.displayName)"
        alert.beginSheetModal(for: window) { _ in
            NSApp.terminate(self)
        }
    }
    
    
    // MARK: Collecting Info
    
    func onAuthenticatorNeedsUserIntent(onUserDidExpressIntent: @escaping OnUserDidExpressIntent) {
        switch registeringCheckbox.state {
        case .on:
            return onUserDidExpressIntent(.success(.registering))
            
        case .off:
            fallthrough
            
        default:
            return onUserDidExpressIntent(.success(.loggingIn))
        }
    }
    
    
    func onAuthenticatorNeedsUserDisplayName(onUserDidProvideDisplayName: @escaping OnUserDidProvideDisplayName) {
        return onUserDidProvideDisplayName(.success(UnsafeUserInput(displayNameTextField.stringValue)))
    }
    
    
    func onAuthenticatorNeedsUserPassword(onUserDidProvidePassword: @escaping OnUserDidProvidePassword) {
        return onUserDidProvidePassword(.success(Password(passwordTextField.stringValue)))
    }
    
    
    // MARK: Edge Case Mitigation
    
    func userSuppliedInvalidDisplayName() -> InappropriateDisplayNameOrPasswordMitigation {
        let alert = NSAlert()
        alert.messageText = "Display Name Invalid"
        alert.informativeText = "Only letters, numbers, and spaces are allowed in a display name"
        alert.beginSheetModal(for: window, completionHandler: nil)
        return .fail
    }
    
    
    func userSuppliedUnregisteredDisplayName() -> InappropriateDisplayNameOrPasswordMitigation {
        let alert = NSAlert()
        alert.messageText = "Display Name Not Registered"
        alert.informativeText = "That display name has not yet been registered. Did you mean to register it?"
        alert.beginSheetModal(for: window, completionHandler: nil)
        return .fail
    }
    
    
    func userSuppliedAlreadyRegisteredDisplayName() -> InappropriateDisplayNameOrPasswordMitigation {
        let alert = NSAlert()
        alert.messageText = "Display Name Already Registered"
        alert.informativeText = "That display name has already been registered. Did you mean to log in?"
        alert.beginSheetModal(for: window, completionHandler: nil)
        return .fail
    }
    
    
    func userSuppliedBadPassword() -> InappropriateDisplayNameOrPasswordMitigation {
        let alert = NSAlert()
        alert.messageText = "Password Incorrect"
        alert.informativeText = "That password does not match that display name"
        alert.beginSheetModal(for: window, completionHandler: nil)
        return .fail
    }
}

