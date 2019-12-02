//
//  main.swift
//  AuthCLI
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation

print("Welcome to Authenticator!")

switch promptForUserIntent() {
case .loggingIn:
    performLogin()
    
case .registering:
    beginRegistration()
}
