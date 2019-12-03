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
    fileprivate private(set) var coreDataController: AuthDatabaseCoreDataDataController? = nil
    
    
    fileprivate init(onDatabaseDoneInitializing: @escaping OnDatabaseDoneInitializing) {
        coreDataController = AuthDatabaseCoreDataDataController() { [weak self] result in
            guard let self = self else {
                return onDatabaseDoneInitializing(.failure(SelfDeinitializedBeforeDatabaseDoneInitializingError()))
            }
            
            switch result {
            case .failure(let error):
                return onDatabaseDoneInitializing(.failure(error))
                
            case .success(controller: _):
                return onDatabaseDoneInitializing(.success(self))
            }
        }
    }
    
    
    
    fileprivate typealias OnDatabaseDoneInitializing = Callback<Result<AuthDatabase, Error>>
    
    
    
    /// Thrown when a database object is deinitialized before its backing database is done initializing
    public struct SelfDeinitializedBeforeDatabaseDoneInitializingError: Error {}
}



public extension AuthDatabase {
    static let shared = await(asyncFunction: AuthDatabase.init)
}



public extension AuthDatabase {
    
    func lookupUser(byDisplayName displayName: String, onLookupComplete: @escaping Callback<LookupUserResult>) {
        guard let coreDataController = self.coreDataController else {
            return onLookupComplete(.failure(LookupAttemptedBeforeDatabaseDoneInitializingError()))
        }
        
        return coreDataController.lookupUser(byDisplayName: displayName, onLookupComplete: onLookupComplete)
    }
    
    
    
    /// The result of performing a user lookup
    typealias LookupUserResult = Swift.Result<UserAccount, Error>
    
    
    /// Thrown when a lookup is attempted before its backing database is done initializing
    struct LookupAttemptedBeforeDatabaseDoneInitializingError: Error {}
}
