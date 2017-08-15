//
//  GuardianTableCellView.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/11/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa

class GuardianTableCellView: NSTableCellView {
    
    @IBOutlet weak var stockSymbol: NSTextField!
    @IBOutlet weak var tickerPrice: RHButton! {
        didSet {
            self.tickerPrice.isBordered = false
            self.tickerPrice.wantsLayer = true
        }
    }
    var quoteURL : String?
    var instrumentURL : String?

    @objc func fetchQuotes() {

        APIManager.shared.getInstrument(withURL: self.quoteURL!) { (responseJSON, error) in
                
                guard responseJSON != nil, error == nil else {
                    // check for fundamental networking error
                    DispatchQueue.main.async {
                        self.tickerPrice.title = "Error"
                    }
                    return
                }
                
                if let tickerPrice = responseJSON?["last_trade_price"].string, let previousClose = responseJSON?["previous_close"].string {
                    DispatchQueue.main.async {
                        let floatingPrice = Float(tickerPrice)
                        let previousClose = Float(previousClose)
                        let difference = floatingPrice! - previousClose!
                        self.tickerPrice.title = String(format: "$%0.2f", floatingPrice!)
                        self.tickerPrice.alternateTitle = difference > 0 ? "+" + String(format: "%0.2f%%", (difference/previousClose!) * 100) : String(format: "%0.2f%%", (difference/previousClose!) * 100)
                        self.tickerPrice.layer?.backgroundColor = (difference) > 0 ? NSColor(red: 37.0/255.0, green: 199.0/255.0, blue: 135.0/255.0, alpha: 1.0).cgColor : NSColor(red: 229.0/255.0, green: 58.0/255.0, blue: 37.0/255.0, alpha: 1.0).cgColor
                        self.tickerPrice.setTextColor(color: NSColor.white)
                    }
                }
            }

    }
    
}
