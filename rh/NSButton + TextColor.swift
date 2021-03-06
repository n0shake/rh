//
//  NSColor + TextColor.swift
//  rh
//
//  Created by Abhishek Banthia on 8/14/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa

extension NSButton {
    func setTextColor(color : NSColor) {
        let colorTitle = NSMutableAttributedString(attributedString:self.attributedTitle)
        colorTitle.addAttributes([NSAttributedStringKey.foregroundColor:color], range: NSMakeRange(0, self.attributedTitle.length))
        self.attributedTitle = colorTitle
    }
    
    func setTextColorForAlternateTitle(color : NSColor) {
        let colorTitle = NSMutableAttributedString(attributedString:self.attributedAlternateTitle)
        colorTitle.addAttributes([NSAttributedStringKey.foregroundColor:color], range: NSMakeRange(0, self.attributedAlternateTitle.length))
        self.attributedAlternateTitle = colorTitle
    }
}
