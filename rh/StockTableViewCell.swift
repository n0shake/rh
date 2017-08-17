//
//  StockTableViewCell.swift
//  rh
//
//  Created by Abhishek Banthia on 8/7/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa
import SystemConfiguration

class StockTableViewCell: GuardianTableCellView {
    
    @IBOutlet weak var sharesCount: NSTextField!
    
    func configure(security: SecurityOwned) {
        
        self.stockSymbol.stringValue = "Fetching..."
        self.tickerPrice.title = "..."
        
        if let totalQuantity = security.quantity {
            let totalQuantity = Int(Float(totalQuantity)!)
            self.sharesCount.stringValue = "\(totalQuantity) SHARES"
        }

        if let instrument = security.instrumentURL {
            self.instrumentURL = instrument
        }
        
        if let symbol = security.symbol {
            self.stockSymbol.stringValue = symbol
        }
        
    }
    
    
    
}

class NetworkAssistant {
    
    static let sharedInstance = NetworkAssistant()
    
    static func isConnected() -> Bool {
        let result: Bool = isHostConnected()
        
        return result
    }
    
    private static func isHostConnected() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
}

