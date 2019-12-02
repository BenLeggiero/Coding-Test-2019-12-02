//
//  UserIntent.swift
//  AuthCLI
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation
import SpecialString



/// The user's intention here
internal enum UserIntent {
    /// The user is logging in with an existing account
    case loggingIn
    
    /// The user is registering a new account
    case registering
}



internal extension UserIntent {
    
    /// Uses the given raw user input to determine their intent by comparing it to the given expected input prefixes
    ///
    /// - Parameters:
    ///   - rawUserInput:     The user's raw input, unsanitized
    ///   - caseInsensitive:  _optional_ - Iff `true`, the user's input's capitalization will be ignored.
    ///                       Defaults to `true`
    ///   - expectedPrefixes: The prefixes to the user input that you expect
    init?(rawUserInput: UnsafeUserInput,
          caseInsensitive: Bool = true,
          expectedPrefixes: ExpectedUserInputPrefixes) {
        guard
            let userInputPrefix = rawUserInput
                .withoutTypeSafety()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .first
            else
        {
            return nil
        }
        
        if userInputPrefix.equals(expectedPrefixes.loggingIn, caseInsensitive: caseInsensitive) {
            self = .loggingIn
        }
        else if userInputPrefix.equals(expectedPrefixes.registering, caseInsensitive: caseInsensitive) {
            self = .registering
        }
        else {
            return nil
        }
    }
    
    
    
    /// The prefixes to a user's input that you expect, when asking for their itent
    typealias ExpectedUserInputPrefixes = (loggingIn: Character, registering: Character)
}
