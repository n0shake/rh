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
    @IBOutlet weak var tickerPrice: NSButton!
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
                
                if let tickerPrice = responseJSON?["last_trade_price"].string {
                    DispatchQueue.main.async {
                        let floatingPrice = Float(tickerPrice)
                        self.tickerPrice.title = String(format: "$%0.2f", floatingPrice!)
                    }
                }
            }

    }

}
