//
//  await.swift
//  AuthCLI
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation
import AuthBackend



/// Calls the given asynchronous function by passing it the given argument, and waits for its callback block to be called
///
/// - Parameters:
///   - argument:      The argument to pass to the given function before waiting for it to complete
///   - asyncFunction: The asynchronous function whose result to await
internal func await<FirstArgument, Return>(passing argument: FirstArgument, to asyncFunction: AsyncFunctionTakingOneArgumentAndOneCallback<FirstArgument, Return>) -> Return {
    let semaphore = DispatchSemaphore(value: 0)
    var returnValue: Return!
    
    asyncFunction(argument) { result in
        returnValue = result
        semaphore.signal()
    }
    
    semaphore.wait()
    
    return returnValue
}
