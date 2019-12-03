//
//  UUID Extensions.swift
//  AuthBackend
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation



public extension UUID {
    
    /// Returns the `Data` version of the `uuid` field of this UUID
    func uuidData() -> Data {
        let lowLevel = self.uuid
        return Data.init([
            lowLevel.01,
            lowLevel.02,
            lowLevel.03,
            lowLevel.04,
            lowLevel.05,
            lowLevel.06,
            lowLevel.07,
            lowLevel.08,
            lowLevel.09,
            lowLevel.10,
            lowLevel.11,
            lowLevel.12,
            lowLevel.13,
            lowLevel.14,
            lowLevel.15,
        ])
    }
}
