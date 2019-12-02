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
}
