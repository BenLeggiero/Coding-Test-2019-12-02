//
//  Function Types.swift
//  AuthBackend
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation



/// A callback that is "blind"; it does not receive any result nor respond with any side-effects
public typealias BlindCallback = () -> Void



/// An asynchronous function which takes one argument in addition to its callback, where the argument comes first
///
/// - Parameters:
///   - firstArgument: The argument which comes before the callback
///   - callback:      The function which is called after this async function completes
public typealias AsyncFunctionTakingOneArgumentAndOneCallback<FirstArgument, CallbackResult> = (_ firstArgument: FirstArgument, _ callback: Callback<CallbackResult>) -> Void



/// A function which is passed to another function, to be called when that other function completes
///
/// - Parameter result: The result of the parent function which is passed to this one when the parent function completes
public typealias Callback<Result> = (_ result: Result) -> Void
