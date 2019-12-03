//
//  Character Extensions.swift
//  AuthCLI
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation



internal extension Character {
    /// Determines whether this character is equal to the given other one, optionally comparing case-insensitively
    ///
    /// - Parameters:
    ///   - other:           The other character
    ///   - caseInsensitive: Iff `true`, compares without regard to the character's case
    func equals(_ other: Character, caseInsensitive: Bool) -> Bool {
        if caseInsensitive {
            return other.uppercased() == self.uppercased()
        }
        else {
            return other == self
        }
    }
}
