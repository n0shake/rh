//
//  LoginViewController.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/10/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa


class LoginViewController: NSViewController {
    
    @IBOutlet weak var emailField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var mfaStackView: NSStackView!
    @IBOutlet weak var codeEntryField: NSTextField!
    var is2FAInProgress : Bool = false
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator! {
        didSet {
            progressIndicator.isHidden = true
        }
    }
    
    init() {
        super.init(nibName: NSNib.Name(rawValue: "LoginView"), bundle: nil)
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
        
        if self.is2FAInProgress == false {
            self.errorLabel.stringValue = ""
            self.emailField.stringValue = ""
            self.mfaStackView.isHidden = true
            self.passwordField.stringValue = ""
        }
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
                                            password: passkey, MFA: nil) { (success, error) in
                                                self.toggleProgressIndicator(state: false)
                                                if success == false {
                                                    if (error?.localizedDescription.contains("2FA required"))! {
                                                        DispatchQueue.main.async {
                                                            self.is2FAInProgress = true
                                                            self.setAutoerasingErrorText(errorText: "Enter your 2FA code.")
                                                            self.mfaStackView.isHidden = false
                                                            self.codeEntryField.becomeFirstResponder()
                                                        }
                                                    } else {
                                                        self.setAutoerasingErrorText(errorText: (error?.localizedDescription)!)
                                                    }
                                                }
                                                else {
                                                    self.slide()
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
        if self.emailField.stringValue.count == 0 ||
            self.passwordField.stringValue.count == 0 {
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
    
    @IBAction func confirmMFA(_ sender: Any) {
        if self.codeEntryField.stringValue.characters.count <= 0 {
            self.setAutoerasingErrorText(errorText: "2FA field is empty.")
            return }
        if validateFields() == false { return }
        
        Authenticator.shared.initialize(email: self.emailField.stringValue, password: self.passwordField.stringValue, MFA: self.codeEntryField.stringValue) { (success, error) in
            self.is2FAInProgress = false
            if success == false {
                if let description = error?.localizedDescription, description.contains("valid code") {
                    self.is2FAInProgress = true
                    self.setAutoerasingErrorText(errorText: "Wrong code entered.")
                    return
                }
                self.setAutoerasingErrorText(errorText: "Unexpected error encountered")
            } else {
                self.slide()
            }
        }
    }
    
    private func slide() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "MenubarTitleNeedsUpdate"), object: nil)
        let delegate = NSApplication.shared.delegate as! AppDelegate
        delegate.slideToPortfolio()
    }

}
