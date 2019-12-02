//
//  Data Extensions.swift
//  AuthBackend
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation



public extension Data {
    
    /// Generates a hex-encoded string out of these Data
    /// - Parameter options: _optional_ - The options for encoding the hex string. Defaults to none.
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return lazy
            .map { String(format: format, $0) }
            .joined()
    }
    
    
    
    /// The options for encoding Data into a hex-encoded string
    struct HexEncodingOptions: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        
        /// The output string should only use upper-case letters
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
}
