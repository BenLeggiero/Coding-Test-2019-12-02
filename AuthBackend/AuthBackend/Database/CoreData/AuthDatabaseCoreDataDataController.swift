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
        
        let momdName = "DataModel"
        
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: momdName, withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }

        persistentContainer = NSPersistentContainer(name: momdName, managedObjectModel: mom)
        
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
    ///
    /// - Parameter userAccount: The account to save
    /// - Throws: Any error that occurred when interacting with CoreData
    func insert(newUser userAccount: UserAccount) throws {
//        let userAccount = NSEntityDescription.insertNewObject(forEntityName: "UserAccount", into: managedObjectContext) as! UserAccountCoreDataEntity

        let context = persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "UserAccount", in: context)!
        
        let newUserAccount = NSManagedObject(entity: entity, insertInto: context) as! UserAccountCoreDataEntity
        print(newUserAccount) // TODO: Remove when testing complete
        newUserAccount.setValuesForKeys([
            "id" : userAccount.id,
            "displayName" : userAccount.displayName,
            "passwordHash" : userAccount.passwordHash.contents,
            "passwordSalt" : userAccount.passwordHash.salt,
        ])
        
        if let approachForDatabase = userAccount.passwordHash.approach.coreDataRepresentation {
            newUserAccount.setValue(approachForDatabase, forKey: "passwordHashingApproach")
        }
        
        try persistentContainer.viewContext.save()
    }
    
    
    /// Attempts to find an existing user with the given display name
    ///
    /// - Parameters:
    ///   - displayName:      The user's display name
    ///   - onLookupComplete: Called when the lookup has been performed
    func lookupUser(byDisplayName displayName: String, onLookupComplete: @escaping OnUserAccountLookupComplete) {
        func lookupSynchronously() throws -> UserAccount {
            let context = persistentContainer.viewContext
            let userFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserAccount")
            userFetchRequest.predicate = NSPredicate(format: "displayName == %@", argumentArray: [displayName])
            
            do {
                let fetchResults = try context.fetch(userFetchRequest)
                guard let fetchedUserAccounts = fetchResults as? [UserAccountCoreDataEntity] else {
                    throw AuthDatabase.InteractionError.userAccountFetchResultsWereNotUserAccounts
                }
                guard let firstFetchedUserAccount = fetchedUserAccounts.first else {
                    throw AuthDatabase.UserError.noUsernameWithGivenDisplayName
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
    
    
    
    /// Called once a user account lookup is complete
    typealias OnUserAccountLookupComplete = Callback<Result<UserAccount, Error>>
}
