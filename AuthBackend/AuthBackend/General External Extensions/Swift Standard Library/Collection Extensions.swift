//
//  Collection Extensions.swift
//  AuthBackend
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation



public extension Collection where Element: Equatable {
    
    /// Determines whether the given sample is the only element in this collection, either alone or repeated.
    /// - Note: If this collection is empty, this function always returns `false`
    /// - Parameter sample: The sample to test against each element in this collection
    func allEqual(_ sample: Element) -> Bool {
        return !isEmpty && allSatisfy { $0 == sample }
    }
}
