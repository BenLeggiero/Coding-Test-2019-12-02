//
//  AuthDatabaseCoreDataDataController.swift
//  AuthBackend
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import AppKit
import CoreData



internal class AuthDatabaseCoreDataDataController: NSObject {
    
    fileprivate var persistentContainer: NSPersistentContainer
    
    
    internal init(onDatabaseDoneInitializing: @escaping OnDatabaseDoneInitializing) {
        persistentContainer = NSPersistentContainer(name: "DataModel")
        
        super.init()
        
        persistentContainer.loadPersistentStores { [weak self] _, error in
            if let error = error {
                onDatabaseDoneInitializing(.failure(error))
            }
            if let self = self {
                onDatabaseDoneInitializing(.success(self))
            }
        }
    }
    
    
    
    internal typealias OnDatabaseDoneInitializing = Callback<Result<AuthDatabaseCoreDataDataController, Error>>
}



internal extension AuthDatabaseCoreDataDataController {
    
    /// Saves the given user into the database
    /// - Parameter userAccount: The account to save
    /// - Throws: Any error that occurred when interacting with CoreData
    func registerNewUser(_ userAccount: UserAccount) throws {
//        let userAccount = NSEntityDescription.insertNewObject(forEntityName: "UserAccount", into: managedObjectContext) as! UserAccountCoreDataEntity

        let context = persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "UserAccount", in: context)!
        entity.setValuesForKeys([
            "id" : userAccount.id,
            "displayName" : userAccount.displayName,
            "passwordHash" : userAccount.passwordHash.contents,
            "passwordSalt" : userAccount.passwordHash.salt,
        ])
        
        if let approachForDatabase = userAccount.passwordHash.approach.coreDataRepresentation {
            entity.setValue(approachForDatabase, forKey: "passwordHashingApproach")
        }
        
        let newUserAccount = NSManagedObject(entity: entity, insertInto: context) as! UserAccountCoreDataEntity
        print(newUserAccount)
        
        try persistentContainer.viewContext.save()
    }
    
    
    /// Attempts to find an existing user with the given display name
    /// - Parameter displayName: The user's display name
    func lookupUser(byDisplayName displayName: String, onLookupComplete: @escaping OnUserAccountLookupComplete) {
        func lookupSynchronously() throws -> UserAccount {
            let context = persistentContainer.viewContext
            let userFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserAccount")
            userFetchRequest.predicate = NSPredicate(format: "displayName == %@", argumentArray: [displayName])
            
            do {
                let fetchResults = try context.fetch(userFetchRequest)
                guard let fetchedEmployees = fetchResults as? [UserAccountCoreDataEntity] else {
                    throw InteractionError.userAccountFetchResultsWereNotUserAccounts
                }
                guard let firstFetchedUserAccount = fetchedEmployees.first else {
                    throw UserError.noUsernameWithGivenDisplayName
                }
                
                return UserAccount(firstFetchedUserAccount)
            }
            catch {
                throw error
            }
        }
        
        
        // TODO: How difficult would it be to put this on a background queue?
        onLookupComplete(Result(catching: lookupSynchronously))
    }
    
    
    
    /// An error occurred while interacting with the CoreData database
    enum InteractionError: Error {
        /// Expected to fetch user account objects from the database, but what we got back weren't those
        case userAccountFetchResultsWereNotUserAccounts
    }
    
    
    
    /// An error occurred which might be the fault of the user
    enum UserError: Error {
        /// Searched the database for users by display name, but no user with that display name was in the database
        case noUsernameWithGivenDisplayName
    }
    
    
    
    /// Called once a user account lookup is complete
    typealias OnUserAccountLookupComplete = Callback<Result<UserAccount, Error>>
}
