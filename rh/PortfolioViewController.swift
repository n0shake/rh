//
//  ViewController.swift
//  rh
//
//  Created by Abhishek Banthia on 8/7/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa
import SwiftyJSON

private enum PortfolioKeys : String {
    case DragKey = "move"
    case WatchListNibName = "WatchListPopover"
    case ErrorDefault = "Some Error"
    case JsonResultsKey = "results"
    case GroupCellIdentifier = "GroupCell"
    case WatchListGroupCellTitle = "Watchlist"
    case WatchListGroupCellIdentifier = "watchlistCell"
    case PortfolioListGroupCellTitle = "Portfolio"
    case PortfolioListGroupCellIdentifier = "stockCell"
}

class PortfolioViewController: NSViewController {
    
    @IBOutlet weak var loadingLabel: NSTextField!
    @IBOutlet weak var loadingView: NSView! {
        didSet {
            self.loadingView.wantsLayer = true
            self.loadingView.layer?.backgroundColor = NSColor.white.cgColor
            self.loadingView.isHidden = true
        }
    }
    static var portfolioCounter = 0
    static var stockListCounter = 0

    var symbols = Set<String>()
    
    @IBOutlet weak var shareApp: NSButton! {
        didSet {
            self.shareApp.sendAction(on: .leftMouseDown)
        }
    }
 
    @IBOutlet weak var mainTableview: NSTableView! {
        didSet {
            self.mainTableview.register(forDraggedTypes: [PortfolioKeys.DragKey.rawValue])
        }
    }
    @IBOutlet weak var supplementaryView: NSView! {
        didSet {
            self.supplementaryView.wantsLayer = true
            self.supplementaryView.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
    
    fileprivate var securitiesOwned = [SecurityOwned]()
    
    fileprivate var portfolios = [Security]()
    
    init() {
        super.init(nibName: PortfolioKeys.WatchListNibName.rawValue, bundle: nil)!
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchSecuritiesOwned()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    fileprivate func fetchSecuritiesOwned() {
        
        if NetworkAssistant.isConnected() == false {
            DispatchQueue.main.async {
               self.loadingView.isHidden = false
               self.loadingLabel.stringValue = "You appear to be offline."
                return
            }
        }
        
        APIManager.shared.getRequest(Endpoints.SecuritiesURL.url) { (responseJSON, error) in
            
            DispatchQueue.main.async {
                self.perform(#selector(self.hideLoadingView), with: nil, afterDelay: 5)
            }
    
            guard let data = responseJSON, error == nil else {
                // check for fundamental networking error
                print(error?.localizedDescription ?? PortfolioKeys.ErrorDefault.rawValue)
                return
            }
            
            let securities = data[PortfolioKeys.JsonResultsKey.rawValue].array
            
            DispatchQueue.main.async {
                for security in securities! {
                    let stock = SecurityOwned(json: security)
                    self.securitiesOwned.append(stock)
                }
                self.mainTableview.reloadData()
                OperationQueueManager.shared.queue.addOperation {
                    self.fetchInstrumentsForSecurityOwned()
                    self.fetchWatchlist()
                }
            }
        }
    }
    
    func fetchInstrumentsForSecurityOwned() {
        
        for (index,security) in self.securitiesOwned.enumerated() {
            
            self.getInstrument(withURL: security.instrumentURL, completion: { (securityModel, success) in
                if success {
                    
                    guard let model = securityModel else {
                        print("Security model is nil")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        security.symbol = model.symbol
                        self.symbols.insert(model.symbol!)
                        if index == self.securitiesOwned.count {
                            self.mainTableview.reloadData()
                        }
                    }
                } else {
                    Swift.print("Failure while fetching URL")
                }

            })
            
        }
    }
    
    func fetchWatchlist() {
        
        OperationQueueManager.shared.queue.addOperation {
            APIManager.shared.getRequest("https://api.robinhood.com/watchlists/Default/") { (responseJSON, error) in
                guard error == nil else { return }
                let result = responseJSON?["results"].array
                if let watchlist = result {
                    for instrument in watchlist {
                        let instrumentDictionary = instrument.dictionary
                        
                        self.getInstrument(withURL: instrumentDictionary?["instrument"]?.string, completion: { (security, success) in
                            if success {
                                guard let model = security else {
                                    print("Security model is nil")
                                    return
                                }
                                self.portfolios.append(model)
                                self.symbols.insert(model.symbol!)
                                if watchlist.count == self.portfolios.count {
                                    self.scheduleAutoupdatingQuoteFetcher()
                                    DispatchQueue.main.async {
                                       self.mainTableview.reloadData()
                                    }
                                }
                            }
                        })
                    }
                }
                
            }
        }
    }
    
    @objc private func hideLoadingView() {
        self.loadingLabel.stringValue = ""
        self.loadingView.isHidden = true
    }
    
    func getInstrument(withURL: String?, completion handler: @escaping  (_ model : Security?, _ error : Bool) -> Void) {
        
        APIManager.shared.getInstrument(withURL: withURL!) { (json, error) in
            
            if error == nil {
                DispatchQueue.main.async {
                    let security = Security(json: (json?.dictionary)!)
                    handler(security, true)
                }
            }
            else {
                print(error?.localizedDescription ?? PortfolioKeys.ErrorDefault.rawValue)
            }
        }
    }
    
    func scheduleAutoupdatingQuoteFetcher() {
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
                self.getAllQuotesTogether()
            }
        }
    }
    
    func getAllQuotesTogether() {
        
        let URL = self.symbols.joined(separator: ",")
        let baseURL = Endpoints.QuotesURL.url + URL
        PortfolioViewController.portfolioCounter = 0
        PortfolioViewController.stockListCounter = 0
        
        APIManager.shared.getQuotes(baseURL) { (responseJSON, error) in
            
            guard error == nil || responseJSON != nil else{
                print("Response JSON is nil or error is nil")
                print(error?.localizedDescription ?? "Error encountered")
                return
            }
            
            if let response = responseJSON {
                DispatchQueue.main.async {
                    for i in 0..<self.portfolios.count {
                        let current = self.portfolios[i]
                        for quoteModel in response {
                            if current.instrumentURL == quoteModel.instrumentURL {
                                current.quote = quoteModel
                                break
                            }
                        }
                    }
                    for i in 0..<self.securitiesOwned.count {
                        let current = self.securitiesOwned[i]
                        for quoteModel in response {
                            if current.instrumentURL == quoteModel.instrumentURL {
                                current.quote = quoteModel
                                break
                            }
                        }
                    }
                    
                    for i in 0..<self.mainTableview.numberOfRows {
                        
                        let currentrow = self.mainTableview.view(atColumn: 0, row: i, makeIfNecessary: false)
   
                        if let row = currentrow as? WatchlistTableCellView, PortfolioViewController.portfolioCounter < self.portfolios.count, let quote = self.portfolios[PortfolioViewController.portfolioCounter].quote {
                            row.updateTickerPrice(quote)
                            PortfolioViewController.portfolioCounter += 1
                        }
                        if let stockCell = currentrow as? StockTableViewCell, PortfolioViewController.stockListCounter < self.securitiesOwned.count,
                            let quote = self.securitiesOwned[PortfolioViewController.stockListCounter].quote  {
                            stockCell.updateTickerPrice(quote)
                            PortfolioViewController.stockListCounter += 1
                            continue
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func showPreferences(_ sender: Any) {
        closePopover()
        let preferencesWindow = PreferencesWindowController.sharedWindow
        preferencesWindow.showWindow(self)
        preferencesWindow.window?.orderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        self.securitiesOwned = [SecurityOwned]()
        self.portfolios = [Security]()
        self.loadingView.isHidden = false
        self.loadingLabel.stringValue = "Refreshing..."
        self.fetchSecuritiesOwned()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "MenubarTitleNeedsUpdate"), object: nil)
    }
   
    @IBAction func logoutAction(_ sender: Any) {
        let delegate = NSApplication.shared().delegate as! AppDelegate
        delegate.logout()
    }
    
    @IBAction func shareAction(_ sender: NSButton) {
        let shareText = "Put Robinhood in your menubar. Download at https://github.com/abhishekbanthia/rh/tree/master/Releases/rh.app.zip"
        let servicePicker = NSSharingServicePicker(items: [shareText])
        servicePicker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minX)
    }
        
    func closePopover() {
        let delegate = NSApplication.shared().delegate as! AppDelegate
        delegate.toggle()
    }
    
}

extension PortfolioViewController : NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.securitiesOwned.count+self.portfolios.count+2
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if row == 0 {
            let field = tableView.make(withIdentifier: PortfolioKeys.GroupCellIdentifier.rawValue, owner: tableView) as? NSTextField
            field?.stringValue = PortfolioKeys.PortfolioListGroupCellTitle.rawValue
            return field
        }
        
        if row == self.securitiesOwned.count + 1 {
            let field = tableView.make(withIdentifier: PortfolioKeys.GroupCellIdentifier.rawValue, owner: tableView) as? NSTextField
            field?.stringValue = PortfolioKeys.WatchListGroupCellTitle.rawValue
            return field
        }
        
        if row < self.securitiesOwned.count + 1 {
            let cell = tableView.make(withIdentifier: PortfolioKeys.PortfolioListGroupCellIdentifier.rawValue, owner: tableView) as? StockTableViewCell
            cell?.configure(security: self.securitiesOwned[row-1])
            return cell
        }
        
        if portfolios.count > 0 && PortfolioViewController.portfolioCounter < portfolios.count {
            let cell = tableView.make(withIdentifier: PortfolioKeys.WatchListGroupCellIdentifier.rawValue, owner: tableView) as? WatchlistTableCellView
            cell?.configure(self.portfolios[PortfolioViewController.portfolioCounter])
            PortfolioViewController.portfolioCounter += 1
            return cell
        }
        
        return nil
        
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        if row == 0 || row == self.securitiesOwned.count + 1{
            return true
        }
        return false
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if row == 0 || row == self.securitiesOwned.count + 1 {
            return 23
        }
        
        return tableView.rowHeight
    }
    
    // Mark: Reordering
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.declareTypes([PortfolioKeys.DragKey.rawValue], owner: self)
        pboard.setData(data, forType: PortfolioKeys.DragKey.rawValue)
        return true
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        
        if row == 0 || row >= self.securitiesOwned.count + 1{
            return false
        }
        
        var destinationRow = row
        
        if destinationRow == 0 {
            return false
        }
        
        if destinationRow >= self.securitiesOwned.count+1 {
            destinationRow = destinationRow - 1
        }
        
        let pasteboard : NSPasteboard = info.draggingPasteboard()
        let data: Data = pasteboard.data(forType: PortfolioKeys.DragKey.rawValue)!
        let rowIndexes = NSKeyedUnarchiver.unarchiveObject(with: data) as! IndexSet
        print(rowIndexes.first!, destinationRow)
        let currentSecurity : SecurityOwned = self.securitiesOwned[rowIndexes.first!-1]
        self.securitiesOwned.remove(at: rowIndexes.first!-1)
        self.securitiesOwned.insert(currentSecurity, at: destinationRow-1)
        self.mainTableview.reloadData()
        
        return true
    }
    
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        return .move
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
    }
    
}

