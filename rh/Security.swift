//
//  Security.swift
//  rh
//
//  Created by Abhishek Banthia on 8/7/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa
import SwiftyJSON

public class SecurityOwned {
    
    var instrumentURL: String?
    var quantity: String?
    var averageBuyPrice: String?
    var symbol : String?
    var quote : Quote?
    
    public init(security : [String:AnyObject]) {
        self.instrumentURL = security["instrument"]! as? String
        self.quantity = security["quantity"] as? String
        self.averageBuyPrice = security["instrumentURL"] as? String
    }
    
    public init(json : JSON) {
        self.instrumentURL = json["instrument"].string
        self.quantity = json["quantity"].string
        self.averageBuyPrice = json["instrumentURL"].string
    }
}

public class Security {
    
    var instrumentURL: String?
    var quantity: String?
    var averageBuyPrice: String?
    var symbol : String?
    var quoteURL : String?
    var quote : Quote?
    
    public init(json : [String:JSON]) {
        self.instrumentURL = json["url"]?.string
        self.symbol = json["symbol"]?.string
        self.quoteURL = json["quote"]?.string
    }
    
}

public struct Quote {
    
    var last_trade_price: String?
    var symbol : String?
    var instrumentURL : String?
    var bidPrice : String?
    var tradingHalted : Bool?
    var previous_close_price : String?
    
    public init(json : JSON) {
        self.instrumentURL = json["instrument"].string
        self.symbol = json["symbol"].string
        self.last_trade_price = json["last_trade_price"].string
        self.previous_close_price = json["previous_close"].string
    }

}

