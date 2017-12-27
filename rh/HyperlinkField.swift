//
//  HyperlinkField.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/11/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa

class HyperlinkField: NSTextField {
    
    private var cursorTrackingArea: NSTrackingArea!

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if cursorTrackingArea != nil {
            removeTrackingArea(cursorTrackingArea)
        }
        
        cursorTrackingArea = NSTrackingArea(rect: bounds,
                                            options: [.cursorUpdate, .inVisibleRect, .activeInActiveApp],
                                            owner: self,
                                            userInfo: nil)
        addTrackingArea(cursorTrackingArea)
    }
    
    override func cursorUpdate(with event: NSEvent) {
        if event.trackingArea == cursorTrackingArea {
            NSCursor.pointingHand.push()
        } else {
            super.cursorUpdate(with: event)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if let action = self.action {
            NSApp.sendAction(action, to: target, from: self)
        }
    }

    
}
