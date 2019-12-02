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



/// Prompts the user for their intent, retrying on bad input
internal func promptForUserIntent() -> UserIntent {
    
    while true {
        print("Are you (L)ogging into an existing account, or a (R)egistering a new one?", terminator: " ")
        guard let rawUserResponse = getUserInputFromCli() else {
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
            print("That is not a known option.")
            continue
        }
        return userIntent
    }
}



internal func performLogin() {
    let displayName = promptForUserDisplayName()
    
    let lookupResult = await(passing: displayName, to: AuthDatabase.shared.lookupUser)
    
    lookupWaitSemaphore.wait()
}



internal func beginRegistration() {
    
}
