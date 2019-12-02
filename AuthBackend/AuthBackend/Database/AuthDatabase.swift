//
//  AuthDatabase.swift
//  AuthBackend
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation
import CoreData



public class AuthDatabase {
    
}



public extension AuthDatabase {
    static let shared = AuthDatabase()
}



public extension AuthDatabase {
    
    func lookupUser(displayName: String, onLookupComplete: @escaping Callback<LookupUserResult>) {
        
    }
    
    
    
    /// The result of performing a user lookup
    typealias LookupUserResult = Swift.Result<UserAccount, Error>
}
