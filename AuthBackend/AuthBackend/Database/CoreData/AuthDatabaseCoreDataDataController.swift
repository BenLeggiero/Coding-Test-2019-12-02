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
    
    var managedObjectContext: NSManagedObjectContext
    var persistentContainer: NSPersistentContainer
    
    
    init(completionCallback: @escaping BlindCallback) {
        persistentContainer = NSPersistentContainer(name: "DataModel")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
            completionCallback()
        }
    }
}



internal extension AuthDatabaseCoreDataDataController {
    
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
        let newUserAccount = NSManagedObject(entity: entity, insertInto: context) as! UserAccountCoreDataEntity
        print(newUserAccount)
        
        try persistentContainer.viewContext.save()
    }
    
    
    func existingUser(displayName: String) throws -> UserAccount {
        let context = persistentContainer.viewContext
        let userFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserAccount")
        userFetchRequest.predicate = NSPredicate(format: "displayName == %@", argumentArray: [displayName])
        
        do {
            let fetchResults = try context.fetch(userFetchRequest)
            guard let fetchedEmployees = fetchResults as? [UserAccountCoreDataEntity] else {
                throw InteractionError.userAccountFetchResultsWereNotUserAccounts
            }
            
            return fetchedEmployees.map(UserAccount.init)
        }
        catch {
            fatalError("Failed to fetch employees: \(error)")
        }
    }
    
    
    
    enum InteractionError: Error {
        case userAccountFetchResultsWereNotUserAccounts
    }
}
