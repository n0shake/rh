//
//  AppDelegate.swift
//  rh
//
//  Created by Abhishek Banthia on 8/7/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa
import Crashlytics
import Fabric

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private let menubarController = MenubarController()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Fabric.with([Crashlytics.self])
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
    }
    
    func logout() {
        menubarController.logout()
    }
    
    func slideToPortfolio() {
         menubarController.popoverController.transitionToPortfolioViewController()
    }
    
}

