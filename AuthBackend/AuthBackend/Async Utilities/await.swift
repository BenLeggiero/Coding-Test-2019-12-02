//
//  await.swift
//  AuthCLI
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation



/// Calls the given asynchronous function by passing it the given argument, and waits for its callback block to be called
///
/// - Parameters:
///   - argument:      The argument to pass to the given function before waiting for it to complete
///   - asyncFunction: The asynchronous function whose callback's result to await
public func await<FirstArgument, Return>(passing argument: FirstArgument, to asyncFunction: AsyncFunctionTakingOneArgumentAndOneCallback<FirstArgument, Return>) -> Return {
    let semaphore = DispatchSemaphore(value: 0)
    var returnValue: Return!
    
    asyncFunction(argument) { result in
        returnValue = result
        semaphore.signal()
    }
    
    semaphore.wait()
    
    return returnValue
}


/// Calls the given asynchronous function, saves its result, and waits for its callback block to be called before
/// returning that result
///
/// - Parameters:
///   - asyncFunction: The asynchronous function whose result to save and whose callback to await
public func await<Return, IgnoredCallbackResult>(asyncFunction: AsyncFunctionTakingZeroArgumentsAndReturningResultImmediatelyThenCallingCallback<Return, IgnoredCallbackResult>) -> Return {
    let semaphore = DispatchSemaphore(value: 0)
    
    let returnValue = asyncFunction() { _ in
        semaphore.signal()
    }
    
    semaphore.wait()
    
    return returnValue
}
