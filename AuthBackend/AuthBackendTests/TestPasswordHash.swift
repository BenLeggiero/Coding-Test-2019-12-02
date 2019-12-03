//
//  TestPasswordHash.swift
//  AuthBackendTests
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import XCTest
@testable import AuthBackend



class TestPasswordHash: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    
    func testInit_rawUnsanitizedPassword_salt_approach_sha512() {
        
        /// Tests that generating a password hash with the given raw password and salt results in the given
        /// expected result
        ///
        /// - Parameters:
        ///   - password:       The password to be hashed
        ///   - salt:           The salt to combine with the password while hashing
        ///   - expectedResult: The result we expect from the hashing process, as a hex-encoded string with upper-case letters
        func testPasswordHashing(password: String, salt: Data, expectedResult: String) -> Bool {
            let hashed = try! PasswordHash(rawUnsanitizedPassword: .init(password), salt: .testSalt, approach: .sha512)
            let hashString = hashed.contents.hexEncodedString(options: .upperCase)
            
            return hashString == expectedResult
        }
        
        
        XCTAssertTrue(testPasswordHashing(password: "password", salt: .testSalt, expectedResult: "9B5F22D28347267649365118A9DF71B2B974C8DE90A75BD1898AB4230871A7C93114D737A38AEAC71C4D9B2A93D28F0C995A967151E6B0F6C57180B78580A35B"))
        XCTAssertTrue(testPasswordHashing(password: "password", salt: .testSalt, expectedResult: "9B5F22D28347267649365118A9DF71B2B974C8DE90A75BD1898AB4230871A7C93114D737A38AEAC71C4D9B2A93D28F0C995A967151E6B0F6C57180B78580A35B"))
        XCTAssertFalse(testPasswordHashing(password: "Password", salt: .testSalt, expectedResult: "9B5F22D28347267649365118A9DF71B2B974C8DE90A75BD1898AB4230871A7C93114D737A38AEAC71C4D9B2A93D28F0C995A967151E6B0F6C57180B78580A35B"))
    }
    
    
    func testMatches_sha512() {
        let passwordHash = try! PasswordHash(rawUnsanitizedPassword: .init("password"), salt: .testSalt, approach: .sha512)
        
        XCTAssertTrue(try! passwordHash.matches(.init("password")))
    }
}



internal extension Data {
    static let testSalt = "Salt".data(using: .utf8)!
}
