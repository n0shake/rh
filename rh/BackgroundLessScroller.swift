//
//  BackgroundLessScroller.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/10/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa

class BackgroundLessScroller: NSScroller {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.drawKnob()
    }
    
    override class func scrollerWidth(for controlSize: NSControlSize, scrollerStyle: NSScrollerStyle) -> CGFloat {
        return 8
    }
    
    
    
}
