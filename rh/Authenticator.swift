//
//  Authenticator.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/8/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa

class Authenticator: NSObject {
    
    public var authenticationToken : String?
    public var requiresMFA : Bool = false
    public var mfaType : String?
    
    static var shared: Authenticator {
        struct Singleton {
            static let instance = Authenticator()
        }
        return Singleton.instance
    }
    
    override init() {
        super.init()
        self.setTokenForSessionIfPresent()
    }
    
    public func initialize(email: String, password: String, MFA : String?, completion :@escaping (_ success : Bool, _ error : Error?) -> Void) {
        login(email: email, password: password, MFA: MFA) { (success, error) in
            if success == true {
                self.saveTokenToDefaults(token: self.authenticationToken!)
                completion(true, nil)
            }else {
                completion(false, error)
            }
        }
    }
    
    private func login(email: String, password: String, MFA : String?, completion :@escaping (_ success : Bool, _ error : Error?) -> Void) {
    
        APIManager.shared.authenticate(username: email, password: password, MFA: MFA) { (response, error) in
            if error == nil, response != nil, let tokenString = response {
                let start = tokenString.index(tokenString.startIndex, offsetBy: 10)
                let end = tokenString.index(tokenString.endIndex, offsetBy: -2)
                let range = start..<end
                self.authenticationToken = tokenString.substring(with: range)
                completion(true, nil)
            }
            else {
                print("Error in login \(error!)")
                self.authenticationToken = nil
                completion(false, error)
            }
        }

    }
}

extension Authenticator {

    fileprivate func saveTokenToDefaults(token : String) {
        let cachedCredentials = UserDefaults.standard.string(forKey: "token")
        if cachedCredentials == nil {
           UserDefaults.standard.setValue(token, forKey: "token")
        }
    }
    
    fileprivate func setTokenForSessionIfPresent() {
        if let token = UserDefaults.standard.string(forKey: "token") {
            self.authenticationToken = token
        } else {
            print("No token found")
        }
    }
    
    public func clearTokenData() {
        UserDefaults.standard.set(nil, forKey: "token")
    }

    
}
