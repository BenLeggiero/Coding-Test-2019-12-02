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
    
    
    /// Simply ensures the shared database is completely initialized
    static func initialize() {
        _ = Self.shared
    }
}



public extension AuthDatabase {
    
    /// Attempts to find an existing user with the given display name
    ///
    /// - Parameters:
    ///   - displayName:      The user's display name
    ///   - onLookupComplete: Called when the lookup has been performed
    func lookupUser(byDisplayName displayName: String, onLookupComplete: @escaping OnUserLookupComplete) {
        guard let coreDataController = self.coreDataController else {
            return onLookupComplete(.failure(InteractionError.lookupAttemptedBeforeDatabaseDoneInitializingError))
        }
        
        return coreDataController.lookupUser(byDisplayName: displayName, onLookupComplete: onLookupComplete)
    }
    
    
    
    typealias OnUserLookupComplete = Callback<LookupUserResult>
    
    
    
    /// The result of performing a user lookup
    typealias LookupUserResult = Swift.Result<UserAccount, Error>
}



public extension AuthDatabase {
    /// An error occurred while interacting with the CoreData database
    enum InteractionError: Error {
        /// Expected to fetch user account objects from the database, but what we got back weren't those
        case userAccountFetchResultsWereNotUserAccounts
        
        /// A lookup is attempted before its backing database is done initializing
        case lookupAttemptedBeforeDatabaseDoneInitializingError
    }
    
    
    
    /// An error occurred which might be the fault of the user
    enum UserError: Error {
        /// Searched the database for users by display name, but no user with that display name was in the database
        case noUsernameWithGivenDisplayName
    }
}



public extension AuthDatabase {
    
    /// Registers the given user in the database
    ///
    /// - Parameters:
    ///   - newUser:                The new user to register
    ///   - onRegistrationComplete: Called when registration completes
    func register(newUser: UserAccount, onRegistrationComplete: @escaping OnUserRegistrationComplete) {
        self.lookupUser(byDisplayName: newUser.displayName) { lookupResult in
            switch lookupResult {
            case .failure(let error as UserError):
                switch error {
                case .noUsernameWithGivenDisplayName:
                    do {
                        try self.insert(newUser: newUser)
                        return onRegistrationComplete(.success(()))
                    }
                    catch {
                        return onRegistrationComplete(.failure(.unexpected(error: error)))
                    }
                }
                
            case .failure(let error):
                return onRegistrationComplete(.failure(.unexpected(error: error)))
                
            case .success(_):
                return onRegistrationComplete(.failure(.displayNameAlreadyRegistered))
            }
        }
    }
    
    
    /// Inserts the given user into the database
    ///
    /// - Parameter newUser: The user to insert into the database
    private func insert(newUser: UserAccount) throws {
        try coreDataController?.insert(newUser: newUser)
    }
    
    
    
    typealias OnUserRegistrationComplete = Callback<Result<Void, RegistrationError>>
    
    
    
    /// An error which occurred during registration
    enum RegistrationError: Error {
        /// Registration could not complete because a user with the given display name is already registered
        case displayNameAlreadyRegistered
        
        /// An unexpected error occurred during registration
        case unexpected(error: Error)
    }
}
