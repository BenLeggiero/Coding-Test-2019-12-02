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



// MARK: - Setup

/// Prompts the user for their intent, retrying on bad input
internal func promptForUserIntent() -> UserIntent {
    
    let prompt = "Are you (L)ogging into an existing account, or a (R)egistering a new one?"
    
    while true {
        guard let rawUserResponse = getUserInputFromCli(prompt: prompt) else {
            exit(0)
        }
        guard
            let userIntent = UserIntent(rawUserInput: rawUserResponse,
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
        return userIntent
    }
}



// MARK: - Login

internal func performLogin() {
    while true {
        guard let displayName = promptForUserDisplayName().sanitizedUsername() else {
            informUserOfInvalidDisplayName()
            continue
        }
        
        let lookupResult = await(passing: displayName, to: AuthDatabase.shared.lookupUser(byDisplayName:onLookupComplete:))
        return
    }
}


private func informUserOfInvalidDisplayName() {
    print("Invalid display name! Display names can only contain letters, numbers, and spaces")
}


private func promptForUserDisplayName() -> UnsafeUserInput {
    
}



private extension UnsafeUserInput {
    
    private static let safeCharacters = CharacterSet.alphanumerics.union(.whitespaces)
    private static var unsafeCharacters: CharacterSet { safeCharacters.inverted }
    
    func sanitizedUsername() -> String? {
        let rawString = self.withoutTypeSafety()
        guard
            !rawString
            .lazy
            .flatMap({ $0.unicodeScalars })
            .contains(where: Self.unsafeCharacters.contains)
        else
        {
            return nil
        }
        return rawString
    }
}



// MARK: - Registration

internal func beginRegistration() {
    
}
