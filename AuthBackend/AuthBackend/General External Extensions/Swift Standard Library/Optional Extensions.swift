//
//  Optional Extensions.swift
//  AuthBackend
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation



public extension Optional {
    
    /// If this contains a value, then that value is returned. Else, the given error is thrown.
    func nonNilOrThrow(_ error: @autoclosure () -> Error = UnexpectedlyFoundNilError()) throws -> Wrapped {
        switch self {
        case .some(let value):
            return value
            
        case .none:
            throw error()
        }
    }
}



/// Thrown when trying to use an Optional and expecting it to be non-nil, but it is nil
public struct UnexpectedlyFoundNilError: Error {
    public init() {}
}
