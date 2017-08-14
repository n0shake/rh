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
        Timer.scheduledTimer(timeInterval: 3,
                             target: self,
                             selector: #selector(self.fetchQuotes),
                             userInfo: nil,
                             repeats: true)
    }

}
