//
//  main.swift
//  AuthCLI
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation
import AuthBackend



print("Welcome to Authenticator!")



let delegate = AuthenticatorDelegate()

Authenticator.beginAuthenticationProcess(delegate: delegate)
