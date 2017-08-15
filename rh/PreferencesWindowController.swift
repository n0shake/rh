//
//  PreferencesWindowController.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/8/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa
import ServiceManagement

class PreferencesWindowController: NSWindowController {
    
    static let sharedWindow = PreferencesWindowController(windowNibName: "PreferencesWindow")
    private var twitterURL = URL(string: "https://twitter.com/abgbm")
    private var sourceURL = URL(string: "https://github.com/abhishekbanthia/rh")
    
    
    @IBOutlet weak var feedbackField: HyperlinkField! {
        didSet {
            feedbackField.alphaValue = 0.8
            feedbackField.textColor = .blue
            feedbackField.target = self
            feedbackField.action = #selector(openMyTwitter(_:))
        }
    }
    
    @IBOutlet weak var sourceField: HyperlinkField! {
        didSet {
            sourceField.alphaValue = 0.8
            sourceField.textColor = .blue
            sourceField.target = self
            sourceField.action = #selector(opensSource(_:))
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.titlebarAppearsTransparent = true
        self.window?.titleVisibility = .hidden
    }
    
    override func showWindow(_ sender: Any?) {
        window?.center()
        window?.alphaValue = 0.0
        super.showWindow(sender)
        window?.alphaValue = 1.0
    }
    
    @IBAction func openMyTwitter(_ sender: Any) {
        guard let feedbackURL = twitterURL else { return }
        NSWorkspace.shared().open(feedbackURL)
    }
    
    @IBAction func opensSource(_ sender: Any) {
        guard let githubURL = sourceURL else { return }
        NSWorkspace.shared().open(githubURL)
    }

    @IBAction func toggleAutoupdater(_ sender: Any) {
        
    }
    
    @IBAction func startAtLogin(_ sender: NSButton) {
        if !SMLoginItemSetEnabled("com.abhishek.rhHelper" as CFString, Bool(sender.state as NSNumber)) {
            print("Unable to set login item")
        }
    }
    
    @IBAction func showPortfolioAmountInMenubar(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "MenubarPreferenceChangedNotification"), object: nil)
    }
   
    
    
}
