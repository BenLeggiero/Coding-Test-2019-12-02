//
//  SessionToken.swift
//  AuthBackend
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation



/// A token which uniquely identifies a user's session
public struct SessionToken {
    /// The actual data of the token
    internal let data: Data
    
    /// When the token was created
    internal let creationDate: Date
    
    
    /// Generates a new token
    internal init() {
        self.data = UUID().uuidData()
        self.creationDate = Date()
    }
}



extension SessionToken: Equatable {
    public static func == (lhs: SessionToken, rhs: SessionToken) -> Bool {
        return lhs.data == rhs.data
    }
}



extension SessionToken: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
    }
}
