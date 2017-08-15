//
//  StatusPopoverController.swift
//  rh
//
//  Created by Abhishek Banthia on 8/7/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa

class StatusPopoverController: NSObject {
    
    private var popover = NSPopover()
    private lazy var popoverController = PortfolioViewController()
    private lazy var loginController = LoginViewController()
    
    override init() {
        super.init()
        
        installApplicationTerminationListener()
        installLocalMonitorListener()
        
        self.setPopoverAppearance()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func installLocalMonitorListener() {
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseUp, .rightMouseDown]) { event in
            if event.type == .leftMouseUp || event.type == .rightMouseDown || event.keyCode == 53 {
                self.popover.performClose(nil)
            }
            return event
        }
    }
    
    private func installApplicationTerminationListener() {
        let delayTime = DispatchTime.now() + Double(Int64(2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            NotificationCenter.default.addObserver(self,
                                                   selector:#selector(StatusPopoverController.closePopover),
                                                   name: NSNotification.Name.NSApplicationDidResignActive,
                                                   object: nil)
        }
    }
    
    fileprivate func setPopoverAppearance() {
        popover.appearance = NSAppearance(appearanceNamed: NSAppearanceNameVibrantDark, bundle: nil)
        popover.behavior = .applicationDefined
        popover.animates = true
    }
    
    func showPopoverFromStatusItemButton(_ statusItemButton: NSButton) {
        
        if popover.contentViewController == nil {
            self.setPopoverContentViewController()
            self.addChildViewControllersToPopover()
        }
        
        if (close()) {
            return
        }
        self.showPopover(statusItemButton)
    }
    
    func close() -> Bool {
        if (popover.isShown) {
            popover.performClose(nil)
            return true
        }
        return false
    }
    
    func showPopover(_ statusItemButton: NSButton) {
        DispatchQueue.main.async {
            self.popover.show(relativeTo: NSZeroRect, of: statusItemButton, preferredEdge: .maxY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func transitionToPortfolioViewController() {
        DispatchQueue.main.async {
            let transition: NSViewControllerTransitionOptions = .slideLeft
            self.popover.contentViewController?.transition(from: self.loginController,
                                                            to: self.popoverController,
                                                            options: transition,
                                                            completionHandler: { finished in
            })
        }
    }
    
    func logout() {
        Authenticator.shared.clearTokenData()
        DispatchQueue.main.async {
            let transition: NSViewControllerTransitionOptions = .slideRight
            self.popover.contentViewController?.transition(from: self.popoverController,
                                                            to: self.loginController,
                                                            options: transition,
                                                            completionHandler: { finished in
                                                                Authenticator.shared.authenticationToken = nil
            })
        }
        
    }

    @objc fileprivate func closePopover() {
        popover.performClose(nil)
    }
    
    func setPopoverContentViewController() {
        let token = Authenticator.shared.authenticationToken
        popover.contentViewController = token != nil ? popoverController : loginController
    }
    
    func addChildViewControllersToPopover(){
        self.popover.contentViewController?.addChildViewController(loginController)
        self.popover.contentViewController?.addChildViewController(popoverController)
    }
    
}
