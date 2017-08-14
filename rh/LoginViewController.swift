//
//  LoginViewController.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/10/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa
import SwiftyJSON

class LoginViewController: NSViewController {
    
    @IBOutlet weak var emailField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator! {
        didSet {
            progressIndicator.isHidden = true
        }
    }
    
    init() {
        super.init(nibName: "LoginView", bundle: nil)!
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.emailField.stringValue = ""
        self.passwordField.stringValue = ""
    }
    
    @IBAction func loginAction(_ sender: Any) {
        
        self.errorLabel.stringValue = ""
        
        if validateFields() == false {
            self.setAutoerasingErrorText(errorText: "Username/Password Required")
            return
        }
        
        self.toggleProgressIndicator(state: true)
        self.startAuthentication(username: self.emailField.stringValue,
                                 password: self.passwordField.stringValue)
    }
    
    func startAuthentication(username:String?, password: String?) {
        
        if let userid = username, let passkey = password {
            Authenticator.shared.initialize(email: userid,
                                            password: passkey) { (success, error) in
                                                self.toggleProgressIndicator(state: false)
                                                if success == false {
                                                    self.setAutoerasingErrorText(errorText: (error?.localizedDescription)!)
                                                }
                                                else {
                                                    let delegate = NSApplication.shared().delegate as! AppDelegate
                                                    delegate.slideToPortfolio()
                                                }
        }
        
        }
        else {
            self.setAutoerasingErrorText(errorText: "Error with username/password")
        }
    }
    
    func setAutoerasingErrorText(errorText : String) {
        DispatchQueue.main.async {
            self.errorLabel.stringValue = errorText
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { (timer) in
                self.errorLabel.stringValue = ""
            })
        }
    }
    
    func validateFields() -> Bool {
        if self.emailField.stringValue.characters.count == 0 ||
            self.passwordField.stringValue.characters.count == 0 {
            return false
        }
        return true
    }
    
    func toggleProgressIndicator(state:Bool) {
        DispatchQueue.main.async {
            self.progressIndicator.isHidden = !state
            state ? self.progressIndicator.startAnimation(self) :
                self.progressIndicator.stopAnimation(self)
        }
    }
    
    
}
