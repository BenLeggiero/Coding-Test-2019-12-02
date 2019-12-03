//
//  Main Guts.swift
//  AuthCLI
//
//  The guts of the main file, to keep its actions and purpose clear
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation
import AuthBackend
import SpecialString



internal class AuthenticatorDelegate: Authenticator.Delegate {
    
    // MARK: End states
    
    func authenticationFailed(cause: AuthenticationFailure) {
        print("Could not complete authentication:", cause.localizedDescription)
    }
    
    
    func authenticationSuccessful(account: UserAccount, sessionToken: SessionToken) {
        loginSuccessful(account: account)
    }
    
    
    // MARK: Collecting Info
    
    func onAuthenticatorNeedsUserIntent(onUserDidExpressIntent: @escaping OnUserDidExpressIntent) {

        let prompt = "Are you (L)ogging into an existing account, or a (R)egistering a new one?"
        
        while true {
            guard let rawUserResponse = getUserInputFromCli(prompt: prompt) else {
                exit(0)
            }
            
            guard
                let userIntent = UserIntent(
                    rawUserInput: rawUserResponse,
                    expectedPrefixes: (
                        loggingIn: "L",
                        registering: "R"
                    )
                )
                else
            {
                print("That is not a known option.\n")
                continue
            }
            
            return onUserDidExpressIntent(.success(userIntent))
        }
    }
    
    
    func onAuthenticatorNeedsUserDisplayName(onUserDidProvideDisplayName: @escaping OnUserDidProvideDisplayName) {
        guard let displayName = promptForUserDisplayName() else {
            exit(0)
        }
        
        return onUserDidProvideDisplayName(.success(displayName))
    }
    
    
    func onAuthenticatorNeedsUserPassword(onUserDidProvidePassword: @escaping OnUserDidProvidePassword) {
        guard let password = promptForUserPassword() else {
            exit(0)
        }
        
        return onUserDidProvidePassword(.success(password))
    }
    
    
    // MARK: Edge Case Mitigation
    
    func userSuppliedInvalidDisplayName() -> InappropriateDisplayNameOrPasswordMitigation {
        informUserOfInvalidDisplayName()
        return .retry
    }
    
    
    func userSuppliedUnregisteredDisplayName() -> InappropriateDisplayNameOrPasswordMitigation {
        informUserThatNoSuchDisplayNameExists()
        return .retry
    }
    
    
    func userSuppliedAlreadyRegisteredDisplayName() -> InappropriateDisplayNameOrPasswordMitigation {
        informUserThatDisplayNameIsTaken()
        return .retry
    }
    
    
    func userSuppliedBadPassword() -> InappropriateDisplayNameOrPasswordMitigation {
        informUserThatPasswordDoesNotMatchDisplayName()
        return .retry
    }
}



// MARK: - Semantic Print & Prompt Aliases

private func promptForUserDisplayName() -> UnsafeUserInput? {
    getUserInputFromCli(prompt: "What is your name?")
}

private func promptForUserPassword() -> Password? {
    return getUserInputFromCli(prompt: "Password:").map { Password($0.withoutTypeSafety()) }
    
}


private func informUserOfInvalidDisplayName() {
    print("Invalid display name! Display names can only contain letters, numbers, and spaces")
}


private func informUserThatNoSuchDisplayNameExists() {
    print("Could not find any user with that name")
}


private func informUserThatDisplayNameIsTaken() {
    print("A user is already registered with that display name")
}


private func informUserThatPasswordDoesNotMatchDisplayName() {
    print("Incorrect password")
}


private func loginSuccessful(account: UserAccount) {
    print("Login successful! Welcome back, \(account.displayName)")
}
