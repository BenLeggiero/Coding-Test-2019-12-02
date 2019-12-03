//
//  PasswordHash.swift
//  AuthBackend
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation
import SpecialString
import CommonCrypto



/// The digested hash of a user's password
public struct PasswordHash {
    /// The raw data contents of this hash
    public let contents: Data
    
    /// The salt of this hash
    public let salt: Data
    
    public let approach: UsedApproach
}



// MARK: - Initialization

public extension PasswordHash {
    
    /// Creates a new password hash by digesting the given raw, unsanitized password along with the given salt using the given approach
    ///
    /// - Parameters:
    ///   - rawUnsanitizedPassword: The raw, unsanitized password that the user provided
    ///   - salt:                   _optional_ - The salt to combinre with the password while hashing.
    ///                             Defaults to a randomly-generated salt.
    ///   - approach:               _optional_ - The approach by which the hash will be generated.
    ///                             Defaults to the default approach.
    init(rawUnsanitizedPassword: Password, salt: Data = .generateSalt(), approach: Approach = .default) throws {
        self.contents = try approach.performHash(on: rawUnsanitizedPassword, salt: salt)
        self.salt = salt
        self.approach = UsedApproach(approach)
    }
}



// MARK: - Hashing Approaches

public extension PasswordHash {
    
    /// The approach by which the hash was generated
    enum Approach: CaseIterable {
        /// SHA-512, a 512-bit hashing approach
        case sha512
    }
    
    
    
    /// The approach which was actually used when hashing a password
    enum UsedApproach {
        /// The approach is unknown; possibly made by a future version of this software
        case unknown
        
        /// The approach is good and known
        /// - Parameter approach: The approach which was actually used
        case known(approach: Approach)
        
        
        /// Creates a `UsedApproach` from the given known `Approach`
        /// - Parameter knownApproach: The approach we know was actually used
        init(_ knownApproach: Approach) {
            self = .known(approach: knownApproach)
        }
        
        
        /// Returns the actual known approach, or `nil` if it isn't known
        func knownOrNil() -> Approach? {
            switch self {
            case .unknown: return nil
            case .known(let approach): return approach
            }
        }
    }
}


// MARK: Constants

public extension PasswordHash.Approach {
    /// The default hashing approach
    static let `default` = sha512
}


// MARK: Functionality

public extension PasswordHash.Approach {
    
    /// The number of bytes in a result of this hashing approach
    var digestLength: Int {
        let length: CInt
        
        switch self {
        case .sha512:
            length = CC_SHA512_DIGEST_LENGTH
        }
        
        return Int(length)
    }
    
    
    /// Immediately performs a hash using this approach
    ///
    /// - Parameters:
    ///   - rawUnsanitizedPassword: The password to be hashed and salted
    ///   - salt:                   The salt with which to hash and salt the password
    ///
    /// - Returns: The result of hashing and salting the password
    func performHash(on rawUnsanitizedPassword: Password, salt: Data) throws -> Data {
        var rawUnsanitizedPasswordData = try rawUnsanitizedPassword
            .withoutTypeSafety()
            .data(using: .bestForPasswordHashing)
            .nonNilOrThrow(FailedToConvertPasswordToDataError())
            + salt
        
        var hash = [UInt8](repeating: 0, count: digestLength)
        
        switch self {
        case .sha512:
            CC_SHA512(&rawUnsanitizedPasswordData, CC_LONG(rawUnsanitizedPasswordData.count), &hash)
        }
        
        guard
            !hash.isEmpty,
            !hash.allEqual(0)
            else
        {
            throw FailedToGenerateHashError()
        }
        
        return Data(hash)
    }
    
    
    
    struct FailedToConvertPasswordToDataError: Error {}
    struct FailedToGenerateHashError: Error {}
}



// MARK: - Validation

public extension PasswordHash {
    /// Determines whether this hash matches the given raw password
    ///
    /// - Parameter password: The raw password from the user
    /// - Returns: `true` iff the salted hash of the given password perfectly matches this one
    /// - Throws: Any error which occurs when trying to generate the new hash
    func matches(_ password: Password) throws -> Bool {
        let regeneratedHash = try PasswordHash(rawUnsanitizedPassword: password,
                                               salt: self.salt,
                                               approach: self.approach.knownOrNil() ?? .default)
        return regeneratedHash.contents == self.contents
    }
}



// MARK: - Public Extensions of Extenral APIs

public extension Data {
    
    /// Generates a unique salt for hashing
    static func generateSalt() -> Data {
        return UUID().uuidData() + UUID().uuidData()
    }
}



// MARK: - Private Extensions of Extenral APIs

private extension String.Encoding {
    
    /// The string encoding we prefer when hashing a password
    static let bestForPasswordHashing = utf8
}
