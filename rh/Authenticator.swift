//
//  Authenticator.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/8/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa
import Locksmith

class Authenticator: NSObject {
    
    public var authenticationToken : String?
    
    static var shared: Authenticator {
        struct Singleton {
            static let instance = Authenticator()
        }
        return Singleton.instance
    }
    
    public func initialize(email: String, password: String, completion :@escaping (_ success : Bool, _ error : Error?) -> Void) {
        login(email: email, password: password) { (success, error) in
            if success == true {
                self.saveCredentialsToKeychain(username: email, password: password)
                completion(true, nil)
            }else {
                completion(false, error)
            }
        }
    }
    
    private func login(email: String, password: String, completion :@escaping (_ success : Bool, _ error : Error?) -> Void) {
        
        APIManager.shared.authenticate(username: email, password: password) { (response, error) in
            
            if error == nil, response != nil, let tokenString = response {
                let start = tokenString.index(tokenString.startIndex, offsetBy: 10)
                let end = tokenString.index(tokenString.endIndex, offsetBy: -2)
                let range = start..<end
                self.authenticationToken = tokenString.substring(with: range)
                completion(true, nil)
            }
            else {
                self.authenticationToken = nil
                completion(false, error)
            }
        }

    }
    
    public func tryAuthentication(completion :@escaping (_ success : Bool) -> Void) {
        print("Trying to log in silently.")
        let cachedCredentials = Locksmith.loadDataForUserAccount(userAccount: "UserCredentials")
        guard let credentials = cachedCredentials else {
            completion(false)
            return
        }
        let username = Array(credentials.keys)[0]
        let password = credentials[username] as! String
        login(email: username, password: password) { (success, error) in
            completion(true)
            if success == false {
                print("Error encountered while trying silent authentication")
            } else {
                print("Able to login in silently with token : \(self.authenticationToken!)")
            }
        }
    }
    
}

extension Authenticator {

    fileprivate func saveCredentialsToKeychain(username: String, password: String) {
        print("Saving credentials to the Keychain.")
        let cachedCredentials = Locksmith.loadDataForUserAccount(userAccount: "UserCredentials")
        if cachedCredentials == nil {
            do {
                try Locksmith.saveData(data: [username: password], forUserAccount: "UserCredentials")
            }
            catch {
                print("Unable to save items to the Keychain")
            }
        }
    }
    
    public func clearKeychainData() {
        do {
            try Locksmith.deleteDataForUserAccount(userAccount: "UserCredentials")
        }
        catch {
            print("Locksmith is not able to delete them credentials")
        }
    }

    
}
