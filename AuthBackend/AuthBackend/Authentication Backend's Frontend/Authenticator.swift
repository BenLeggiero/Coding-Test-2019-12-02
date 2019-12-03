//
//  Authenticator.swift
//  AuthBackend
//
//  Created by Ben Leggiero on 2019-12-02.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation
import SpecialString



/// The maximum number of times the user can attempt a bad password before they're put in time out
private let maxPasswordAttempts: UInt8 = 5

/// The amount of time the user is put in time out when they try too many bad passwords
private let tooManyBadAttemptsCooldownInterval: TimeInterval = 10 * 60



/// Controls the flow of authentication
public enum Authenticator {
    // Empty on-purpose; all members are static
}



// MARK: - Public-facing API

public extension Authenticator {
    /// Starts the authentication process, calling the given delegate as necessary
    ///
    /// - Parameter delegate: The delegate which will respond to authentication steps
    static func beginAuthenticationProcess(delegate: Delegate) {
        AuthDatabase.initialize()
        getUserIntent(with: delegate)
    }
    
    

    /// A set of callbacks to follow the flow of user authentication
    typealias Delegate = AuthenticatorDelegate
}



/// A set of callbacks to follow the flow of user authentication
public protocol AuthenticatorDelegate {
    
    // MARK: End states
    
    /// Called when the `Authenticator` has determiend that authorization cannot continue due to a failure state
    ///
    /// - Parameter cause: The reason authentication failed
    func authenticationFailed(cause: AuthenticationFailure)
    
    
    /// Called when all the steps of authentication have succeeded and the user is logged in
    ///
    /// - Parameter sessionToken: The token which identifies this session
    func authenticationSuccessful(account: UserAccount, sessionToken: SessionToken)
    
    
    // MARK: Collecting Info
    
    /// Called when the `Authenticator` needs the user's intent
    ///
    /// - Parameter onUserDidExpressIntent: The function to call when the user has expressed their intent
    func onAuthenticatorNeedsUserIntent(onUserDidExpressIntent: @escaping OnUserDidExpressIntent)
    
    
    /// Called when the `Authenticator` needs the user's display name
    ///
    /// - Parameter onUserDidProvideDisplayName: The function to call when the user has provided their display name
    func onAuthenticatorNeedsUserDisplayName(onUserDidProvideDisplayName: @escaping OnUserDidProvideDisplayName)
    
    
    /// Called when the `Authenticator` needs the user's password
    ///
    /// - Parameter onUserDidProvidePassword: The function to call when the user has provided their password
    func onAuthenticatorNeedsUserPassword(onUserDidProvidePassword: @escaping OnUserDidProvidePassword)
    
    
    // MARK: Edge Case Mitigation
    
    /// Called when the `Authenticator` decided that the user provided a display name which does not meet our
    /// requirements for a display name
    func userSuppliedInvalidDisplayName() -> InappropriateDisplayNameOrPasswordMitigation
    
    
    /// Called when the `Authenticator` found that the user provided a display name which does not exist in our
    /// registration database
    func userSuppliedUnregisteredDisplayName() -> InappropriateDisplayNameOrPasswordMitigation
    
    
    /// Called when the `Authenticator` found that the user provided a display name which already exists in our
    /// registration database
    func userSuppliedAlreadyRegisteredDisplayName() -> InappropriateDisplayNameOrPasswordMitigation
    
    
    /// Called when the `Authenticator` decided that the user provided a password which does not match our records
    func userSuppliedBadPassword() -> InappropriateDisplayNameOrPasswordMitigation
}



public extension AuthenticatorDelegate {
    /// The kind of callback used for when the user has expressed their intent,
    /// or if an error occured while getting that intent
    typealias OnUserDidExpressIntent = Callback<Result<UserIntent, Error>>
    
    
    
    /// The kind of callback used when the user has given their display name,
    /// or if an error occured while getting that name
    typealias OnUserDidProvideDisplayName = Callback<Result<UnsafeUserInput, Error>>
    
    
    
    /// The kind of callback used when the user has given their password,
    /// or if an error occured while getting that password
    typealias OnUserDidProvidePassword = Callback<Result<Password, Error>>
    
    
    
    /// The delegate's response for how to mitigate a failure to authenticate by a bad display name or password
    typealias InappropriateDisplayNameOrPasswordMitigation = AuthenticatorDelegateInvalidDisplayNameOrPasswordMitigation
}



/// The delegate's response for how to mitigate a failure to authenticate by a bad display name or password
public enum AuthenticatorDelegateInvalidDisplayNameOrPasswordMitigation {
    /// The delegate is okay with the whole process failing out
    case fail
    
    
    /// The delegate wants to try a different display name andor password
    case retry
}



/// The reason why an authentication failed
public enum AuthenticationFailure {
    /// Authentication failed because the delegate returned an error after attempting some step
    /// - Parameter delegateError: The error the delegate returned
    case delegateDecidedFailure(delegateError: Error)
    
    /// The user provided a display name which does not meet our requirements for a display name
    case displayNameInvalid
    
    /// The user provided a password which does not match a display name we have on record
    case passwordIncorrect
    
    /// The user tried to register with a display name which is already in use
    case displayNameAlreadyInUse
    
    /// Some error occurred in the cryptography
    case cryptoError
    
    /// The user attemtped to use a bad password too many times
    case tooManyBadPasswordAttempts
    
    /// Some unexpected error occurred
    case unexpectedErrorOccurred(error: Error)
}



public extension AuthenticationFailure {
    var localizedDescription: String {
        switch self {
        case .delegateDecidedFailure(let delegateError):
            return delegateError.localizedDescription
            
        case .displayNameInvalid:
            return "Invalid display name"
            
        case .passwordIncorrect:
            return "Incorrect password"
            
        case .displayNameAlreadyInUse:
            return "Someone has already registered that display name"
            
        case .cryptoError:
            return "An error occurred in the internal cryptography subsystem"
            
        case .tooManyBadPasswordAttempts:
            return "An incorrect password was attempted too many times"
            
        case .unexpectedErrorOccurred(let error):
            return error.localizedDescription
        }
    }
}



// MARK: - Guts

private extension Authenticator {
    
    static var activeSessionTokens = Set<SessionToken>()
    static var lastTimeOutDate: Date? = nil
    static var badPasswordCount: UInt8 = 0
    
    
    /// Asks the delegate to get the user's intent for this authentication session
    ///
    /// - Parameter delegate: The delgate which will respond to the authenticator's requests
    static func getUserIntent(with delegate: Delegate) {
        delegate.onAuthenticatorNeedsUserIntent { result in
            switch result {
            case .failure(let error):
                return delegate.authenticationFailed(cause: .delegateDecidedFailure(delegateError: error))
                
            case .success(let userIntent):
                switch userIntent {
                case .loggingIn:
                    return self.beginLoginProcess(with: delegate)
                    
                case .registering:
                    return self.beginRegistrationProcess(with: delegate)
                }
            }
        }
    }
    
    
    /// Attempts to look up the user by their display name
    ///
    /// - Parameters:
    ///   - displayName:      The user's display name
    ///   - delegate:         The delegate which will respond to the authenticator's requests
    ///   - onLookupComplete: Called whrn the user lookup is complete
    static func lookupUser(byDisplayName displayName: String,
                           delegate: Delegate,
                           onLookupComplete: @escaping OnUserLookupComplete)
    {
        AuthDatabase.shared.lookupUser(byDisplayName: displayName, onLookupComplete: onLookupComplete)
    }
    
    
    
    typealias OnUserLookupComplete = AuthDatabase.OnUserLookupComplete
}


// MARK: Logging in

private extension Authenticator {
    
    /// Starts logging in
    ///
    /// - Parameter delegate: The delegate which will respond to the authenticator's requests
    static func beginLoginProcess(with delegate: Delegate) {
        delegate.onAuthenticatorNeedsUserDisplayName { result in
            switch result {
            case .failure(let error):
                return delegate.authenticationFailed(cause: .delegateDecidedFailure(delegateError: error))
                
            case .success(let displayName):
                guard let sanitizedDisplayName = displayName.sanitizedDisplayName() else {
                    switch delegate.userSuppliedInvalidDisplayName() {
                    case .fail:
                        return delegate.authenticationFailed(cause: .displayNameInvalid)
                        
                    case .retry:
                        return self.beginLoginProcess(with: delegate)
                    }
                }
                
                return self.lookupUser(byDisplayName: sanitizedDisplayName, delegate: delegate) { result in
                    switch result {
                    case .failure(error: _):
                        switch delegate.userSuppliedUnregisteredDisplayName() {
                        case .fail:
                            return delegate.authenticationFailed(cause: .displayNameInvalid)
                            
                        case .retry:
                            return self.beginLoginProcess(with: delegate)
                        }
                        
                        
                    case .success(let userAccount):
                        return self.requestPassword(from: delegate, compareAgainstAccount: userAccount)
                    }
                }
            }
        }
    }
    
    
    /// Ask the delegate to get the user's password and respond accordingly
    ///
    /// - Parameters:
    ///   - delegate:      The delegate which can get the user's password and respond accordingly
    ///   - userAccount:   The account we already fetched so we can know the user's name and password
    static func requestPassword(from delegate: Delegate, compareAgainstAccount userAccount: UserAccount) {
        
        if let lastTimeOutDate = self.lastTimeOutDate {
            if Date().timeIntervalSince(lastTimeOutDate) < tooManyBadAttemptsCooldownInterval {
                return delegate.authenticationFailed(cause: .tooManyBadPasswordAttempts)
            }
            else { // Out of time out
                self.lastTimeOutDate = nil
                self.badPasswordCount = 0
            }
        }
        
        delegate.onAuthenticatorNeedsUserPassword { result in
            switch result {
            case .failure(let error):
                return delegate.authenticationFailed(cause: .delegateDecidedFailure(delegateError: error))
                
            case .success(let password):
                let attemptsSoFarIncludingThisOne = self.badPasswordCount + 1
                
                do {
                    guard try userAccount.hasPassword(password) else {
                        self.badPasswordCount += 1
                        
                        guard attemptsSoFarIncludingThisOne <= maxPasswordAttempts else {
                            self.lastTimeOutDate = Date()
                            return delegate.authenticationFailed(cause: .tooManyBadPasswordAttempts)
                        }
                        
                        switch delegate.userSuppliedBadPassword() {
                        case .fail:
                            return delegate.authenticationFailed(cause: .passwordIncorrect)
                            
                        case .retry:
                            return self.requestPassword(from: delegate, compareAgainstAccount: userAccount)
                        }
                    }
                }
                catch {
                    return delegate.authenticationFailed(cause: .cryptoError)
                }
                
                badPasswordCount = 0
                
                return loginSuccess(account: userAccount, delegate: delegate)
            }
        }
    }
    
    
    /// Finishes up the login process after the login succeeded
    ///
    /// - Parameter delegate: The delegate which will respond to login success
    static func loginSuccess(account: UserAccount, delegate: Delegate) {
        return delegate.authenticationSuccessful(account: account,
                                                 sessionToken: generateAndSaveNewSessionToken())
    }
    
    
    /// Generates a new session token, saves it to the concurrent sessions, and returns it
    static func generateAndSaveNewSessionToken() -> SessionToken {
        let token = SessionToken()
        activeSessionTokens.insert(token)
        return token
    }
}


// MARK: Registration

private extension Authenticator {
    
    /// Starts the process of registering a new user
    ///
    /// - Parameter delegate: The delegate which will respond to the authenticator's requests
    static func beginRegistrationProcess(with delegate: Delegate) {
        delegate.onAuthenticatorNeedsUserDisplayName { result in
            switch result {
            case .failure(let error):
                return delegate.authenticationFailed(cause: .delegateDecidedFailure(delegateError: error))
                
            case .success(let displayName):
                guard let sanitizedDisplayName = displayName.sanitizedDisplayName() else {
                    switch delegate.userSuppliedInvalidDisplayName() {
                    case .fail:
                        return delegate.authenticationFailed(cause: .displayNameInvalid)
                        
                    case .retry:
                        return self.beginRegistrationProcess(with: delegate)
                    }
                }
                
                return self.lookupUser(
                    byDisplayName: sanitizedDisplayName,
                    delegate: delegate,
                    onLookupComplete: onUserLookupBeforeRegistrationComplete(
                        delegate: delegate,
                        displayName: sanitizedDisplayName
                    )
                )
            }
        }
    }
    
    
    /// Creates a function which can be a callback which is called after the database has looked up a user, which then
    /// handles the remainder of the registration process based off the database's lookup result
    ///
    /// - Parameters:
    ///   - delegate:    The delegate which will respond to the authenticator's requests
    ///   - displayName: The user's display name
    static func onUserLookupBeforeRegistrationComplete(delegate: Delegate, displayName: String) -> OnUserLookupComplete {
        return { result in
            switch result {
            case .failure(error: _):
                return self.requestNewPassword(from: delegate, registeringUserWithDisplayName: displayName)
                
                
            case .success(userAccount: _):
                switch delegate.userSuppliedAlreadyRegisteredDisplayName() {
                case .fail:
                    return delegate.authenticationFailed(cause: .displayNameInvalid)
                    
                case .retry:
                    return self.beginRegistrationProcess(with: delegate)
                }
            }
        }
    }
    
    
    static func requestNewPassword(from delegate: Delegate, registeringUserWithDisplayName displayName: String) {
        delegate.onAuthenticatorNeedsUserPassword { result in
            switch result {
            case .failure(let error):
                return delegate.authenticationFailed(cause: .delegateDecidedFailure(delegateError: error))
                
            case .success(let password):
                let passwordHash: PasswordHash
                
                do {
                    passwordHash = try PasswordHash(rawUnsanitizedPassword: password)
                }
                catch {
                    return delegate.authenticationFailed(cause: .cryptoError)
                }
                
                let newAccount = UserAccount(displayName: displayName, passwordHash: passwordHash)
                
                AuthDatabase.shared.register(
                    newUser: newAccount,
                    onRegistrationComplete: databaseDidFinishRegistering(account: newAccount, delegate: delegate)
                )
            }
        }
    }
    
    
    private static func databaseDidFinishRegistering(
        account: UserAccount,
        delegate: Delegate
    ) -> OnUserRegistrationComplete
    {
        return { result in
            switch result {
            case .failure(.displayNameAlreadyRegistered):
                switch delegate.userSuppliedAlreadyRegisteredDisplayName() {
                case .fail:
                    return delegate.authenticationFailed(cause: .displayNameAlreadyInUse)
                    
                case .retry:
                    return self.beginRegistrationProcess(with: delegate)
                }
                
            case .failure(.unexpected(let error)):
                return delegate.authenticationFailed(cause: .unexpectedErrorOccurred(error: error))
                
            case .success(_):
                return self.loginSuccess(account: account, delegate: delegate)
            }
        }
    }
    
    
    
    typealias OnUserRegistrationComplete = AuthDatabase.OnUserRegistrationComplete
}



private extension UnsafeUserInput {
    
    private static let safeCharacters = CharacterSet.alphanumerics.union(.whitespaces)
    private static var unsafeCharacters: CharacterSet { safeCharacters.inverted }
    
    /// Returns the sanitized form of this user input, assuming it's a username.
    /// If that cannot be done, `nil` is returned.
    func sanitizedDisplayName() -> String? {
        let rawString = self.withoutTypeSafety()
        guard
            !rawString.isEmpty,
            !rawString
                .lazy
                .flatMap({ $0.unicodeScalars })
                .contains(where: Self.unsafeCharacters.contains)
            else
        {
            return nil
        }
        return rawString
    }
}
