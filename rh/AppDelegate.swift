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
        checkIfAnotherInstanceIsRunning()
        #if DEBUG
        #else
            checkIfAppIsInApplicationFolder()
        #endif
    }
    
    func checkIfAppIsInApplicationFolder() {
        if UserDefaults.standard.bool(forKey: "AllowOutsideApplicationsFolder") { return }
        let bundlePath = Bundle.main.bundlePath
        let applicationDirectories = NSSearchPathForDirectoriesInDomains(.applicationDirectory,
                                                                         .localDomainMask,
                                                                         true)
        for appDir in applicationDirectories {
            if bundlePath.hasPrefix(appDir) { return }
        }
        
        NSApplication.shared().activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            let wrongDirectoryAlert = NSAlert()
            wrongDirectoryAlert.messageText = "Move rh to the Applications folder"
            wrongDirectoryAlert.informativeText = "rh must be run from the Applications folder in order to work properly. \n\nPlease quit rh, move it to the Applications folder and relaunch."
            wrongDirectoryAlert.addButton(withTitle: "Cancel")
            wrongDirectoryAlert.runModal()
            NSApp.terminate(nil)
        }
    }
    
    func checkIfAnotherInstanceIsRunning() {
        
        guard let identifier = Bundle.main.bundleIdentifier else { return }
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
        if apps.count > 1 {
            let currentApplication = NSRunningApplication.current()
            for app in apps {
                if app != currentApplication {
                    app.activate(options: [.activateAllWindows,.activateIgnoringOtherApps])
                    break
                }
            }
            NSApp.terminate(nil)
        }
    }
    
    func toggle() {
        menubarController.popoverController.close()
    }
    
    func logout() {
        menubarController.logout()
    }
    
    func slideToPortfolio() {
         menubarController.popoverController.transitionToPortfolioViewController()
    }
    
}

