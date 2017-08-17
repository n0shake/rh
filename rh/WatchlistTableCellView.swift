//
//  WatchlistTableCellView.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/10/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa

class WatchlistTableCellView: GuardianTableCellView {

    func configure(_ security: Security) {
        self.stockSymbol.stringValue = security.symbol!
        self.tickerPrice.title = "..."
        self.quoteURL = security.quoteURL!
        if let quote = security.quote {
            self.tickerPrice.title = (quote.last_trade_price)!
        }
    }
    
    
}
