//
//  AppDelegate.swift
//  rhHelper
//
//  Created by Banthia, Abhishek on 8/14/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let mainPath = NSString(string: Bundle.main.bundlePath)
        let strippedPath = NSString(string : NSString(string: mainPath.deletingLastPathComponent).deletingLastPathComponent)
        let moreSripping = NSString(string: strippedPath.deletingLastPathComponent).deletingLastPathComponent
        NSWorkspace.shared().launchApplication(moreSripping)
        NSApp.terminate(nil)
    }

}

