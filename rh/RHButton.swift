//
//  RHButton.swift
//  rh
//
//  Created by Abhishek Banthia on 8/14/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa

class RHButton: NSButton {
    
    public enum ButtonTitleStyle {
        case quotePrice
        case totalPortfolioValue
        case percentageChange
    }
    
    public var selectedTitleStyle : ButtonTitleStyle = .quotePrice

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        self.title = self.alternateTitle
        self.setTextColor(color: NSColor.white)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
    }
    


    
}
