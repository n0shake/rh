//
//  MenubarController.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/12/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa

class MenubarController: NSObject {
    
    public var popoverController = StatusPopoverController()
    
    override init() {
        super.init()
        Authenticator.shared.tryAuthentication { (success) in
            DispatchQueue.main.async {
                self.menubarItem.isEnabled = true
                if success {
                    self.menubarTitleNeedsUpdate()
                }
            }
        }
    }
    
    lazy var menubarItem: NSStatusItem = {
        let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
        let font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: 0)
        statusItem.attributedTitle = NSAttributedString(string: "rh", attributes: [NSFontAttributeName : font])
        statusItem.target = self
        statusItem.action = #selector(statusItemAction(_:))
        statusItem.highlightMode = true
        statusItem.isEnabled = false
        return statusItem
    }()
    
    @objc fileprivate func statusItemAction(_ sender: NSStatusBarButton) {
        popoverController.showPopoverFromStatusItemButton(sender)
    }
    
    public func logout() {
        self.popoverController.logout()
        menubarItem.title = "rh"
    }
    
    private func menubarTitleNeedsUpdate() {
        
        DispatchQueue.main.async {
            self.menubarItem.title = "Stand by..."
            self.menubarItem.isEnabled = false
        }
        
        OperationQueueManager.shared.queue.addOperation {
            let menubarTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { (timer) in
                self.fetchPortfolioValue()
            })
            RunLoop.current.add(menubarTimer, forMode: .defaultRunLoopMode)
            RunLoop.current.run()
        }
    }
    
    private func fetchPortfolioValue() {
        
        APIManager.shared.getRequest(Endpoints.PortfolioURL.url) { (responseJSON, error) in
            
            DispatchQueue.main.async {
                self.menubarItem.isEnabled = true
            }
            
            guard let data = responseJSON, error == nil else {
                self.menubarItem.title = error?.localizedDescription
                return
            }
            
            let results = data["results"].array
            let portfolio = results?[0]
            var number = portfolio?["equity"].string
            if let extended = portfolio?["extended_hours_equity"].string{
                number = extended
            }
            
            let previousClose = Float((portfolio?["equity_previous_close"].string)!)
            let todayClose = Float((portfolio?["equity"].string!)!)
            let emoji = todayClose! - previousClose! > 0 ? "↑" : "↓"
            let floatingValue = Float(number!)
            
            DispatchQueue.main.async {
                let overallString = String(format: "%0.2f (%0.2f\(emoji)) ",
                    floatingValue!,
                    todayClose! - previousClose!)
                self.menubarItem.attributedTitle = NSAttributedString(string: overallString,
                                                                 attributes: [NSFontAttributeName :
                                                                    NSFont.monospacedDigitSystemFont(ofSize: 14, weight:0)])
            }
        }
    }


}
