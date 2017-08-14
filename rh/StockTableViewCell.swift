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
        
        self.createOperations()
    }
    
    public func createOperations() {
        
        let symbolNetworkOperation = BlockOperation {
            if let instrument = self.instrumentURL {
                self.fetchSymbol(instrument)
            }
        }
        
        let quoteNetworkOperation = BlockOperation {
            let quoteTimer = Timer(timeInterval: 3, target: self, selector: #selector(self.fetchQuotes), userInfo: nil, repeats: true)
            RunLoop.main.add(quoteTimer, forMode: .commonModes)
        }
    
        quoteNetworkOperation.addDependency(symbolNetworkOperation)
        OperationQueueManager.shared.queue.addOperation(quoteNetworkOperation)
        OperationQueueManager.shared.queue.addOperation(symbolNetworkOperation)
    }
    
    public func fetchSymbol(_ url : String) {
        
        APIManager.shared.getInstrument(withURL: url) { (responseJSON, error) in
            guard responseJSON != nil, error == nil else {
                DispatchQueue.main.async {
                    self.tickerPrice.title = "Error"
                }
                return
            }
            if let stockSymbol = responseJSON?["symbol"].string,
                let quoteURL = responseJSON?["quote"].string  {
                DispatchQueue.main.async {
                    self.quoteURL = quoteURL
                    self.stockSymbol.stringValue = stockSymbol

                }
            }
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

