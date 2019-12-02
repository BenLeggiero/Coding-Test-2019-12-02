//
//  Input conveniences.swift
//  AuthCLI
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation
import SpecialString



/// Attempts to read the user's input from the CLI
/// - Returns: The user's input if they gave any, or `nil` if they did not (e.g. if `EOF` has already been reached)
func getUserInputFromCli() -> UnsafeUserInput? {
    return readLine().map(UnsafeUserInput.init)
}
