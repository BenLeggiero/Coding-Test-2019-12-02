//
//  TestUserAccount.swift
//  AuthBackendTests
//
//  Created by Ben Leggiero on 2019-12-03.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import XCTest
@testable import AuthBackend



class TestUserAccount: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    
    func testHasPassword() {
        let testAccount = UserAccount(id: UUID(),
                                      displayName: "Jimmy",
                                      passwordHash: try! PasswordHash(rawUnsanitizedPassword: .init("password"),
                                                                      salt: .testSalt))
        
        XCTAssertTrue(try! testAccount.hasPassword(.init("password")))
    }
}
