//
//  UserAccount.swift
//  AuthBackend
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation
import SpecialString



/// Represents a user's account
public struct UserAccount {
    /// The user's unique identifier
    public let id: UUID
    
    /// The chosen name of the user to display
    public let displayName: String
    
    /// The user's password, hashed securely
    public let passwordHash: PasswordHash
    
    
    internal init(id: UUID = UUID(), displayName: String, passwordHash: PasswordHash) {
        self.id = id
        self.displayName = displayName
        self.passwordHash = passwordHash
    }
}



public extension UserAccount {
    
    /// Determines whether this account has the given user-provided password
    ///
    /// - Parameter password: The raw password from the user
    /// - Returns: `true` iff the salted hash of the given password perfectly matches this one
    /// - Throws: Any error which occurs when trying to generate the new hash 
    func hasPassword(_ password: Password) throws -> Bool {
        return try passwordHash.matches(password)
    }
}
